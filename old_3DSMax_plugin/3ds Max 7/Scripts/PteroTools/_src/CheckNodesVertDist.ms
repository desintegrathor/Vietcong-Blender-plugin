-- global variables
global oSel = #()

-- rollouts
rollout dlgSetDistTreshold "Unwanted move finder" width:192 height:112
(
	local _iniSect	= "UnwantedMoveFinder"
	local isOK = false
	
	GroupBox grp1 "" pos:[8,8] width:176 height:64
	spinner spnTresh "Distance treshold [m]:" pos:[48,24] width:130 height:16 range:[0.001,9999,0.001] scale:0.001
--	checkbox chkSelOnly "Process selected nodes only" pos:[16,48] width:160 height:16
	button btnOK "OK" pos:[8,80] width:64 height:24
	button btnCancel "Cancel" pos:[120,80] width:64 height:24
	
	on btnOK pressed do
	(
		isOK = true
		fnSaveINI "DistTresh"		(spnTresh.value as string) (fnReturnFilename #ini) _iniSect
--		fnSaveINI "SelectedOnly"	(chkSelOnly.checked as string) (fnReturnFilename #ini) _iniSect
		destroyDialog dlgSetDistTreshold
	)
	on btnCancel pressed do
	(
		destroyDialog dlgSetDistTreshold
	)
	on dlgSetDistTreshold open do
	(
		tmp = fnLoadINIexec "DistTresh" (fnReturnFilename #ini) _iniSect
		if tmp != OK do spnTresh.value = tmp
--		tmp = fnLoadINIexec "SelectedOnly" (fnReturnFilename #ini) _iniSect
--		if tmp != OK do chkSelOnly.checked = tmp
	)
)

rollout dlgUnwantedMoveFinder "Unwanted move finder" width:420 height:232
(
	struct s_unwantedMove ( node, verts = #{})
	local _iniSect	= "UnwantedMoveFinder"
	local oArray	= #()
	local lTxt		= "Progress: "
	local checked	= 0
	local ignored	= 0

	button			btnAbout "?"						pos:[396,8]		width:16	height:16
	ActiveXControl	axWaifs	"MSComctlLib.ListViewCtrl"	pos:[8,64]		width:404	height:126 --TreeCtrl
	label			lbl2	""							pos:[8,8]		width:380	height:16
	label			lbl1	""							pos:[8,24]		width:380	height:16
	progressBar		pb1		""							pos:[8,40]		width:404	height:8
	progressBar		pb2		""							pos:[8,48]		width:404	height:8
	button			btn2	"Close"						pos:[8,200]		width:156	height:24	enabled:false
	button			btn3	"Cancel"					pos:[324,200]	width:88	height:24	enabled:false
	-- Image list controls for holding icons
	activeXControl	ilTvSmallIcons		"{2C247F23-8591-11D1-B16A-00C0F0283628}" height:0 width:0

	-- fnInitAX()
	fn fnInitAX name =
	(
		local LVM_FIRST = 0x1000
		local LVM_SETCOLUMNWIDTH = (LVM_FIRST + 30)
		local windowColor = colorMan.getColor #window
		local iconPath = fnReturnPath #ico

		-- define List View Control
		enableAccelerators = false
		name.allowColumnReorder = false
		name.appearance = #ccFlat
		name.borderStyle = #ccFixedSingle
		name.gridLines = false
		name.view = #lvwReport
		name.fullRowSelect = true
		name.multiSelect = false
		name.labelEdit = #lvwManual
		name.hideSelection = false
		name.sortOrder = #lvwAscending		
		name.hideColumnHeaders = true
		name.FlatScrollBar = false
		name.BackColor = (color (255*windowColor[1]) (255*windowColor[2]) (255*windowColor[3]))

		-- define temp bitmap control (small icons)
		ilTvSmallIcons.imageheight = 14
		ilTvSmallIcons.imagewidth = 14
		ilTvSmallIcons.maskColor = color 212 212 212
		ilTvSmallIcons.useMaskColor = true
		-- add small icons
		ilTvSmallIcons.listImages.add 1 #new (loadPicture (iconPath + "\\spiker_wrong.bmp"))
		ilTvSmallIcons.listImages.add 2 #new (loadPicture (iconPath + "\\spiker_good.bmp"))
		name.smallIcons = ilTvSmallIcons

		-- create columns
		hName = name.columnHeaders.add()
		hName.text = "Node"
		windows.sendMessage axWaifs.hwnd LVM_SETCOLUMNWIDTH  0 150

		hName = name.columnHeaders.add()
		hName.text = "Status"
		windows.sendMessage axWaifs.hwnd LVM_SETCOLUMNWIDTH  1 100

		hName = name.columnHeaders.add()
		hName.text = "Verts"
		windows.sendMessage axWaifs.hwnd LVM_SETCOLUMNWIDTH  2 (axWaifs.size.x - 150 - 100 - 20)
	)

	-- fnAddItem()
	fn fnAddItem control line tooltip:"" icon:0 forecolor:(color 0 0 0) =
	(
		local iCount = control.listItems.count
		local item, subitem

		item = control.listItems.add()
		iCount = control.listItems.count
		
		if (classof line) != Array do line = #(line)
		
		item.text = line[1] as string
		item.tag = line[1] as string
		item.toolTipText = tooltip
		item.forecolor = forecolor
		item.bold = false
		item.ghosted = false
		if icon > 0 do item.smallicon = icon

		for n = 2 to line.count do
		(
			subitem = item.listSubItems.add()
			subitem.text = line[n] as string
			subitem.toolTipText = tooltip
			subitem.forecolor = forecolor
		)	

		control.selectedItem = control.listItems[iCount]
	)

	fn fnFillVerts node verts =
	(
		local notFound = true
		
		if verts.count == 0 do return OK
		
		if oArray.count != 0 then
		(
			for n = 1 to oArray.count do
			(
				if oArray[n].node == node then
				(
					local va = oArray[n].verts as array
					for t = 1 to verts.count do
					(
						if findItem va verts[t] == 0 do append va verts[t]
					)
					oArray[n].verts = va as bitarray
					notFound = false
				)
			)
		)

		if oArray.count == 0 or notFound then
		(
			local item = s_unwantedMove node (verts as bitarray)
--			local item = s_unwantedMove node verts state
			append oArray item
		)
	)
	
	fn fnGetVerts node =
	(
		local ret = #()
		local cn = classOf node
		local vert
		
		if (cn == Editable_Patch) then ()
		else if (cn == NURBSSurf) then ()
		else
		(
			local msh = copy node.mesh
			for v = 1 to msh.numVerts do
			(
				local vrt
				in coordsys world vrt = meshop.getVert msh v node:node
				append ret vrt
--				format "node: %\tvert: %\t%\n" node.name v vrt
			)
			delete msh
		)

--		format "%\t%\t%\n" node.name cn ret.count
		return ret
	)
	
	fn fnProcessCheck v1 v2 tresh =
	(
		local ret1 = #()
		local ret2 = #()
		local isWrong
		local tresh2 = tresh * 0.1
		
		if v1.count == 0 or v2.count == 0 do return #(ret1, ret2)
		
		for u = 1 to v1.count do
		(
			isWrong = false
			for v = 1 to v2.count do
			(
				local vd = ((((distance v1[u] v2[v]) / tresh2) as integer) * tresh2) as float
--				if vd <= tresh do
--					format "vd: %\nv1[%]: %\tv2[%]: %\nv1c: %\tv2c: %\n---------------\n" vd u v1[u] v v2[v] v1.count v2.count
				if vd > 0 and vd <= tresh do
				(
--					format "vd: %\nv1[%]: %\tv2[%]: %\nv1c: %\tv2c: %\n---------------\n" vd u v1[u] v v2[v] v1.count v2.count
					append ret2 v
					isWrong = true
				)
			)
			if isWrong do append ret1 u
--			gc()
		)
		
		return #(ret1, ret2)
	)
	
	fn fnCheckVertDist sel =
	(
--		local allNodes = #()
		local vArray = #()
		local tresh = 0.01
		
		tmp = fnLoadINIexec "DistTresh" (fnReturnFilename #ini) _iniSect
		if tmp != OK do tresh = tmp

--		for n in sel do append allNodes n
		for n in sel do append vArray (fnGetVerts n)
		
		while sel.count > 0 do
		(
--			local v1 = fnGetVerts sel[1]

			for n = 2 to sel.count do
			(
--				if sel[n] == sel[1] do continue
				lbl2.text = lTxt + "Checking verts - " + (checked - sel.count) as string + " of " + checked as string
				lbl1.text = sel[1].name + " - " + vArray[1].count as string + " verts"

--				local v2 = fnGetVerts sel[n]
				local ret = fnProcessCheck vArray[1] vArray[n] tresh
				
				fnFillVerts sel[1] ret[1]
				fnFillVerts sel[n] ret[2]
				
				pb2.value = (100 * n / sel.count) as float
				pb1.value = (100 * (checked - sel.count) / checked) as float
			)
			
			deleteItem sel 1
			deleteItem vArray 1
		)
		pb2.value = 100
		pb1.value = 100
	)
	
	fn fnSelectVerts =
	(
		for n = 1 to axWaifs.listItems.count do
		(
			case axWaifs.listItems[n].ListSubItems[1].text of
			(
				"can't select": continue
				"convert and select": convertToMesh oArray[n].node
			)
			setVertSelection oArray[n].node.mesh oArray[n].verts
		)
	)
	
	-- fnConvert()
	fn fnConvert item select:undefined = 
	(
		local windowColor = colorMan.getColor #window
		local s = ""
		local t = ""
		local c = (color 0 0 0)
		local i = 2

		if item.ListSubItems[1].text != "" do
		(
			if	select == true and item.ListSubItems[1].text != "convert and select" or
				select == undefined and item.ListSubItems[1].text == "can't select" then
			(
				s = "convert and select"
				t = "Double click to remove this node from convertion"
				ignored -= 1
			)
			else if select == false and item.ListSubItems[1].text != "can't select" or
					select == undefined and item.ListSubItems[1].text == "convert and select" then
			(
				s = "can't select"
				t = "Double click to convert this node to Editable mesh"
				c = (color (128*windowColor[1]) (128*windowColor[2]) (128*windowColor[3]))
				i = 1
				ignored += 1
			)
			if s != "" do
			(
				item.smallicon = i
				item.forecolor = c
				item.toolTipText = t
				item.ListSubItems[1].text = s
				item.ListSubItems[1].forecolor = c
				item.ListSubItems[2].forecolor = c

				lbl1.text = "Checked: " + checked as string + "\t\tFound: " + axWaifs.ListItems.count as string + "\t\tIgnored: " + ignored as string
				if ( axWaifs.listItems.count != 0 ) and ( ignored != axWaifs.listItems.count ) then
					btn2.text = "Select and Close"
				else
					btn2.text = "Close"
			)
		)
	)
	
	-- fnUtilizeItem()
	fn fnUtilizeItem item = case item of
	(
		#btnAbout:
		(
			PteroToolsTemp = #("Unwanted move finder", 1.0)
			fnAboutDialog()
		)
		#btnOK:
		(
			fnSelectVerts()
			destroyDialog dlgUnwantedMoveFinder
		)
		#btnCancel:
		(
			destroyDialog dlgUnwantedMoveFinder
		)
		#keySpace:
		(
			fnConvert axWaifs.selectedItem
		)
		#keyCtrlA:
		(
			for n = 1 to axWaifs.ListItems.count do
				fnConvert axWaifs.ListItems[n] select:true
		)
		#keyCtrlN:
		(
			for n = 1 to axWaifs.ListItems.count do
				fnConvert axWaifs.ListItems[n] select:false
		)
	)
	
	-- fnUtilizeKey()
	fn fnUtilizeKey keyCode Shift = case keyCode of
	(
		-- enter
		13: fnUtilizeItem #btnOK
		-- esc
		27: fnUtilizeItem #btnCancel
		-- space
		32: fnUtilizeItem #keySpace
		-- ctrl a
		65: if shift == 2 do fnUtilizeItem #keyCtrlA
		-- ctrl n
		78: if shift == 2 do fnUtilizeItem #keyCtrlN
	)

	-- Buttons
	on btnAbout	pressed do fnUtilizeItem #btnAbout
	on btn2 pressed do fnUtilizeItem #btnOK
	on btn3 pressed do fnUtilizeItem #btnCancel
	-- Waifs
	on axWaifs DblClick					do fnConvert axWaifs.selectedItem
	on axWaifs keyup keyCode Shift		do fnUtilizeKey keyCode Shift
	on axWaifs MouseUp button shift x y	do if axWaifs.selectedItem != undefined do
	(
		if button == 2 and axWaifs.selectedItem.ListSubItems[1].text != "" do
		(
			rcmenu rcmSpiker
			(
				menuItem miConvert		""	checked:false
				menuItem miConvertAll	""	checked:false
				menuItem miUnConvertAll	""	checked:false
				
				on miConvert picked do fnUtilizeItem #keySpace
				on miConvertAll picked do fnUtilizeItem #keyCtrlA
				on miUnConvertAll picked do fnUtilizeItem #keyCtrlN
				on rcmSpiker open do
				(
					miConvert.text = if axWaifs.selectedItem.ListSubItems[1].text == "can't select" then "Select and convert\tSpace" else "Unselect\tSpace"
					miConvertAll.text = "Select and convert All\tCtrl+A"
					miUnConvertAll.text = "Unselect All\tCtrl+N"
				)
			)
			
			popUpMenu rcmSpiker pos:[axWaifs.pos.x + x,axWaifs.pos.y + y] rollout:dlgProgress
		)
	)

	on dlgUnwantedMoveFinder open do with redraw off
	(
		local windowColor = colorMan.getColor #window
		local sel = #()
		
		for n in oSel do append sel n
		checked = sel.count
		
		-- init activeX
		fnInitAX axWaifs

		-- check vert dist		
		fnCheckVertDist sel

		-- fill list box
		for n in oArray do
		(
			local s = ""
			local t = (n.verts as array) as string
			local c = (color 0 0 0)
			local i = 2
			if (classOf n.node) == Editable_mesh and n.node.modifiers.count == 0 then
			()
			else
			(
				s = "can't select"									-- isn't EditableMesh
				t = "Double click to convert this node to Editable mesh"
				c = (color (128*windowColor[1]) (128*windowColor[2]) (128*windowColor[3]))
				i = 1
				ignored += 1
			)
			fnAddItem axWaifs #(n.node.name, s, "propably moved: " + ((n.verts as array).count as string + " vert(s)")) tooltip:t icon:i forecolor:c
		)

		-- display status
		lbl1.text = "Checked: " + checked as string + "\t\tFound: " + oArray.count as string + "\t\tIgnored: " + ignored as string
		lbl2.text = lTxt + "Done"
		
		-- enable buttons
		btn2.enabled = true
		if ( oArray.count != 0 ) and ( ignored != axWaifs.listItems.count ) then
			btn2.text = "Select and Close"
		else
			btn2.text = "Close"
		btn3.enabled = true
	)
)

-- functions
fn fnUnwantedMoveFinder =
(
	local fTresh--, bSelOnly
	
	-- get init variales
	createDialog dlgSetDistTreshold modal:true
	if dlgSetDistTreshold.isOK == false do return OK
	fTresh = dlgSetDistTreshold.spnTresh.value
--	bSelOnly = dlgSetDistTreshold.chkSelOnly.state

	-- get selection
--	local nodeSet = if $ == undefined or not bSelOnly then geometry else $
	local nodeSet = if $ == undefined then geometry else $
	oSel = #()
	for o in nodeSet do
		if (superClassOf o) == GeometryClass and (classOf o) != Dummy do
			append oSel o
	if oSel.count > 1 then
	(
		-- check for unwanted move
		createDialog dlgUnwantedMoveFinder modal:true
	)
	else
	(
		messageBox "Select two or more geometry nodes." caption:"Unwanted move finder"
	)
	
	-- cleaning
	oSel = undefined
	gc()
	
	return OK
)

--clearListener()
--fnUnwantedMoveFinder()
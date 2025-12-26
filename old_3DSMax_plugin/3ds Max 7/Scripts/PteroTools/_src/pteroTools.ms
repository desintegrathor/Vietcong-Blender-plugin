---------------------------------------------------------------
--
-- PteroTools
--
-- by Pan Collette
--
-- Create: 09.09.2003
-- Modified: 02.03.2004
--
---------------------------------------------------------------

---------------------------------------------------------------
-- fnAboutDialog()
---------------------------------------------------------------
fn fnAboutDialog = (
	rollout AboutRollOut "About PteroCollette Tools" width:300(
		-- init GUI
		bitmap iconMap bitmap:(bitmap 144 80) align:#left across:2
		label lbl06 "" align:#right
		label lbl00 "" align:#right offset:[0,-57]
		label lbl07 "Add-in PteroEngine II Tool" align:#right
		label lbl03 "by Pan Collette" align:#right
		button btnPtero "www.pterodon.com" width:280 align:#center
 
		-- Event Handler
		on btnPtero pressed do (
			assetBrowser.open() 
			assetBrowser.gotoURL "http://www.pterodon.com/"
		)
		on AboutRollOut open do (
			local ver = "Version " + ( PteroToolsTemp[2] as float ) as string
			local iconPath = fnReturnFilename #splash
			
			flag = (getfiles iconPath).count
			case flag of (
				1:		iconMap.fileName = iconPath
				default:	()
				)
			lbl00.text = ver
			lbl06.text = PteroToolsTemp[1]
		)
	)

	-- Create Dialog
	createDialog AboutRollOut modal:true --style:#(#style_titlebar, #style_border)
)
--PteroToolsTemp = #("ahoj", 1.3)
--fnAboutDialog()

---------------------------------------------------------------
-- fnColMatList()
---------------------------------------------------------------
global _isColMatListOpen = false
fn fnColMatList = (
	local _iniSect	= "PteroColMatList"
	local matArray	= fnReturnColMats()
	
	if matArray[2] == undefined do matArray = fnLoadMats()

	rollout dlgColMatList "PteroCol Materials List" width:264 height:480
	(
		local _iniSect	= "PteroColMatList"

		editText	edt1	""		pos:[5,8]	width:250	height:18
		listbox		lbx1	""		pos:[8,32]	width:248	height:31
		button		btn1	"Close"	pos:[8,448]	width:248	height:24	enabled:true

		--	fnFindItem()
		fn fnFindItem txt = (
			local ret = lbx1.selection

			if txt == undefined then ( format "ERROR: fnFindItem() - txt:%\n" txt; return ret )

			for i = 1 to lbx1.items.count do
				if ( matchPattern lbx1.items[i] pattern:( txt + "*" ) ) do return i
			return ret
		)

		-- Find
		on edt1	changed txt		do ( lbx1.selection = (fnFindItem txt) )
		on edt1	entered txt		do ( edt1.text = "" )
		-- Close
		on btn1 pressed do 
			destroyDialog dlgColMatList
		-- on Open
		on dlgColMatList open do (
			_isColMatListOpen = true
			updateToolbarButtons()
		)
		on dlgColMatList close do (
			fnSaveINI "DialogPosition" ( ( getDialogpos dlgColMatList ) as string ) (fnReturnFilename #ini) _iniSect
			_isColMatListOpen = false
			updateToolbarButtons()
		)
	)

	-- Create Dialog
	if not _isColMatListOpen then (
		if ( p = fnLoadINIexec "DialogPosition" (fnReturnFilename #ini) _iniSect ) == OK do p = [50,50]

		createDialog dlgColMatList modal:false pos:p --style:#(#style_titlebar, #style_border) pos:p
		dlgColMatList.controls[2].items = matArray
	) else 
		destroyDialog dlgColMatList
)

---------------------------------------------------------------
-- fnFindSpikeFaces()
---------------------------------------------------------------
global findSelectedSpiked
fn fnFindSpikeFaces = (
	rollout dlgProgress "Looking for crashed faces" width:400 height:232
	(
		local oArray	= #()
		local lTxt		= "Progress: "
		local checked	= 0
		local ignored	= 0

		button			btnAbout "?"						pos:[376,8]		width:16	height:16
		ActiveXControl	axWaifs	"MSComctlLib.ListViewCtrl"	pos:[8,64]		width:384	height:126 --TreeCtrl
		label			lbl2	""							pos:[8,8]		width:360	height:16
		label			lbl1	""							pos:[8,24]		width:360	height:16
		progressBar		pb1		""							pos:[8,40]		width:384	height:8
		progressBar		pb2		""							pos:[8,48]		width:384	height:8
--		listBox			lbx1	"Waifs:"					pos:[8,64]		width:248	height:8
		button			btn2	"Close"						pos:[8,200]		width:156	height:24	enabled:false
		button			btn3	"Cancel"					pos:[304,200]	width:88	height:24	enabled:false
		-- Image list controls for holding icons
		activeXControl	ilTvSmallIcons		"{2C247F23-8591-11D1-B16A-00C0F0283628}" height:0 width:0
		-- Timer
		timer			tmrClose interval:1000 active:false

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
			windows.sendMessage axWaifs.hwnd LVM_SETCOLUMNWIDTH  0 175
	
			hName = name.columnHeaders.add()
			hName.text = "Status"
			windows.sendMessage axWaifs.hwnd LVM_SETCOLUMNWIDTH  1 100
	
			hName = name.columnHeaders.add()
			hName.text = "Faces"
			windows.sendMessage axWaifs.hwnd LVM_SETCOLUMNWIDTH  2 (axWaifs.size.x - 175 - 100 - 20)
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

		-- fnCheckVertsInLine()
		fn fnCheckVertsInLine msh va = (
			local r  = false
			local a  = #(#(1,2,3), #(2,1,3), #(1,3,2))
			local b  = 0  --#( false, false, false )

			for i = 1 to 3 do (
				local v1, v2, v3
				local xa, ya, za
				local xb, yb, zb
				local q

--					format "a[%]: %\t" i a[i]

				if ( iskindof msh editable_poly ) then
				(
					v1 = polyOp.getVert msh (va as array)[a[i][1]]
					v2 = polyOp.getVert msh (va as array)[a[i][2]]
					v3 = polyOp.getVert msh (va as array)[a[i][3]]
				)
				else
				(
					v1 = getVert msh (va as array)[a[i][1]]
					v2 = getVert msh (va as array)[a[i][2]]
					v3 = getVert msh (va as array)[a[i][3]]
				)
	
--					format "v1: %\tv2: %\t v3: %\n" v1 v2 v3
				xa = v1.x - v2.x
				ya = v1.y - v2.y
				za = v1.z - v2.z

				q  = 1.0 / sqrt ( xa*xa + ya*ya + za*za )
				xa *= q
				ya *= q
				za *= q

				xb = v3.x - v2.x
				yb = v3.y - v2.y
				zb = v3.z - v2.z

				q  = 1.0 / sqrt ( xb*xb + yb*yb + zb*zb )
				xb *= q
				yb *= q
				zb *= q

--					print ( xa*xb + ya*yb + za*zb )
				if abs ( xa*xb + ya*yb + za*zb ) > 0.999999 do
					if ( b += 1 ) == 2 do return true
			)

			return r
		)

		-- fnCheckFaceInLine()
		fn fnCheckFaceInLine msh va = (
			local tresh = 0.001
			local r = false
			local n = 1

			if (va as array).count != 3 then
			(	-- wrong vertex count
				r = true																
			)
			else
			(
				while n <= 3 do (
					local i = n + 1

					while i <= 3 do (
						local v1, v2
						
						if ( iskindof msh editable_poly ) then
						(
							v1 = polyOp.getVert msh (va as array)[n]
							v2 = polyOp.getVert msh (va as array)[i]
						)
						else
						(
							v1 = getVert msh (va as array)[n]
							v2 = getVert msh (va as array)[i]
						)
						
						if ( (va as array)[n] == (va as array)[i] ) then
						(	-- wrong indexes
							r = true
						) else if	(ABS (v1.x - v2.x) < tresh) and (ABS (v1.x - v2.x) > -tresh) and
									(ABS (v1.y - v2.y) < tresh) and (ABS (v1.y - v2.y) > -tresh) and
									(ABS (v1.z - v2.z) < tresh) and (ABS (v1.z - v2.z) > -tresh) then
						(	-- verts with same position
							r = true													
						)

						i += 1
					)

					n += 1
				)
			)
			
			return r
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
						btn2.text = "Select Faces and Close"
					else
						btn2.text = "Close"
				)
			)
		)
		
		-- fnSelectAndClose()
		fn fnSelectAndClose =
		(
			local oNum		= 1
			local oMax		= oArray.count

			pb1.value = 0
			pb2.value = 0
			btn3.enabled = false
--				btn2.enabled = false

			if oArray[1] != undefined do clearselection()

			while oNum <= oMax do (
				local obj = oArray[oNum]

				if axWaifs.ListItems[oNum].ListSubItems[1].text != "can't select" do
				(
					lbl2.text = lTxt + "Selecting faces and objects - " + oNum as string + " of " + oMax as string
					
					if axWaifs.ListItems[oNum].ListSubItems[1].text == "convert and select" do
					(
						lbl1.text = obj[1].name + " - converting"
						convertToMesh obj[1]
					)
					lbl1.text = obj[1].name + " - " + obj[2].count as string + " faces"
	
					selectmore obj[1]
	
					if ( iskindof obj[1] editable_mesh ) then
						(
							setFaceSelection obj[1] (obj[2])
						)
					else if ( iskindof obj[1] editable_poly ) then
						(
							polyOP.setFaceSelection obj[1] #{1} --obj[2]
						)
						
					pb1.value = 100.0 * oNum / oMax
				)	
				oNum += 1
			)
		)
		
		-- fnUtilizeItem()
		fn fnUtilizeItem item = case item of
		(
			#btnAbout:
			(
				PteroToolsTemp = #("Find Spike Faces", 1.5)
				fnAboutDialog()
			)
			#btnOK:
			(
				fnSelectAndClose()
				destroyDialog dlgProgress
			)
			#btnCancel:
			(
				destroyDialog dlgProgress
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
		on btn2		pressed do fnUtilizeItem #btnOK
		on btn3		pressed do fnUtilizeItem #btnCancel
		on tmrClose	tick	do fnUtilizeItem #btnCancel

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
		-- Check all
		on dlgProgress open do (
			local windowColor = colorMan.getColor #window
--			local pArray	= #()
			local oSel		= #()
			local oNum		= 1
			local oMax		= 1
			local o

			setfocus btn2
			
			-- init activeX
			fnInitAX axWaifs
			
			with redraw off
			(
				if $ == undefined or findSelectedSpiked == 0 then
					oSel = geometry
				else
					for o in $ do if (superClassOf o) == GeometryClass do append oSel o
				oMax = oSel.count
				
				btn2.enabled = false
				btn3.enabled = false
	
				while oNum <= oMax do (
					local obj = oSel[oNum]
					
					lbl2.text = lTxt + "Checking faces - " + oNum as string + " of " + oMax as string
					
	--				( not obj.isHidden ) 
					if (( iskindof obj editable_mesh ) or ( iskindof obj editable_poly )) do (
						local f		 	= 1
						local msh
						local fArray	= #()
						local lProgress = 0
						local fm
	
						if ( iskindof obj editable_mesh ) then
						(
							if isDeleted obj.mesh do
							(
								local queryStr = "ERROR: Wrong mesh data in: " + obj.name + "\n\nTo solve this problem convert node to editable mesh.\n\nConvert it now?"
								if (queryBox queryStr title:"Mesh error") do convertToMesh obj
	
								oNum += 1
								continue
							)
							msh = copy obj.mesh
							fm = getNumFaces obj
						)
						else if ( iskindof obj editable_poly ) then
						(
							local queryStr = "ERROR: Can't check editable poly: " + obj.name + "\n\nTo solve this problem convert node to editable mesh.\n\nConvert it now?"
							if (queryBox queryStr title:"Node type error") then
							(
								convertToMesh obj
								msh = copy obj.mesh
								fm = getNumFaces obj
							)
							else
							(
								oNum += 1
								continue
							)
	--						fm = polyOp.getNumFaces obj
	--						msh = copy obj
						)
							
						if (classof obj) != Targetobject do (
							lbl1.text = obj.name + " - " + fm as string + " faces"
						)
						
						while f <= fm do (
							local va
							local nProgress = ( 100.0 * f / fm ) as integer
	
							if ( iskindof obj editable_mesh ) then
								va = meshop.getVertsUsingFace msh f
							else if ( iskindof obj editable_poly ) then
								va = polyOp.getVertsUsingFace msh f
	
							if lProgress != nProgress do (
								pb2.value = nProgress as float
								lProgress = nProgress
							)
	
	--							print f
	
							if ( fnCheckFaceInLine msh va ) or ( fnCheckVertsInLine msh va ) do
								append fArray f
	
							f += 1
						)
						if fArray.count > 0 do (
							local s = ""
							local t = ""
							local c = (color 0 0 0)
							local i = 2
	
							if (( iskindof obj editable_mesh ) or ( iskindof obj editable_poly )) and obj.modifiers.count == 0 then ()
							else
							(
								s = "can't select"									-- isn't EditableMesh
								t = "Double click to convert this node to Editable mesh"
								c = (color (128*windowColor[1]) (128*windowColor[2]) (128*windowColor[3]))
								i = 1
								ignored += 1
							)
							append oArray #(obj, (fArray as bitArray))				-- is EditableMesh
							fnAddItem axWaifs #(obj.name, s, (fArray.count as string + " face(s)")) tooltip:t icon:i forecolor:c
						)
						checked += 1
					)
	
					pb1.value = 100.0 * oNum / oMax
	
					oNum += 1
				)
			)
			
			lbl1.text = "Checked: " + checked as string + "\t\tFound: " + axWaifs.listItems.count as string + "\t\tIgnored: " + ignored as string
			lbl2.text = lTxt + "Done"
			if ( axWaifs.listItems.count != 0 ) and ( ignored != axWaifs.listItems.count ) do btn2.text = "Select Faces and Close"
			btn3.enabled = true
			btn2.enabled = true
			if oMax != 0 do btn2.enabled = true
			
			if findSelectedSpiked > -1 then
			(
				if axWaifs.listItems.count > 0 then
				(
					findSelectedSpiked = axWaifs.listItems.count
				)
				else
				(
					findSelectedSpiked = 0
					btn3.enabled = false
					btn2.enabled = false
					tmrClose.active = true
				)
			)
		)
	)

	-- Create Dialog
	if findSelectedSpiked == undefined do findSelectedSpiked = -1
--	try (
		createDialog dlgProgress modal:true --style:#(#style_titlebar, #style_border)
--	) catch ()
	gc()
)

---------------------------------------------------------------
-- fnPrintMappingToBitmap()
---------------------------------------------------------------
global PrintMappingToBitmap = false
rollout roPMTB "Print mapping to bitmap" width:472 height:344 (
	-- locals
	local _iniSect	= "PteroPrintToBitmap"
	local sizeTable = #("4", "8", "16", "32", "64", "128", "256", "512", "1024", "2048")
	local TextureTable = #()
	local map
	local mesh, faceSel

	-- init gui
	GroupBox grp5 "Mapping" pos:[8,8] width:224 height:72
		label lbl19 "Mapping Channel:" pos:[16,24] width:96 height:16
		spinner spnMapCh "" pos:[115,24] width:48 height:16 range:[1,99,1] type:#integer scale:1
		label lbl47 "Used Faces:" pos:[16,44] width:88 height:16
		radiobuttons rdoUsedFaces "" pos:[114,44] width:89 height:32 labels:#("Whole Mesh", "Selected Only") columns:1
	GroupBox grp1 "File" pos:[8,88] width:224 height:128
		label lbl5 "Save to:" pos:[16,104] width:208 height:16
		radiobuttons rdoSaveTo "" pos:[21,120] width:23 height:32 labels:#("", "") columns:1
		edittext edtSaveTo "" pos:[40,120] width:168 height:16
		button btnBrowse "..." pos:[208,120] width:16 height:16 toolTip:"Browse ..."
		dropdownList drpSaveTo "" pos:[44,136] width:181 height:21
		label lbl28 "Save Method:" pos:[16,160] width:88 height:16
		radiobuttons rdoSaveMethod "" pos:[114,160] width:68 height:32 labels:#("Draw into", "Overwrite") columns:1
		checkbox chkCreateBackup "Create Backup" pos:[20,192] width:208 height:16 checked:false
	GroupBox grp6 "Drawing" pos:[8,224] width:224 height:112
		label lbl66 "New Bitmap Size:" pos:[16,244] width:96 height:16
		dropdownList drpSizeX "" pos:[116,240] width:48 height:21 items:#("4", "8", "16", "32", "64", "128", "256", "512", "1024", "2048") selection:7
		label lbl67 "X" pos:[166,244] width:8 height:16
		dropdownList drpSizeY "" pos:[176,240] width:48 height:21 items:#("4", "8", "16", "32", "64", "128", "256", "512", "1024", "2048") selection:7
		label lbl6 "Bitmap Background:" pos:[16,264] width:96 height:16
		colorPicker cpBackground "" pos:[112,264] width:32 height:16 color:(color 255 255 255)
		label lbl3 "Visible Edges:" pos:[16,280] width:96 height:16
		colorPicker cpVisEdge "" pos:[112,280] width:32 height:16 color:(color 0 0 0)
		label lbl4 "Invisible Edges:" pos:[16,296] width:96 height:16
		colorPicker cpUnvisEdge "" pos:[112,296] width:32 height:16 color:(color 200 200 200)
		checkbox chkDrawUnvis "Draw" pos:[152,296] width:72 height:16 checked:true
		checkbox chkDrawSelFacesOnly "Draw faces with selected bitmap only" pos:[16,312] width:208 height:16 enabled:false checked:true
	GroupBox grp2 "Preview" pos:[240,8] width:224 height:232
		ImgTag imgBitmap "Bitmap" pos:[248,24] width:208 height:208 -- bitmap:(bitmap 208 208 color:(color 255 255 255)) tooltip:"Click to show in real size"
		button btnAbout "?" pos:[448,248] width:16 height:16 toolTip:"About ..."
		button btnGenerate "GENERATE" pos:[304,312] width:72 height:24
		button btnSave "SAVE" pos:[392,312] width:72 height:24

	-- fnShowTexture
	fn fnShowTexture del:true =
	(
		local bMap = bitmap 208 208 color:backgroundColor
		local fExist = true
		
		if rdoSaveMethod.state == 1 then
			if rdoSaveTo.state == 1 then
				try (bMap = openBitmap edtSaveTo.text) catch (fExist = false)
			else if drpSaveTo.selection > 0 do
				try (bMap = openBitmap TextureTable[drpSaveTo.selection]) catch (fExist = false)
		else
			bMap = bitmap (drpSizeX.selected as integer) (drpSizeY.selected as integer) color:cpBackground.color
	
		imgBitmap.bitmap = fnScaleBitmap m:bMap w:208 h:208
		imgBitmap.style = #bmp_center
		
		if rdoSaveMethod.state == 1 and del or rdoSaveMethod.state == 2 then
		(
			map = undefined
			btnSave.enabled = false
		)
		
		if selection.count == 0 then
			btnGenerate.enabled = false
		else
			btnGenerate.enabled = fExist
	)
	
	-- fnGetTextures()
	fn fnGetTextures = (
		local matTemp = #()
		local mats = #()
		local ret = #()
	
		if selection.count == 0 do return ret
		
		for s in selection do (
			-- skip dummy
			if classof s == Dummy do continue
			mesh = copy s.mesh
			faceSel = #()
			if rdoUsedFaces.state == 1 then
				faceSel = #{1..mesh.numfaces}
			else
				faceSel = getFaceSelection mesh
			
			if not meshop.getMapSupport mesh spnMapCh.value do continue
			
			if (faceSel as array)[1] == undefined do faceSel = #{1..(meshop.getNumMapFaces mesh spnMapCh.value)}
			
			if (classof s.material) == multimaterial then
			(
				for n in faceSel do (
					local matID = getFaceMatID mesh n
					local matIDX = findItem s.material.materialIDList matID
					
					if matIDX != 0 and s.material.materialList[matIDX] != undefined do
					(
						if (findItem matTemp s.material.materialList[matIDX].name) == 0 then
						(
							append matTemp s.material.materialList[matIDX].name
							append mats s.material.materialList[matIDX]
						)
					)
				)
			)
			else
			(
				if (findItem matTemp s.material.name) == 0 then
				(
					append matTemp s.material.name
					append mats s.material
				)
			)
		)
		
		for m in mats do
		(
			try ( local count = m.maps.count ) catch continue
			
			for n = 1 to count do
			(
				if m.maps[n] != undefined and (classof m.maps[n]) == Bitmaptexture and m.maps[n].filename != undefined and (findItem ret m.maps[n].filename) == 0 do
				(
					append ret m.maps[n].filename
				)
			)
		)
		
		return ret
	)
	
	-- fnGetItems()
	fn fnGetItems =
	(
		local items = #()
		TextureTable = fnGetTextures()
		for t in TextureTable do append items ((getFilenameFile t) + (getFilenameType t))
		drpSaveTo.selection = 1
		drpSaveTo.items = items
		
		fnShowTexture()
	)
	
	-- fnGenerate()
	fn fnGenerate = (
		local newMap = bitmap (drpSizeX.selected as integer) (drpSizeY.selected as integer) color:cpBackground.color
		
		if selection.count == 0 do (
			imgBitmap.enabled = false
			messageBox "Nothing selected!" title:"Print mapping to bitmap"
			imgBitmap.enabled = true
			return false
		)

		if rdoSaveMethod.state == 1 then
		(
			if rdoSaveTo.state == 1 then
				imgBitmap.bitmap = fnScaleBitmap m:(openBitmap edtSaveTo.text) w:208 h:208
			else
			(
				if drpSaveTo.items.count > 0 do
					imgBitmap.bitmap = fnScaleBitmap m:(openBitmap TextureTable[drpSaveTo.selection]) w:208 h:208
			)
		) else
			imgBitmap.bitmap = (bitmap 208 208 color:(color 255 255 255))

		if rdoSaveMethod.state == 1 do (
			local tmp
			if rdoSaveTo.state == 1 then
				tmp = fnFindFile edtSaveTo.text #( ".dds", ".bmp", ".tga" )
			else
				tmp = fnFindFile (TextureTable[drpSaveTo.selection]) #( ".dds", ".bmp", ".tga" )
			if tmp != undefined then
				try (newMap = copy (openBitmap tmp)) catch ()
		)
			
		for s in selection do (
			mesh = copy s.mesh
			faceSel = #()
			if rdoUsedFaces.state == 1 then
				faceSel = #{1..mesh.numfaces}
			else
				faceSel = getFaceSelection mesh
			
			if not meshop.getMapSupport mesh spnMapCh.value do continue
			
			if (faceSel as array)[1] == undefined do faceSel = #{1..(meshop.getNumMapFaces mesh spnMapCh.value)}
			
			for n in faceSel do (
				local mapVerts = meshop.getMapFace mesh spnMapCh.value n
				local mapVert = #()
				
				for k = 1 to 3 do (
					mapVert[k] = meshop.getMapVert mesh spnMapCh.value mapVerts[k]
					mapVert[k].x = (mapVert[k].x * newMap.width) as integer
					mapVert[k].y = ((1 - mapVert[k].y) * newMap.height) as integer
				)
				
				for k = 1 to 3 do (
					local vis = getEdgeVis mesh n k
					if vis or chkDrawUnvis.checked do
						fnDrawBitmapLine newMap mapVert[k] mapVert[(if k < 3 then k + 1 else 1)] (if vis then cpVisEdge.color else cpUnvisEdge.color)
				)
			)
		)

		imgBitmap.bitmap = fnScaleBitmap m:newMap w:208 h:208
		imgBitmap.style = #bmp_center
		
		btnSave.enabled = true
		
		return copy newMap
	)
	
	-- fnSave()
	fn fnSave map = (
		local tmp, tmp2
		
		if rdoSaveTo.state == 1 then
			try
			(
				tmp = edtSaveTo.text
				if tmp == undefined do
				(
					messageBox "Enter correct path and filename please!" title:"Save bitmap"
					return 0;
				)
			) catch ()
		else if drpSaveTo.selection > 0 do
			try
			(
				tmp = TextureTable[drpSaveTo.selection]
				tmp = fnFindFile tmp #( ".bmp", ".tga", ".ifl" )
				if tmp == undefined do
				(
					messageBox "Can find your texture!" title:"Save bitmap"
					return 0;
				)
			) catch
			(
				messageBox "Some problem with selected texture ... Sorry!" title:"Save bitmap"
				return 0;
			)
		
		if tmp == undefined do
		(
			messageBox "I don't know where to save ... Sorry!" title:"Save bitmap"
			return 0;
		)

		if (fnupcase (getFilenameType tmp)) == ".DDS" do
		(
			messageBox "Can't save DDS format file!" title:"Save bitmap"
			return false
		)
		
		if map == undefined do (
			imgBitmap.enabled = false
			messageBox "There is nothing to Save!" title:"Save bitmap"
			imgBitmap.enabled = true
			return false
		)
		
		try (
			if chkCreateBackup.checked and (doesFileExist edtSaveTo.text)do (
				local newFile = (getFilenamePath tmp) + (getFilenameFile tmp) + "_backup" + (getFilenameType tmp)
				copyFile tmp newFile
			)
		) catch (
			messageBox "Can't create backup of Bitmap file." title:"Save bitmap"
		)
		
		try (
			map.filename = tmp
			save map
			close map
		) catch (
			messageBox "Something very bad is very wrong." title:"Save bitmap"
			return false
		)

		imgBitmap.enabled = false
		messageBox ("I believe that Your Bitmap is safe now.\n\nFile: " + tmp) title:"Save bitmap"
		imgBitmap.enabled = true
	)
	
	-- fnCheckName()
	fn fnCheckName = (
		if (getFilenamePath edtSaveTo.text) == "" do edtSaveTo.text = (getDir #image) + "\\" + edtSaveTo.text
		if (getFilenameFile edtSaveTo.text) == "" do edtSaveTo.text += "default"
		if (getFilenameType edtSaveTo.text) == "" do edtSaveTo.text += ".bmp"
		rdoSaveTo.state = 1
		fnShowTexture()
	)
	
	-- fnBrowse()
	fn fnBrowse = (
		local tmp = getBitmapSaveFilename()
		if tmp == undefined do return false
		edtSaveTo.text = tmp
		rdoSaveTo.state = 1
	)
	
	-- fnOpen()
	fn fnOpen = (
		tmp = fnLoadINIexec "MapChannel" (fnReturnFilename #ini) _iniSect
		if tmp != OK do spnMapCh.value = tmp
		tmp = fnLoadINIexec "BitmapSize" (fnReturnFilename #ini) _iniSect
		if tmp != OK do (
			if (tmp2 = findItem sizeTable ((tmp[1] as integer) as string)) != 0 do drpSizeX.selection = tmp2
			if (tmp2 = findItem sizeTable ((tmp[2] as integer) as string)) != 0 do drpSizeY.selection = tmp2
		)
		tmp = fnLoadINIexec "Background" (fnReturnFilename #ini) _iniSect
		if tmp != OK do cpBackground.color = tmp
		tmp = fnLoadINIexec "VisibleEdge" (fnReturnFilename #ini) _iniSect
		if tmp != OK do cpVisEdge.color = tmp
		tmp = fnLoadINIexec "InvisibleEdge" (fnReturnFilename #ini) _iniSect
		if tmp != OK do cpUnvisEdge.color = tmp
		tmp = fnLoadINIexec "DrawInvisible" (fnReturnFilename #ini) _iniSect
		if tmp != OK do chkDrawUnvis.checked = tmp
		tmp = fnLoadINIexec "SourceType" (fnReturnFilename #ini) _iniSect
		if tmp != OK do rdoSaveTo.state = tmp
		tmp = fnLoadINI "FileName" (fnReturnFilename #ini) _iniSect
		if tmp != OK do edtSaveTo.text = tmp
		tmp = fnLoadINIexec "SaveMethod" (fnReturnFilename #ini) _iniSect
		if tmp != OK do rdoSaveMethod.state = tmp
		tmp = fnLoadINIexec "UsedFaces" (fnReturnFilename #ini) _iniSect
		if tmp != OK do rdoUsedFaces.state = tmp
		tmp = fnLoadINIexec "CreateBackup" (fnReturnFilename #ini) _iniSect
		if tmp != OK do chkCreateBackup.checked = tmp
		
		fnGetItems()
		
		callbacks.addScript #selectionSetChanged "roPMTB.fnGetItems()" id:#printMapping

 			PrintMappingToBitmap = true
		updateToolbarButtons()
	)
	
	-- fnClose()
	fn fnClose = (
		fnSaveINI "MapChannel"		(spnMapCh.value as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "BitmapSize"		("["+drpSizeX.selected+","+drpSizeY.selected+"]") (fnReturnFilename #ini) _iniSect
		fnSaveINI "Background"		(cpBackground.color as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "VisibleEdge"		(cpVisEdge.color as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "InvisibleEdge"	(cpUnvisEdge.color as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "DrawInvisible"	(chkDrawUnvis.checked as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "SourceType"		(rdoSaveTo.state as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "FileName"		edtSaveTo.text (fnReturnFilename #ini) _iniSect
		fnSaveINI "SaveMethod"		(rdoSaveMethod.state as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "UsedFaces"		(rdoUsedFaces.state as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "DialogPosition"	((getDialogpos roPMTB) as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "CreateBackup"	(chkCreateBackup.checked as string) (fnReturnFilename #ini) _iniSect
		
		callbacks.removeScripts id:#printMapping

		destroyDialog roPMTB
		PrintMappingToBitmap = false
		updateToolbarButtons()
	)
	
	-- event handles
	on btnAbout		pressed	do (PteroToolsTemp = #("Print Mapping to Bitmap", 1.1); fnAboutDialog())
	on imgBitmap	click	do try (display map) catch ()
	on btnGenerate	pressed	do map = fnGenerate()
	on btnSave		pressed	do fnSave map
	on btnClose		pressed	do fnClose() --destroyDialog roPMTB
	on rdoUsedFaces changed state do fnGetItems()
	on rdoSaveTo	changed state do fnShowTexture()
	on edtSaveTo	entered	val do fnCheckName()
	on btnBrowse	pressed do (fnBrowse(); fnShowTexture())
	on drpSaveTo	selected val do ( rdoSaveTo.state = 2; fnShowTexture() )
	on rdoSaveMethod changed state do fnShowTexture()
	on cpBackground changed col do fnShowTexture del:false
	on drpSizeX		selected val do fnShowTexture del:false
	on drpSizeY		selected val do fnShowTexture del:false
	on spnMapCh		entered do fnShowTexture()
	on roPMTB		open	do fnOpen()
	on roPMTB		close	do fnClose()
)
fn fnPrintMappingToBitmap = (
	local _iniSect	= "PteroPrintToBitmap"
	
	-- Create Dialog 
	if PrintMappingToBitmap != true then
	(
		if (p = fnLoadINIexec "DialogPosition" (fnReturnFilename #ini) _iniSect) == OK do p = [50,50]

		createDialog roPMTB modal:false pos:p --style:#(#style_titlebar, #style_border) pos:p
	)
	else
		destroyDialog roPMTB
)

---------------------------------------------------------------
-- fnPteroSettings()
---------------------------------------------------------------
fn fnPteroSettings = (
	rollout SettingsRollout "PteroSettings" width:288 (
		-- locals
		local _iniSect	= "General"
		local oldEnginePath = ""
		
		-- init GUI
		groupBox	grp1		"Paths"		pos:[8,8] width:272 height:104
		label		lblEngFile	"Engine File:"	pos:[16,25] width:58 height:16
		editText	edtEngFile	""			pos:[74,24] width:198 height:16
		label		lblEngine	"Engine:"	pos:[16,41] width:48 height:16
		editText	edtEngine	""			pos:[74,40] width:182 height:16
		button		btnEngine	"..."		pos:[256,40] width:16 height:16	toolTip:"Browse ..."
		label		lblScenes	"Scenes:"	pos:[16,57] width:48 height:16
		editText	edtScenes	""			pos:[74,56] width:166 height:16
		button		btnScnDef	"D"			pos:[240,56] width:16 height:16	toolTip:"Set to Default"
		button		btnScnPath	"..."		pos:[256,56] width:16 height:16	toolTip:"Browse ..."
		label		lblModels	"Models:"	pos:[16,73] width:48 height:16
		editText	edtModels	""			pos:[74,72] width:166 height:16
		button		btnModDef	"D"			pos:[240,72] width:16 height:16	toolTip:"Set to Default"
		button		btnModPath	"..."		pos:[256,72] width:16 height:16	toolTip:"Browse ..."
		label		lblTextures	"Textures:"	pos:[16,89] width:48 height:16
		editText	edtTextures	""			pos:[74,88] width:166 height:16
		button		btnTexDef	"D"			pos:[240,88] width:16 height:16	toolTip:"Set to Default"
		button		btnTexPath	"..."		pos:[256,88] width:16 height:16	toolTip:"Browse ..."
		groupBox	grpShader	"Shaders"	pos:[8,112] width:272 height:56
		radioButtons rdoShaders ""			pos:[16,128] width:160 height:32 labels:#("Generate Shaders List from Engine", "Use Default Shaders List") enabled:false
		groupBox	grpSurfaces "Surfaces"	pos:[8,168] width:272 height:56
		radioButtons rdoSurfaces ""			pos:[16,184] width:160 height:32 labels:#("Generate Surfaces List from Engine", "Use Default Surfaces List")
		GroupBox	grpMisc		"Miscellaneous" pos:[8,224] width:272 height:56
		checkbox	chkPrecacheBitmaps "Precache bitmaps after new scene is loaded" pos:[16,240] width:240 height:16
		checkbox	chkOpenPteroProps "Open pteroProps Panel at 3DS Max startup" pos:[16,257] width:240 height:16
		label		lblNote		"Note: You have to fill Engine File and Path!" pos:[8,293] width:224 height:16
		button		btnClose	"Close"		pos:[220,290] width:60

		-- fnGetPath()
		fn fnGetPath type path:"" = (
			
			fn fnPath type:type = 
				getSavePath caption:("Choose a folder with : " + (fnUpcase (type as string)))

			fn fnReplaceStringSetting strTarget strOld strNew = 
				replace strTarget (findString strTarget strOld) strOld.count strNew
			
			fn fnFindEngineFile path = (
				local pArray = #("\\", "\\dev\\engine\\")
				local ret = undefined
				local n = 0
				while (n += 1) <= pArray.count do
					if (ret = fnFindFile (path + pArray[n] + edtEngFile.text) #(".exe")) != undefined do exit
				return ret
			)
			
			case type of (
				#engine : (
					local isPath = fnFindEngineFile path
					while isPath == undefined do (
						path = fnPath()
						if path == undefined do (
							edtEngine.text = oldEnginePath
							return false
						)
						if (isPath = fnFindEngineFile path) == undefined do
							messageBox "You entered wrong engine path or filename!" title:"Wrong path"
					)
					if edtScenes.text.count == 0 then edtScenes.text = path + "\\levels"
					else if (findString edtScenes.text edtEngine.text) != undefined do
							edtScenes.text = fnReplaceStringSetting edtScenes.text edtEngine.text path
					if edtModels.text.count == 0 then edtModels.text = path + "\\g"
					else if (findString edtModels.text edtEngine.text) != undefined do
							edtModels.text = fnReplaceStringSetting edtModels.text edtEngine.text path
					if edtTextures.text.count == 0 then edtTextures.text = path + "\\g\\textures"
					else if (findString edtTextures.text edtEngine.text) != undefined do
							edtTextures.text = fnReplaceStringSetting edtTextures.text edtEngine.text path
					edtEngine.text	= path
					oldEnginePath	= path
				)
				#scenes : (
					path = fnPath()
					if path == undefined do return false
					edtScenes.text = path
				)
				#models : (
					path = fnPath()
					if path == undefined do return false
					edtModels.text = path
				)
				#textures : (
					path = fnPath()
					if path == undefined do return false
					edtTextures.text = path
				)
				#scenesDef : if edtEngine.text.count > 0 do edtScenes.text = edtEngine.text + "\\levels"
				#modelsDef : if edtEngine.text.count > 0 do edtModels.text = edtEngine.text + "\\g"
				#texturesDef : if edtEngine.text.count > 0 do edtTextures.text = edtEngine.text + "\\g\\textures"
			)
			
			fnSaveINI "EngineFile"	edtEngFile.text (fnReturnFilename #ini) _iniSect
			fnSaveINI "EnginePath"	edtEngine.text (fnReturnFilename #ini) _iniSect
			fnSaveINI "ScenesPath"	edtScenes.text (fnReturnFilename #ini) _iniSect
			fnSaveINI "ModelsPath"	edtModels.text (fnReturnFilename #ini) _iniSect
			fnSaveINI "TexturesPath"	edtTextures.text (fnReturnFilename #ini) _iniSect
			return true
		)
		
		-- fnCanClose()
		fn fnCanClose = (
			-- save Settings
			fnSaveINI "PrecacheBitmaps"	(chkPrecacheBitmaps.checked as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "DialogOpen"		(chkOpenPteroProps.checked as string) (fnReturnFilename #ini) (fnReturnSection #ini)
			fnSaveINI "ShadersListType"	(rdoShaders.state as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "SurfaceListType"	(rdoSurfaces.state as string) (fnReturnFilename #ini) _iniSect
			if not (fnGetPath #engine path:edtEngine.text) then return false
			if edtEngFile.text	== "" do return false
			if edtEngine.text	== "" do return false
			if edtModels.text	== "" do return false
			if edtTextures.text	== "" do return false
			destroyDialog SettingsRollout
		)
		
		-- Event Handler
		on edtEngFile	entered	val	do fnGetPath #engine path:edtEngine.text
		on edtEngine	entered	val	do fnGetPath #engine path:val
		on btnEngine	pressed		do fnGetPath #engine
		on edtScenes	entered	val	do ()
		on btnScnDef	pressed		do fnGetPath #scenesDef
		on btnScnPath	pressed		do fnGetPath #scenes
		on edtModels	entered	val	do ()
		on btnModDef	pressed		do fnGetPath #modelsDef
		on btnModPath	pressed		do fnGetPath #models
		on edtTextures	entered	val	do ()
		on btnTexDef	pressed		do fnGetPath #texturesDef
		on btnTexPath	pressed		do fnGetPath #textures
		on chkOpenPteroProps changed state do
		try (
			local idx = fnFindControl mainRollout.controls "btnLock"
			if idx > 0 do if mainRollout != undefined do mainRollout.controls[idx].checked = state
		) catch ()
		on rdoShaders	changed state do ()
		on rdoSurfaces	changed state do ()
		on btnClose		pressed		do fnCanClose()
		on SettingsRollout open		do (
			local tmp
			tmp = fnLoadINI "EngineFile" (fnReturnFilename #ini) _iniSect
			edtEngFile.text = if tmp == "undefined" or tmp == ok or tmp == "" then "pten.exe" else tmp

			tmp = fnLoadINI "EnginePath" (fnReturnFilename #ini) _iniSect
			edtEngine.text = if tmp == "undefined" or tmp == ok then "" else tmp
			oldEnginePath = edtEngine.text

			tmp = fnLoadINI "ScenesPath" (fnReturnFilename #ini) _iniSect
			edtScenes.text = if tmp == "undefined" or tmp == ok then "" else tmp

			tmp = fnLoadINI "ModelsPath" (fnReturnFilename #ini) _iniSect
			edtModels.text = if tmp == "undefined" or tmp == ok then "" else tmp

			tmp = fnLoadINI "TexturesPath" (fnReturnFilename #ini) _iniSect
			edtTextures.text = if tmp == "undefined" or tmp == ok then "" else tmp

			tmp = fnLoadINIexec "PrecacheBitmaps" (fnReturnFilename #ini) _iniSect
			if tmp == ok or tmp == undefined then tmp = true
			chkPrecacheBitmaps.checked = tmp

			tmp = fnLoadINIexec "DialogOpen" (fnReturnFilename #ini) (fnReturnSection #ini)
			if tmp == ok or tmp == undefined then tmp = true
			chkOpenPteroProps.checked = tmp

			tmp = fnLoadINIexec "ShadersListType" (fnReturnFilename #ini) _iniSect
			rdoShaders.state = if tmp == undefined or tmp == ok then 1 else tmp

			tmp = fnLoadINIexec "SurfaceListType" (fnReturnFilename #ini) _iniSect
			rdoSurfaces.state = if tmp == undefined or tmp == ok then 1 else tmp
		)
		on SettingsRollout close	do (
			-- setup Surfaces list
			_colMatTable = fnReturnColMats()
			if _colMatTable[2] == undefined do _colMatTable = fnLoadMats()
			-- setup Shaders list
			pteroShaderList.fnUpdate()
		)
	)
	-- Create Dialog
	createDialog SettingsRollout modal:true style:#(#style_titlebar, #style_border)
)

---------------------------------------------------------------
-- fnOpenCreateBBoxDialog()
---------------------------------------------------------------
struct _bBox (bMin, bMax)
global createBBoxDialog = false
fn fnOpenCreateBBoxDialog = (
	local _iniSect	= "CreateBBox"
	rollout createBBox "Create pteroBBox" width:192 height:120 (
		-- locals
		local _iniSect	= "CreateBBox"
		
		-- init GUI
		checkbox		chkMode		"Create BBox for Each Node"	pos:[8,8] width:152 height:16
		button			btnAbout	"?"							pos:[168,8] width:16 height:16 tooltip:"About ..."
		checkbox		chkSelect	"Select Created BBox(es)"	pos:[8,24] width:152 height:16
		radiobuttons	rdoType		"Type of BBox(es):"			pos:[8,48] width:122 height:30 labels:#("Mesh", "Dummy") columns:2
--		label			lbl1		"Selected:"					pos:[8,88] width:48 height:16
--		label			lblSelected	""							pos:[56,88] width:128 height:16
		button			btnCreate	"Create"					pos:[8,88] width:176 height:24
		
		-- fnCreateBBoxNode()
		fn fnCreateBBoxNode bBox type = (
			local pos	= (bBox.bMin + bBox.bMax) / 2
			local size	= bBox.bMax - bBox.bMin
			local newbBox
		
			case type of (
				#box : (
					newBBox = box width:size.x length:size.y height:size.z
					newBBox.pivot.z += size.z / 2.0
					newBBox.pos = pos
				)
				#dummy : (
					newBBox = dummy boxsize:size
					newBBox.pos = pos
				)
			)
			
			return newBBox
		)
		
		-- fnGetBBoxSingle()
		fn fnGetBBoxSingle node = (
			local bBox = _bBox node.min node.max
			return bBox
		)
		
		-- fnGetBBoxGroup()
		fn fnGetBBoxGroup sel = (
			local bBox
			local bBoxTemp
			
			for s in sel do (
				bBoxTemp = fnGetBBoxSingle s
				
				if bBox == undefined then
					bBox = bBoxTemp
				else (
					if bBox.bMax.x < bBoxTemp.bMax.x do bBox.bMax.x = bBoxTemp.bMax.x
					if bBox.bMax.y < bBoxTemp.bMax.y do bBox.bMax.y = bBoxTemp.bMax.y
					if bBox.bMax.z < bBoxTemp.bMax.z do bBox.bMax.z = bBoxTemp.bMax.z
			
					if bBoxTemp.bMin.x < bBox.bMin.x do bBox.bMin.x = bBoxTemp.bMin.x
					if bBoxTemp.bMin.y < bBox.bMin.y do bBox.bMin.y = bBoxTemp.bMin.y
					if bBoxTemp.bMin.z < bBox.bMin.z do bBox.bMin.z = bBoxTemp.bMin.z
				)
			)
			
			return bBox
		)
		
		-- fnUtilizeBBox()
		fn fnUtilizeBBox type mode selectBB = (
			local sel	 = selection
			local newSel = #()
			local bBox
			
			if sel.count == 0 do (
				messageBox "Nothig selected." title:"Create pteroBBox"
				return false
			)
			
			case mode of (
				#each :
					for s in sel do (
						bBox = fnGetBBoxSingle s
						append newSel (fnCreateBBoxNode bBox type)
					)
				#multi : (
					bBox = fnGetBBoxGroup sel
					newsel = fnCreateBBoxNode bBox type
				)
			)
			
			if selectBB do
				select newSel
				
			return true
		)
		
		-- event handles
		on btnAbout pressed do (PteroToolsTemp = #("Create pteroBBox", 1.0); fnAboutDialog())
		on btnCreate pressed do (
			local type = if rdoType.state == 1 then #box else #dummy
			local mode = if chkMode.checked then #each else #multi
			local selectBB = chkSelect.checked
			fnUtilizeBBox type mode selectBB
		)
		on createBBox open do (
			tmp = fnLoadINIexec "BBoxType" (fnReturnFilename #ini) _iniSect
			if tmp != OK do rdoType.state = tmp
			tmp = fnLoadINIexec "CreateEach" (fnReturnFilename #ini) _iniSect
			if tmp != OK do chkMode.checked = tmp
			tmp = fnLoadINIexec "SelectBBoxes" (fnReturnFilename #ini) _iniSect
			if tmp != OK do chkSelect.checked = tmp
			
			createBBoxDialog = true
			updateToolbarButtons()
		)
		on createBBox close do (
			fnSaveINI "DialogPosition"	((getDialogpos createBBox) as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "BBoxType"		(rdoType.state as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "CreateEach"		(chkMode.checked as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "SelectBBoxes"	(chkSelect.checked as string) (fnReturnFilename #ini) _iniSect
			
			createBBoxDialog = false
			updateToolbarButtons()
		)
	)
	
	if createBBoxDialog == false then (
		if (p = fnLoadINIexec "DialogPosition" (fnReturnFilename #ini) _iniSect) == OK do p = [50,50]

		createDialog createBBox modal:false pos:p
	) else
		destroyDialog createBBox
)

---------------------------------------------------------------
-- BES Info Dialog
---------------------------------------------------------------
-- fnNumLods
fn fnNumLods obj = (
	local ret = 0
	for child in obj.children do (
		local char = substring child.name 1 1
		if char == ">" do (
			ret += 1
			if child.children.count >= 0 do (
				ret += fnNumLods child
			)
		)
	)
	return ret
)
-- fnNumLodsFaces
fn fnNumLodsFaces obj = (
	local ret = #()
	if obj.parent == undefined do
		try (append ret obj.mesh.numFaces) catch (append ret 0)
	for child in obj.children do (
		local char = substring child.name 1 1
		if char == ">" do (
			try (append ret child.mesh.numFaces) catch (append ret 0)
			if child.children.count > 0 do
				join ret (fnNumLodsFaces child)
		)
	)
	return ret
)
-- fnPrintNumFaces
fn fnPrintNumFaces numFaces = (
	local retStr = ""
	if numFaces[1] == undefined do numFaces[1] = 0
	for n = 1 to numFaces.count do (
		retStr += numFaces[n] as string
		if n < numFaces.count do
			retStr += ", "
	)
	retStr += "\n"
	return retStr
)
-- fnCreateBesInfo
fn fnCreateBesInfo = (
	local sceneObjects = $*
	local sceneMaps = #()
	local tmp = #()
	local strepName = "strep"
	local retStr = ""
	local strepCount = 0
	local strepFaces = 0
	local objBuffer, isPhysic, isAlpha

	for mat in sceneMaterials do
		tmp = fnFillMapArray mat tmp
	for map in tmp do
		if (findItem sceneMaps map.filename) == 0 do append sceneMaps map.filename
	sceneMaps = sort sceneMaps
	
	for obj in sceneObjects do (
		local char = substring obj.name 1 1
		local numLods, numFaces
		
		if (fnUpCase (substring obj.name 1 strepName.count)) == (fnUpCase strepName) do (
			strepCount += 1
			try (strepFaces += obj.mesh.numFaces) catch()
			continue
		)
		
--		format "%\t%\n" obj.name (obj.superclassid)
		case (obj.superClassID) of (
			16 : () -- edit mesh
			80 : () -- dummy
			48 : () -- light
			default : continue
		)
		
		if char != "&" and char != ">" and char != "^" and char != "!" then (
			-- main node
			objBuffer = getUserPropBuffer obj
			isPhysic = findString objBuffer "Phy_weight"
			isAlpha = findString objBuffer "LastLodAlpha"
			numLods = fnNumLods obj
			numFaces = fnNumLodsFaces obj

			if retStr != "" do retStr += "\n"
			retStr += "Node     : " + obj.name + "\n"
			retStr += "  Type    : " + (Classof obj) as string + "\n"
			if numLods > 0 do (
				retStr += "  Lods    : " + numLods as string + "\n"
				if isAlpha != undefined do
					retStr += "  LastAlpha: yes\n"
			)
			if numFaces.count > 1 or numFaces.count == 1 and numFaces[1] != 0 do (
				retStr += "  Faces  : "
				retStr += (fnPrintNumFaces numFaces)
			)
			if isPhysic != undefined do
				retStr += "  Physical : yes\n"
		) else if char == "&" then (
			-- destructed node
			objBuffer = getUserPropBuffer obj
			isAlpha = findString objBuffer "LastLodAlpha"
			numLods = fnNumLods obj
			numFaces = try (#(obj.mesh.numFaces)) catch (#(0))
			
			join numFaces (fnNumLodsFaces obj)
			
			retStr += "  Destroy  : " + obj.name + "\n"
			if numLods > 0 do (
				retStr += "    Lods   : " + numLods as string + "\n"
				if isAlpha != undefined do
					retStr += "  LastAlpha: yes\n"
			)
			if numFaces.count > 1 or numFaces.count == 1 and numFaces[1] != 0 do (
				retStr += "    Faces  : "
				retStr += (fnPrintNumFaces numFaces)
			)
		) else if char == "^" or char == "!" then (
			-- Collision node
			numFaces = try (#(obj.mesh.numFaces)) catch (#(0))
			retStr += "  Collision  : " + obj.name + "\n"
			if numFaces.count > 1 or numFaces.count == 1 and numFaces[1] != 0 do (
				retStr += "    Faces  : "
				retStr += (fnPrintNumFaces numFaces)
			)
		)
	)
	
	if strepCount > 0 do (
		retStr += "\n"
		retStr += "Shards     : " + strepCount as string + "\n"
		retStr += "  Name     : " + strepName + "#\n"
		retStr += "  Faces    : " + strepFaces as string + "\n"
	)
	
	if sceneMaps.count > 0 do (
		retStr += "\n"
		retStr += "Textures: " + sceneMaps.count as string + "\n"
		for tex in sceneMaps do (
			retStr += "  " + (getfilenamefile tex) + "\n"
		)
	)
	
	return retStr
)

---------------------------------------------------------------
-- BES Info Dialog
---------------------------------------------------------------
struct _objVis ( nodes = #(), hidden = #())

-- fnLodText()
fn fnLodText = (
	local viewText = "Show LODs Enabled"
	local lastViewport
	local textPos = [20,65,0]
	local updateRect = box2 (textPos.x) (textPos.y-(gw.getTextExtent "X").y) 0 0
	
	if viewport.activeViewport != lastViewport then	(
		completeredraw()
		lastViewport = viewport.activeViewport 
	) else (
		local rect = gw.getTextExtent viewText
		updateRect.w = rect.x+1
		updateRect.h = rect.y+1
		gw.clearscreen updateRect useBkg:true
		gw.enlargeUpdateRect updateRect 
		gw.updateScreen() 
		gw.resetUpdateRect()
	)
	gw.wtext textPos viewText color:(color 255 234 0)
	rect = gw.getTextExtent viewText 
	updateRect.w = rect.x+1
	updateRect.h = rect.y+1
	gw.enlargeUpdateRect updateRect
	gw.updateScreen() 
)

-- fnGetNodesVisibility()
fn fnGetNodesVisibility = (
	local sel = $*
	local ret = _objVis()
	
	for obj in sel do (
		append ret.nodes obj
		append ret.hidden obj.isHidden
	)
	
	return ret
)

-- fnSetNodesVisibility()
fn fnSetNodesVisibility data = (
	if data == undefined do return false
	for n = 1 to data.nodes.count do
		try (data.nodes[n].isHidden = data.hidden[n]) catch ()
)

-- fnGetNodeToViewpointDist()
fn fnGetNodeToViewpointDist obj = (
	local coordSysTM = Inverse(getViewTM()) 
	local dist = 0
	if obj != undefined do
		dist = distance obj.pos coordSysTM.row4
	return dist
)

-- fnFindNodeLods()
fn fnFindNodeLods obj lods:#() = (
	if obj != undefined do (
		-- append main node
		if lods[1] == undefined do
			lods = #(obj)
		-- find and append first child
		if obj.children.count > 0 do
			for c in obj.children do
				if (substring c.name 1 1) == ">" do (
					append lods c
					-- find next child
					lods = fnFindNodeLods c lods:lods
					exit
				)
	)
	return lods
)

-- fnFindMainNode()
fn fnFindMainNode obj = (
	if obj != undefined do
		if (substring obj.name 1 1) == ">" do
			obj = fnFindMainNode obj.parent
	return obj
)

-- fnGetLodDistances()
fn fnGetLodDistances obj = (
	local userProps = getUserPropBuffer obj
	local strArray = filterString userProps ("= ," + (bit.intAsChar 13) + (bit.intAsChar 10))
	local distances = #()
	local n = 0
	while (n += 1) <= strArray.count do (
		if strArray[n] == "Lod" do (
			if strArray[n+1] != undefined do
				append distances (strArray[n+1] as float)
			n += 1
		)
	)
	return distances
)

-- fnDoLod()
fn fnDoLod = (
	local sel = $* --selection
	local mainNodes = #()
	local mainNode, lods, distances, viewDist, whichLod, subStr
	
--	if sel.count == 0 and ($*).count > 1 do
--		sel = $*
	
	if sel.count > 0 do 
		for obj in sel do (
			-- hide destr and col nodes
			subStr = substring obj.name 1 1
			case subStr of (
				"&" : ( -- destr
					if not obj.isHidden do hide obj
					continue
				)
				"!" : ( -- unlinked col
					if not obj.isHidden do hide obj
					continue
				)
				"^" : ( -- linked col
					if not obj.isHidden do hide obj
					continue
				)
			)
			if (substring obj.name 1 5) == "strep" do ( -- linked col
				if not obj.isHidden do hide obj
				continue
			)
				
			-- find main node
			mainNode = fnFindMainNode obj
			if (findItem mainNodes mainNode) > 0 do continue
			
			-- get all LODs
			lods = fnFindNodeLods mainNode
			if lods[1] == undefined do exit

			-- get all distances
			distances = fnGetLodDistances mainNode
			if distances[1] == undefined do exit
			
			-- get distance from viewpoint to node
			viewDist = fnGetNodeToViewpointDist mainNode
			
			-- which lod will be shown
			whichLod = 0
			while (whichLod += 1) <= distances.count do
				if viewDist < distances[whichLod] do exit
			if whichLod > lods.count and distances[lods.count] == -1 do
				whichLod = lods.count
			if whichLod > distances.count and lods.count > distances.count do
				whichLod = 0
			
			-- show right lod
			for n = 1 to lods.count do
				if n == whichLod then
					unhide lods[n]
				else
					hide lods[n]

			-- append mainnode to array
			append mainNodes mainNode

--			format "%\t: %\t:\t%\t%\n" whichLod viewDist distances lods
		)
)

---------------------------------------------------------------
-- fnReplaceSelectionByObject
---------------------------------------------------------------
global isReplaceSelectionActive = false
fn fnReplaceSelectionByObject = (
	global doClone = #(0,true,true,true, 1, 2, 1, 1)
	local objSel = #()
	local newSel = #()
	local originalObj
	
	isReplaceSelectionActive = true
	updateToolbarButtons()

	-- exit if nothing selected
	if $ == undefined do (
		messageBox "No objects are selected." title:"Create clones"
		isReplaceSelectionActive = false
		updateToolbarButtons()
		return false
	)

	-- pick source node
	local originalObj = pickObject message:"Pick source object for clone." count:1 select:false forceListenerFocus:false
	if originalObj == undefined or originalObj == #escape do (
		isReplaceSelectionActive = false
		updateToolbarButtons()
		return false
	)

	-- collect selection
	local objSel = #()
	for s in selection do if s != originalObj do append objSel s
	
	isReplaceSelectionActive = false
	updateToolbarButtons()

	-- rollout definition
	rollout roCloneOptions "Clone Tool: Replace selection" width:328 height:216
	(
		local _iniSect = "ReplaceSelection"
		
		GroupBox	grp1		"Clone options" pos:[8,4] width:160 height:76
			radiobuttons	rdoCloneType	"" pos:[16,24] width:73 height:48 labels:#("Copy", "Instance", "Reference") columns:1
			checkbox		chkMove			"Move" pos:[104,24] width:56 height:16 checked:true
			checkbox		chkRotate		"Rotate" pos:[104,40] width:56 height:16 checked:true
			checkbox		chkScale		"Scale" pos:[104,56] width:56 height:16 checked:true
		GroupBox	grp2		"Clone attributes" pos:[8,88] width:160 height:120
			label			lbl3			"Name:" pos:[16,111] width:56 height:16
			dropdownList	ddlName			"" pos:[72,108] width:88 height:21 items:#("From Target", "From Source", "Generate New") selection:1
			label			lbl4			"Material:" pos:[16,135] width:56 height:16
			dropdownList	ddlMat			"" pos:[72,132] width:88 height:21 items:#("From Target", "From Source", "None") selection:2
			label			lbl5			"Wire color:" pos:[16,159] width:56 height:16
			dropdownList	ddlColor		"" pos:[72,156] width:88 height:21 items:#("From Target", "From Source", "Generate New") selection:1
			label			lbl6			"User def.:" pos:[16,181] width:56 height:16
			dropdownList	ddlUserDef		"" pos:[72,179] width:88 height:21 items:#("From Target", "From Source", "Erase") selection:1
		label		lbl1		"Note:" pos:[176,8] width:32 height:16
		label		lbl2		"Result of this operation will not be correct if you apply it to an object with pivot position different from the clone source or an object with reseted XForm." pos:[184,24] width:136 height:128
		button		btnOK		"OK" pos:[176,184] width:64 height:24
		button		BtnCancel	"Cancel" pos:[256,184] width:64 height:24

		on btnOK pressed do (
			doClone[1] = rdoCloneType.state
			doClone[2] = chkMove.checked
			doClone[3] = chkRotate.checked
			doClone[4] = chkScale.checked
			doClone[5] = ddlName.selection
			doClone[6] = ddlMat.selection
			doClone[7] = ddlColor.selection
			doClone[8] = ddlUserDef.selection
			destroyDialog roCloneOptions
		)
		on btnCancel pressed do (
			destroyDialog roCloneOptions
		)
		on roCloneOptions open do (
			local p = fnLoadINIexec "CloneType" (fnReturnFilename #ini) _iniSect
			if p != OK do rdoCloneType.state = p
			p = fnLoadINIexec "Move" (fnReturnFilename #ini) _iniSect
			if p != OK do chkMove.checked = p
			p = fnLoadINIexec "Rotate" (fnReturnFilename #ini) _iniSect
			if p != OK do chkRotate.checked = p
			p = fnLoadINIexec "Scale" (fnReturnFilename #ini) _iniSect
			if p != OK do chkScale.checked = p
			p = fnLoadINIexec "Name" (fnReturnFilename #ini) _iniSect
			if p != OK do ddlName.selection = p
			p = fnLoadINIexec "Material" (fnReturnFilename #ini) _iniSect
			if p != OK do ddlMat.selection = p
			p = fnLoadINIexec "Color" (fnReturnFilename #ini) _iniSect
			if p != OK do ddlColor.selection = p
			p = fnLoadINIexec "UserDefined" (fnReturnFilename #ini) _iniSect
			if p != OK do ddlUserDef.selection = p
			
			setfocus btnOK
		)
		on roCloneOptions close do (
			fnSaveINI "CloneType"	(rdoCloneType.state as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "Move"		(chkMove.checked as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "Rotate"		(chkRotate.checked as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "Scale"		(chkScale.checked as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "Name"		(ddlName.selection as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "Material"	(ddlMat.selection as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "Color"		(ddlColor.selection as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "UserDefined"	(ddlUserDef.selection as string) (fnReturnFilename #ini) _iniSect
		)
	)

	-- create options dialog	
	createDialog roCloneOptions modal:true
	
	-- do clone
	if doClone[1] > 0 do (
		while objSel.count > 0 do (
			local tmpObj = case doClone[1] of (
				1: copy originalObj
				2: instance originalObj
				3: reference originalObj
				default: (messageBox "A je to v pici!" title:"Clone Tool"; return false)
			)

			-- set parent
			if objSel[1].parent != undefined do (
				tmpObj.parent = objSel[1].parent
			)

			-- set position and rotation
			case of (
				(doClone[2] and doClone[3]) :			(
															tmpObj.transform = objSel[1].transform
														)
				(doClone[2] and not doClone[3]) :		(
															tmpObj.transform = originalObj.transform
															tmpObj.position = objSel[1].position
														)
				(not doClone[2] and doClone[3]) :		(
															tmpObj.transform = objSel[1].transform
															tmpObj.position = originalObj.position
														)
				(not doClone[2] and not doClone[3]) :	(
															tmpObj.transform = originalObj.transform
														)
			)
			
			-- set scale
			if doClone[4] then tmpObj.scale = objSel[1].scale
						  else tmpObj.scale = originalObj.scale

			-- set pivot
--			tmpObj.pivot	 = objSel[1].pivot

			-- set name
			case doClone[5] of (
				1: tmpObj.name = objSel[1].name
				2: tmpObj.name = uniqueName originalObj.name
				3: tmpObj.name = uniqueName "Clone"
			)
			-- set material
			case doClone[6] of (
				1: tmpObj.material = objSel[1].material
				2: tmpObj.material = originalObj.material
				3: tmpObj.material = undefined
			)
			-- set wire color
			case doClone[7] of (
				1: tmpObj.wirecolor = objSel[1].wirecolor
				2: tmpObj.wirecolor = originalObj.wirecolor
				3: tmpObj.wirecolor = random gray white
			)
			-- set user defined properties
			case doClone[8] of (
				1: setUserPropBuffer tmpObj (getUserPropBuffer objSel[1])
				2: setUserPropBuffer tmpObj (getUserPropBuffer originalObj)
				3: setUserPropBuffer tmpObj ""
			)
			
			-- set target
			if objSel[1].target != undefined do
				tmpObj.target = objSel[1].target
				
			-- set children
			if objSel[1].children.count > 0 do
				for c in objSel[1].children do append tmpObj.children c
				
			-- delete node from scene
			delete objSel[1]
			deleteitem objSel 1
			-- append new node to new selection
			append newSel tmpObj
		)

		doClone = undefined
		-- select new nodes
		select newSel
	)
)

---------------------------------------------------------------
-- fnSelectMaterialToReplace
---------------------------------------------------------------
fn fnSelectMaterialToReplace =
(
	rollout main "Replace pteroMaterial" width:304 height:304
	(
		local matList = #()
		-- init GUI
		multilistBox	lbxSelect "Select materials to be replaced:" pos:[8,8] width:288 height:17
		progressBar		pb1 "" pos:[8,256] width:288 height:8
		button			btnReplaceAll "Replace All" pos:[8,272] width:65 height:23
		button			btnReplace "Replace" pos:[152,272] width:65 height:23
		button			btnCancel "Cancel" pos:[231,272] width:65 height:23
		
		-- fnSortMat()
		fn fnSortMat m1 m2 = (
			local ret = 0
			m1 = fnDnCase m1.name
			m2 = fnDnCase m2.name
			case of (
				( m1 > m2 ): ret = 1
				( m1 < m2 ): ret = -1
			)
			return ret
		)
 
 		-- event handler
		on btnCancel pressed do destroyDialog main
		on btnReplace pressed do
		(
			for n = 1 to lbxSelect.selection.count do
			(
				pb1.value = (100 * (n / lbxSelect.selection.count))
				fnReplaceOneMaterial matList[(lbxSelect.selection as array)[n]]
			)
			destroyDialog main
		)
		on btnReplaceAll pressed do
		(
			for n = 1 to matList.count do
			(
				pb1.value = (100 * (n / matList.count))
				fnReplaceOneMaterial matList[n]
			)
			destroyDialog main
		)
		on main open do
		(
			local listBoxItems = #()
			for obj in $* do
			(
				if obj.material != undefined do
					if obj.material.classid[1] == 512 and obj.material.classid[2] == 0 then
						for sm = 1 to obj.material.count do
							if obj.material[sm] != undefined do
								if obj.material[sm].classid[1] == 0x654df3d2 and obj.material[sm].classid[2] == 0x64da69d9 do
									if (findItem matList obj.material[sm]) == 0 do
										append matList obj.material[sm]
					else if obj.material.classid[1] == 0x654df3d2 and obj.material.classid[2] == 0x64da69d9 do
								if (findItem matList obj.material) == 0 do
									append matList obj.material
			)
			
			qsort matList fnSortMat
			
			for m in matList do
				append listBoxItems m.name
			lbxSelect.items = listBoxItems
		)
	)
	
	createDialog main modal:true
)

---------------------------------------------------------------
-- fnDoRemoveFuckedMultimat
---------------------------------------------------------------
fn fnDoRemoveFuckedMultimat =
(
	
	rollout main "Replace Multimaterial in Multimaterial" width:272 height:296
	(
		local list = fnRemoveFuckedMultimat()

		listBox lbxResult "Result:" pos:[8,8] width:256 height:17
		button btnClose "Close" pos:[200,264] width:64 height:24
		
		on btnClose pressed do destroyDialog main
		on main open do if list.count > 2 then lbxResult.items = list else lbxResult.items = #("There is no problem in this scene.")
	)
	
	try (destroyDialog main) catch ()
	createDialog main --modal:true
)

---------------------------------------------------------------
-- Reset Xform and Export to BES file
---------------------------------------------------------------
struct _NodeFamily ( node, parent, children = #(), pos, rotation, scale, pivot )
-- fnGetNodeFamily
fn fnGetNodeFamily node =
(
	local family = _NodeFamily()
	local child
	
	family.node = node
	family.parent = node.parent
	family.pos = copy node.transform.position
	family.scale = copy node.transform.scale
	family.rotation = copy node.transform.rotation
	family.pivot = copy node.pivot
	
	if node.children.count != 0 do
	(
		for obj in node.children do
		(
			child = fnGetNodeFamily obj
			append family.children child
		)
	)
	
	return family
)
-- fnUnlinkNodes
fn fnUnlinkNodes family =
try (
	local node = family.node

	for child in family.children do
		fnUnlinkNodes child
	
	node.parent = undefined
	
	return true
)
catch (return false)

-- fnLinkNodes
fn fnLinkNodes family =
try (
	local node = family.node

	for child in family.children do
		fnLinkNodes child
	
	node.parent = family.parent
	
	return true
)
catch (return false)

-- fnDoResetXform
fn fnDoResetXform family = 
try (
	local node, r, mtx, mtx2

	-- process children
	for child in family.children do
		fnDoResetXform child

	-- set variables
	node = family.node

	-- don't reset xForm for
	-- dummy
	if classof node == Dummy then
		return true
	-- handle
	else if node.name[1] == "?" then
		return true
	-- doors
	else if (getUserProp node "Doors") != undefined then
		return true
	-- glass
	else if (getUserProp node "glass") != undefined then
		return true

	-- resetTransform node
	resetXForm node
	
	return true
)
catch (return false)

-- fnResetXform
fn fnResetXform =
(
	rollout rolloutResetXform "Reset Xform" width:224 height:48
	(
		progressBar pb1 "ProgressBar" pos:[8,8] width:208 height:8
		label lbl2 "" pos:[8,24] width:208 height:16
		on rolloutResetXform open do
		(
			local family
			local sel = #()
			local ParentNodes = #()
			local err = false
			
			with redraw off
			(
				-- create hierarchy
				for obj in geometry do
					if obj.parent == undefined do
						append sel obj
				while 1 <= sel.count do
				(
					family = (fnGetNodeFamily sel[1])
					append parentNodes family
					deleteItem sel 1
				)
				-- store selection
	/*			if selection.count > 0 do
				(		
					for s in selection do append sel s
					clearSelection()
				)
	*/			-- reset Xform
				undo "Reset Xform" on
				(
					for n = 1 to parentNodes.count do
					(
						family = parentNodes[n]
						-- print progress
						pb1.value = (n as float / parentNodes.count) * 100
						lbl2.text = family.node.name
						-- unlink nodes
						if (fnUnlinkNodes family) then
						(
							-- reset Xform
							if not (fnDoResetXform family) do err = true
						)
						else err = true
						-- Link nodes
						if not (fnLinkNodes family) do err = true
					)
				)
			)
						
			if err do
			(
				messageBox "Some error occurs when reset Xform runs.\nScene could be corrupted!\n\nI recommend to restart 3ds max." title:"Reset Xform"
			)
		)
	)
	createDialog rolloutResetXform --modal:true
	destroyDialog rolloutResetXform
)
-- ExportAdvanced rollout
rollout ExportAdvanced "Export to BES"  width:440 height:288
(
	-- locals
	local _iniSect = "ExportAdvanced"
	-- init GUI
	label lbl7 "Filename:" pos:[8,9] width:48 height:16
	edittext edtFilename "" pos:[56,8] width:344 height:16
	button btnBrowse "..." pos:[400,8] width:16 height:16
	button btnGenName "G" pos:[416,8] width:16 height:16 toolTip:"Generate filename"
	GroupBox grp3 "Parameters" pos:[8,32] width:192 height:88
	checkbox chkSelectedOnly "Export selected only" pos:[16,48] width:176 height:16
	checkbox chkResmooth "Resmooth single objects" pos:[16,64] width:176 height:16
	checkbox chkSmoothAll "Smooth whole scene together" pos:[16,80] width:176 height:16
	checkbox chkDistinguish "Distinguish LODs" pos:[16,96] width:176 height:16
	GroupBox grp2 "Options" pos:[8,128] width:192 height:88
	checkbox chkCheckFaces "Check nodes for bad faces" pos:[16,144] width:176 height:16
	checkbox chkCheckSave "Check scene for save" pos:[16,160] width:176 height:16
	checkbox chkResetXform "Reset Xform" pos:[16,176] width:176 height:16
	checkbox chkUndoXform "Undo reset Xform" pos:[40,192] width:152 height:16
	GroupBox grp4 "Info" pos:[208,32] width:224 height:184
	label lbl2 "User:" pos:[216,48] width:32 height:16
	edittext edtUser "" pos:[248,48] width:176 height:16
	label lbl3 "Note:" pos:[216,64] width:32 height:16
	edittext edtNote "" pos:[248,64] width:176 height:144
	button btnGen "Gen" pos:[216,192] width:26 height:16 toolTip:"Generate BES info"
	GroupBox grp1 "" pos:[8,224] width:192 height:56
	label lbl1 "Jelikoz vubec netusim, jestli to funguje dobre (snad by melo), tak si sceny radsi pred exportovanim ukladejte." pos:[14,234] width:183 height:42
	button btnOK "Export" pos:[264,256] width:78 height:24
	button BtnCancel "Cancel" pos:[352,256] width:78 height:24
	
	fn fnSaveOptions =
	(
		fileProperties.addProperty #custom "ExportFileName" edtFilename.text
		fileProperties.addProperty #custom "ResmoothSingleObjects" chkResmooth.checked
		fileProperties.addProperty #custom "SmoothWholeSceneTogether" chkSmoothAll.checked
		fileProperties.addProperty #custom "DistinguishLODs" chkDistinguish.checked
		fileProperties.addProperty #custom "Note" edtNote.text
		fnSaveINI "ExportSelected" (chkSelectedOnly.checked as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "CheckFaces" (chkCheckFaces.checked as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "CheckSave" (chkCheckSave.checked as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "ResetXform" (chkResetXform.checked as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "UndoXform" (chkUndoXform.checked as string) (fnReturnFilename #ini) _iniSect
	)
	fn fnGenerateFileName =
	(
		local tmp = getFileNamePath edtFilename.text
		if tmp == "\\" or tmp == "" do --or (getDirectories ((getFileNamePath edtFilename.text) + "*.*")).count == 0 do
		(
			tmp = maxFilePath
			if tmp == "" or tmp == "\\" do
			(
				tmp = (fnLoadINI "ModelsPath" (fnReturnFilename #ini) "General")
				if tmp == "" or tmp == "\\" do
				(
					tmp = (fnLoadINI "ScenesPath" (fnReturnFilename #ini) "General")
					if tmp == "" or tmp == "\\" do tmp = getDir #export
				)
			)
		)
		if tmp[tmp.count] != "\\" do tmp += "\\"
		if maxFileName == "" then
			tmp += "untitled.bes"
		else
			tmp += (getFilenameFile maxFileName) + ".bes"
		return tmp
	)
	on btnBrowse pressed do
	(
		local tmp = getSaveFileName filename:edtFilename.text caption:"Export to BES as" types:"pteroEngine (*.BES)|*.bes"
		if tmp != undefined do edtFilename.text = tmp
	)
	on chkResetXform changed state do
	(
		chkUndoXform.enabled = state
	)
	on btnGenName pressed do
	(
		edtFilename.text = fnGenerateFileName()
	)
	on btnOK pressed do
	(
		local tmp
		-- close dialog
		fnSaveOptions()
		destroyDialog ExportAdvanced
		-- check folder exists
/*		tmp = getDirectories ((getFileNamePath edtFilename.text) + "*.*")
		print tmp
		if tmp.count == 0 do
		(
			messageBox ("Folder '" + (getFileNamePath edtFilename.text) + "' doesn't exit.") title:"Export to BES"
			return false
		)
*//*			if (queryBox ("Folder " + (getFileNamePath edtFilename.text) + " doesn't exit.\nCan you create it?") title:"Folder doesn't exit.") then
				makeDir (getFileNamePath edtFilename.text)
			else
				return true
*/		-- check selection
		if chkSelectedOnly.checked and selection.count == 0 do
		(
			messageBox "No objects are selected." title:"Export to BES"
			return false
		)
		-- check for spiked faces
		if chkCheckFaces.checked do
		(
			findSelectedSpiked = if chkSelectedOnly.checked then 1 else 0
			fnFindSpikeFaces()
			if findSelectedSpiked > 0 do
			(	-- there is a problem with face(s)
				destroyDialog ExportAdvanced
				return 0
			)
		)
		-- switch to create panle to prevent from flashing
		max create mode
		-- check scene for save
		if chkCheckSave.checked do
			if not checkForSave() do return false
		-- reset Xform
		if chkResetXform.checked do fnResetXform()
		-- clear screen
		redrawViews()
		-- export to BES
		try (
			exportFile edtFilename.text #noPrompt selectedOnly:chkSelectedOnly.checked
		) catch (
			messageBox "Tak - a je to v pici, export se nepovedl!!!\n\nTed uz bude Max urcite nestabilni,\ntakze si radsi uloz a zavri ho." title:"Export to BES"
		)
		-- undo reset Xform
		if chkResetXform.checked and chkUndoXform.checked do max undo
	)
	on btnCancel pressed do
	(
		destroyDialog ExportAdvanced
	)
	on btnGen pressed do
	(
		edtNote.text = fnCreateBesInfo()
	)
	on ExportAdvanced open do
	(
		local str = ""
		
		setfocus btnOK
		
		-- get export filename
		tmp = fileProperties.findProperty #custom "ExportFileName"
		if tmp == 0 then
			edtFilename.text = fnGenerateFileName()
		else
			edtFilename.text = fileProperties.getPropertyValue #custom tmp
		-- get check boxes
		tmp = fileProperties.findProperty #custom "ResmoothSingleObjects"
		if tmp != 0 then chkResmooth.checked = fileProperties.getPropertyValue #custom tmp
		tmp = fileProperties.findProperty #custom "SmoothWholeSceneTogether"
		if tmp != 0 then chkSmoothAll.checked = fileProperties.getPropertyValue #custom tmp
		tmp = fileProperties.findProperty #custom "DistinguishLODs"
		if tmp != 0 then chkDistinguish.checked = fileProperties.getPropertyValue #custom tmp
		tmp = fnLoadINIexec "CheckFaces" (fnReturnFilename #ini) _iniSect
		chkCheckFaces.checked = if tmp != OK then tmp else true
		tmp = fnLoadINIexec "CheckSave" (fnReturnFilename #ini) _iniSect
		chkCheckSave.checked = if tmp != OK then tmp else true
		if (maxVersion())[1] >= 6000 then
		(
			tmp = fnLoadINIexec "ResetXform" (fnReturnFilename #ini) _iniSect
			chkResetXform.checked = if tmp != OK then tmp else true
			tmp = fnLoadINIexec "UndoXform" (fnReturnFilename #ini) _iniSect
			chkUndoXform.checked = if tmp != OK then tmp else true
			chkUndoXform.enabled = chkResetXform.checked
		)
		else
		(
			chkResetXform.enabled = false
			chkUndoXform.enabled = false
		)
		-- get note and user name string
		tmp = fileProperties.findProperty #custom "Note"
		if tmp != 0 then
		(
			tmp = fileProperties.getPropertyValue #custom tmp
			for n = 1 to tmp.count do
				if (bit.charAsInt tmp[n]) != 13 then
					if (bit.charAsInt tmp[n]) == 10 then
						str += (bit.IntAsChar 13) + tmp[n]
					else
						str += tmp[n]
			edtNote.text = str
		)
		edtUser.text = sysinfo.computerName + "\\" + sysinfo.userName
		edtUser.enabled = false
	)
)

---------------------------------------------------------------
-- Hierarchy Clipboard
---------------------------------------------------------------
struct _HierarchyClipboard ( name = "", nodes = #() )
struct _HierarchyClipboardNode ( node, parent )
global isHierarchyClipboardActive = false
global HierarchyClipboardTable = #()
fn fnHierarchyClipboard =
(
	local _iniSect = "HierarchyClipboard"
	rollout roHierarchyClipboard "Hierarchy clipboard" width:288 height:64
	(
		local _iniSect = "HierarchyClipboard"
		local emptyPic = bitmap 8 17 color:(color 0 0 0)
		local usedPic = bitmap 8 17 color:(color 0 255 0)

		-- init gui
		bitmap bmpInfo1 "Bitmap" pos:[8,8] width:8 height:17 toolTip:"Status"
		edittext edtName1 "" pos:[16,8] width:128 height:16
		label lblCount1 "" pos:[152,9] width:40 height:16
		button btnSave1 "C" pos:[200,8] width:16 height:16 toolTip:"Store nodes hierarchy" images:(fnReturnFilename #savIcon)
		button btnLoad1 "P" pos:[216,8] width:16 height:16 toolTip:"Restore nodes hierarchy" images:(fnReturnFilename #setIcon)
		button btnSelect1 "S" pos:[240,8] width:16 height:16 toolTip:"Select nodes in slot" images:(fnReturnFilename #plFind)
		button btnClear1 "E" pos:[264,8] width:16 height:16 toolTip:"Empty slot" images:(fnReturnFilename #delIcon)
			
		bitmap bmpInfo2 "Bitmap" pos:[8,24] width:8 height:17 toolTip:"Status"
		edittext edtName2 "" pos:[16,24] width:128 height:16
		label lblCount2 "" pos:[152,26] width:40 height:16
		button btnSave2 "C" pos:[200,24] width:16 height:16 toolTip:"Store nodes hierarchy" images:(fnReturnFilename #savIcon)
		button btnLoad2 "P" pos:[216,24] width:16 height:16 toolTip:"Restore nodes hierarchy" images:(fnReturnFilename #setIcon)
		button btnSelect2 "S" pos:[240,24] width:16 height:16 toolTip:"Select nodes in slot" images:(fnReturnFilename #plFind)
		button btnClear2 "E" pos:[264,24] width:16 height:16 toolTip:"Empty slot" images:(fnReturnFilename #delIcon)
			
		bitmap bmpInfo3 "Bitmap" pos:[8,40] width:8 height:17 toolTip:"Status"
		edittext edtName3 "" pos:[16,40] width:128 height:16
		label lblCount3 "" pos:[152,42] width:40 height:16
		button btnSave3 "C" pos:[200,40] width:16 height:16 toolTip:"Store nodes hierarchy" images:(fnReturnFilename #savIcon)
		button btnLoad3 "P" pos:[216,40] width:16 height:16 toolTip:"Restore nodes hierarchy" images:(fnReturnFilename #setIcon)
		button btnSelect3 "S" pos:[240,40] width:16 height:16 toolTip:"Select nodes in slot" images:(fnReturnFilename #plFind)
		button btnclear3 "E" pos:[264,40] width:16 height:16 toolTip:"Empty slot" images:(fnReturnFilename #delIcon)
		
		-- fnUpdateUI
		fn fnUpdateUI n = 
		(
			local UIitems = #("bmpInfo", "edtName", "lblCount", "btnSelect", "btnSave", "btnLoad", "btnClear")
			for item in UIitems do
			(
				local itemName = item + n as string
				local itemIDX = fnFindControl roHierarchyClipboard.controls itemName
				local control = roHierarchyClipboard.controls[itemIDX]
				case item of
				(
					"bmpInfo" :
					(
						if HierarchyClipboardTable[n] == undefined then
							control.bitmap = emptyPic
						else
							control.bitmap = usedPic
					)
					"edtName" :
					(
						if HierarchyClipboardTable[n] == undefined then
						(
							control.text = ""
							control.enabled = false
						) else
						(
							control.text = HierarchyClipboardTable[n].name
							control.enabled = true
						)
					)
					"lblCount" :
					(
						if HierarchyClipboardTable[n] == undefined then
							control.text = "Empty"
						else
							control.text = "N: " + HierarchyClipboardTable[n].nodes.count as string
					)
					"btnSelect" :
					(
						if HierarchyClipboardTable[n] == undefined then
							control.enabled = false
						else
							control.enabled = true
					)
					"btnSave" :
					(
					)
					"btnLoad" :
					(
						if HierarchyClipboardTable[n] == undefined then
							control.enabled = false
						else
							control.enabled = true
					)
					"btnClear" :
					(
						if HierarchyClipboardTable[n] == undefined then
							control.enabled = false
						else
							control.enabled = true
					)
				)
			)
		)
		-- fnSaveHierarchy
		fn fnSaveHierarchy n =
		(
			if selection.count > 0 do
			(
				HierarchyClipboardTable[n] = _HierarchyClipboard "" #()
				for s in selection do
				(
					append HierarchyClipboardTable[n].nodes (_HierarchyClipboardNode s s.parent)
				)
				fnUpdateUI n
			)
		)
		-- fnLoadHierarchy
		fn fnLoadHierarchy n =
		(
			for s in HierarchyClipboardTable[n].nodes do
			(
				if (isDeleted s.node) do continue
				if s.parent == undefined then
					s.node.parent = undefined
				else
					s.node.parent = if (isDeleted s.parent) then undefined else s.parent
			)
		)
		-- fnSelectNodes
		fn fnSelectNodes n =
		(
			local sel = #()
			for s in HierarchyClipboardTable[n].nodes do
			(
				if (isDeleted s.node) do continue
				append sel s.node
			)			
			select sel
		)
		-- fnClearHierarchy
		fn fnClearHierarchy n =
		(
			HierarchyClipboardTable[n] = undefined
			fnUpdateUI n
		)
		-- event handles		
		on edtName1		entered str do HierarchyClipboardTable[1].name = str
		on btnSave1		pressed do fnSaveHierarchy 1
		on btnLoad1		pressed do fnLoadHierarchy 1
		on btnSelect1	pressed do fnSelectNodes 1
		on btnClear1	pressed do fnClearHierarchy 1
		on edtName2		entered str do HierarchyClipboardTable[2].name = str
		on btnSave2		pressed do fnSaveHierarchy 2
		on btnLoad2		pressed do fnLoadHierarchy 2
		on btnSelect2	pressed do fnSelectNodes 2
		on btnClear2	pressed do fnClearHierarchy 2
		on edtName3		entered str do HierarchyClipboardTable[3].name = str
		on btnSave3		pressed do fnSaveHierarchy 3
		on btnLoad3		pressed do fnLoadHierarchy 3
		on btnSelect3	pressed do fnSelectNodes 3
		on btnClear3	pressed do fnClearHierarchy 3
		on roHierarchyClipboard open do
		(
			for n = 1 to 3 do fnUpdateUI n
		)
		on roHierarchyClipboard close do
		(
			fnSaveINI "DialogPosition" ( ( getDialogpos roHierarchyClipboard ) as string ) (fnReturnFilename #ini) _iniSect
			isHierarchyClipboardActive = false
			updateToolbarButtons()
		)
	)
	if not isHierarchyClipboardActive then
	(
		if ( p = fnLoadINIexec "DialogPosition" (fnReturnFilename #ini) _iniSect ) == OK do p = [50,50]
		createDialog roHierarchyClipboard style:#(#style_toolwindow, #style_sysmenu) pos:p
		isHierarchyClipboardActive = true
	) else
	(
		destroyDialog roHierarchyClipboard
		isHierarchyClipboardActive = false
	)
)

---------------------------------------------------------------
-- OptimizeMultimaterialsDialog
---------------------------------------------------------------
-- OptimizeMultimaterialsDialog
rollout OptimizeMultimaterialsDialog "Optimize Multimaterials" width:240 height:280
(
	local _iniSect = "OptimizeMultimaterials"
	local optimizeIsDone = false
	local oldSel = selection as array
	local sel = selection as array

	-- init gui
	groupBox grp7 "Proceed" pos:[8,8] width:224 height:56
	button btnAbout "?" pos:[208,23] width:16 height:16 tooltip:"About ..."
	radioButtons rdoProceed "" pos:[16,25] width:89 height:32 labels:#("Whole scene", "Selection only:") columns:1
	label lbl3 "0 nodes" pos:[112,41] width:88 height:16 		button btnSelect "..." pos:[208,40] width:16 height:16 toolTip:"Select by name dialog ..."
	GroupBox grp2 "Wrong sub-material indexing options" pos:[8,72] width:224 height:88
	radiobuttons rdoWrongID "" pos:[16,88] width:155 height:48 labels:#("Do nothing", "Select faces", "Select and reindex faces to:") columns:1
	spinner spnNewID "" pos:[176,119] width:48 height:16 range:[0,1000,1000] type:#integer
	checkbox chkSelectNodes "Select nodes" pos:[32,138] width:96 height:16
	GroupBox grp1 "Progress" pos:[8,168] width:224 height:72
	label lbl1 "Note: This tool will convert all geometry" pos:[16,184] width:208 height:16
	label lbl2 "          nodes to Editable Mesh." pos:[16,200] width:208 height:16
	progressBar pb1 "" pos:[16,216] width:208 height:8
	progressBar pb2 "" pos:[16,224] width:208 height:8
	button btnCancel "Cancel" pos:[168,248] width:64 height:24
	button btnProceed "Optimize" pos:[96,248] width:64 height:24

	-- fnCheckSelection
	fn fnCheckSelection sel =
	(
		local ret = #()
		for node in sel do
			if (superClassOf node) == GeometryClass do
			(
				convertToMesh node
				append ret node
			)
		return ret
	)
	
	-- fnGetMaxID
	fn fnGetMaxID mat =
	(
		local ret = 0
		for n in mat.materialIDList do
			if ret < n do ret = n
		return ret
	)
	
	-- fnFindMaterial
	fn fnFindMaterial multi mat =
	(
		ret = 0
		for m = 1 to multi.numSubs do
			if multi.materialList[m] == mat then
			(
				ret = m
				exit
			) else if (fnCompareMaterials multi.materialList[m] mat) do
			(
				ret = m
				exit
			)
		return ret
	)

	-- fnDoOptimizeMultimats
	fn fnDoOptimizeMultimats sel =
	(
		local matTable = #()
		local nmMat = standardmaterial()
		local nmc = 1
		
		assignNewName nmMat
		nmMat = multimaterial name:nmMat.name
		
		lbl1.text = "Creating material table:"
	
		-- create material table
		for n = 1 to sel.count do
		(
			local node = sel[n]
			
			pb2.value = (n as float / sel.count) * 100

			if node.material != undefined do
			(
				local bTemp = true
				for mat in matTable do
					if mat == node.material do
					(
						bTemp = false
						exit
					)
				if bTemp and (classOf node.material) == Multimaterial do
					append matTable node.material
			)
		)
		
		lbl1.text = "Optimizing " + (matTable.count as string) + " Multimaterials:"

		-- create new material
		for n = 1 to matTable.count do
		(
			local mMat = matTable[n]
			
			lbl2.text = mMat.name + " : " + (mMat.numSubs as string) + " sub-mats"
			pb1.value = (n as float / matTable.count) * 100
			
			for k = 1 to mMat.numSubs do
			(
				local id = mMat.materialIDList[k]

				pb2.value = (k as float / mMat.numSubs) * 100
				
				if id != undefined do if id > 0 then
				(
					if (fnFindMaterial nmMat mMat.materialList[k]) == 0 do
					(
						local bTemp = false
						for node in sel do if mMat == node.material do
							for f = 1 to node.numFaces do if (getFaceMatID node.mesh f) == id do
							(
								bTemp = true
								exit
							)
						if bTemp do
						(
							nmMat.numSubs = nmc
							nmMat.materialList[nmc] = mMat.materialList[k]
							nmMat.materialIDList[nmc] = nmc
							nmc += 1
						)
					)
				)
				else
				(
	--				format "%\t---------------\n" k
				)
			)
		)
		
		return nmMat
	)

	-- fnReindexNodeMatID
	fn fnReindexNodeMatID node nmMat =
	(	
		local nMesh
		local oldIDs = #()
		local newIDs = #()
		local wrongMatIDs = #()
		local wrongFaceIDs = #()
		local ret = #()
		local allFaceIDs = #()
		
		nMesh = copy node.mesh
		
		-- compare materials
		if node.material.numSubs == nmMat.numSubs do
		(
			local nmMax = fnGetMaxID nmMat
			local ndMax = fnGetMaxID node.material
			if nmMax == ndMax do
			(
				local bTemp = true
				for n = 1 to nmMax do
					 if node.material.materialIDList[n] != nmMat.materialIDList[n] then
					(
						bTemp = false
						exit
					)
					else if not (fnCompareMaterials node.material.materialList[n] nmMat.materialList[n]) do
					(
						bTemp = false
						exit
					)
				if bTemp do return ret
			)
		)
	
		-- create tables of IDs
		for n = 1 to node.material.numSubs do
		(
			local id = node.material.materialIDList[n]
			local nID = fnFindMaterial nmMat node.material.materialList[n]

			if id != undefined do if nID > 0 do
			(
				append oldIDs id
				append newIDs nID
			)			
		)
		
		if nmMat.numSubs == 1 then
		(
			node.material = nmMat.materialList[1]
		)
		else
		(
			-- reindex faces ID
			for f = 1 to nMesh.numFaces do
			(
				local faceMatID = getFaceMatID nMesh f
				
				pb2.value = (f as float / nMesh.numFaces) * 100
				
				idx = findItem oldIDs faceMatID
				
				if (findItem allFaceIDs faceMatID) == 0 do append allFaceIDs faceMatID
				
				if idx > 0 then
				(
					if faceMatID != newIDs[idx] do
						setFaceMatID nMesh f newIDs[idx]
				)
				else
				(
					append wrongFaceIDs f
					append wrongMatIDs faceMatID
				)
			)
		
			if wrongFaceIDs.count > 0 do
				ret = #(node, wrongFaceIDs as bitArray, wrongMatIDs as bitArray)
			
			node.mesh = nMesh
			
			if allFaceIDs.count == 1 then
				node.material = node.material.materialList[(findItem oldIDs allFaceIDs[1])]
			else
				node.material = nmMat
		)
		
		return ret
	)
	-- fnGeometryFilter
	fn fnGeometryFilter node = if (superClassOf node) == GeometryClass then true else false
	
	-- fnProceed
	fn fnProceed =
	(
		local Errors = #()
		local nmMat
		
		if rdoProceed.state == 1 do
			sel = geometry
		if sel.count == 0 do
		(
			messageBox "No objects are selected." title:"Optimize Multimaterial"
			return false
		)
		
		sel = fnCheckSelection sel

		pb1.visible = true
		pb2.visible = true

		-- do optimize materials
		nmMat = fnDoOptimizeMultimats sel

		lbl1.text = "Reindexing faces in " + (sel.count as string) + " nodes:"
		
		undo "Optimize Multimaterial" on
		(
			-- do reindex faces
			for n = 1 to sel.count do
			(
				local node = sel[n]
				local tmp = #()
				
				pb1.value = (n as float / sel.count) * 100
				lbl2.text = node.name + " : " + (node.numFaces as string) + " faces"

				if (classOf node.material) == Multimaterial do
					tmp = fnReindexNodeMatID node nmMat
				if tmp.count > 0 do append Errors tmp
			)
			
			-- do selections
			if rdoWrongID.state > 1 then
			(
				if chkSelectNodes.checked and Errors.count > 0 do clearNodeSelection()
				for n in Errors do
				(
					setFaceSelection n[1] n[2]
					if rdoWrongID.state == 3 do
						for k in n[2] do
							setFaceMatID n[1].mesh k spnNewID.value
					if chkSelectNodes.checked do selectMore n[1]
				)
			)
		)
		fnSaveINI "WhatProceed" (rdoProceed.state as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "WrongID" (rdoWrongID.state as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "NewID" (spnNewID.value as string) (fnReturnFilename #ini) _iniSect
		fnSaveINI "SelectNodes" (chkSelectNodes.checked as string) (fnReturnFilename #ini) _iniSect

		destroyDialog OptimizeMultimaterialsDialog
	)
	
	-- event handles
	on btnProceed	pressed do fnProceed()
	on btnAbout		pressed	do (PteroToolsTemp = #("Optimize Multimaterials", 1.0); fnAboutDialog())
	on rdoProceed	changed state do lbl3.enabled = if state == 1 then false else true
	on rdoWrongID	changed state do chkSelectNodes.enabled = if state == 1 then false else true
	on btnCancel	pressed do destroyDialog OptimizeMultimaterialsDialog
	on spnNewID		entered do 
	(
		rdoWrongID.state = 3
		chkSelectNodes.enabled = true
	)
	on btnSelect pressed do
	(
		local newSel = selectByName title:"Select objects" filter:fnGeometryFilter showHidden:true single:false
		if newSel != undefined do
			if newSel.count > 0 do
			(
				sel = newSel
				rdoProceed.state = 2
				lbl3.enabled = if rdoProceed.state == 1 then false else true
				lbl3.text = (newSel.count as string) + " nodes"
			)
	)
	on OptimizeMultimaterialsDialog open do
	(
		tmp = fnLoadINIexec "WhatProceed" (fnReturnFilename #ini) _iniSect
		if tmp != OK do rdoProceed.state = tmp
		tmp = fnLoadINIexec "WrongID" (fnReturnFilename #ini) _iniSect
		if tmp != OK do rdoWrongID.state = tmp
		tmp = fnLoadINIexec "NewID" (fnReturnFilename #ini) _iniSect
		if tmp != OK do spnNewID.value = tmp
		tmp = fnLoadINIexec "SelectNodes" (fnReturnFilename #ini) _iniSect
		if tmp != OK do chkSelectNodes.checked = tmp
		
		chkSelectNodes.enabled = if rdoWrongID.state == 1 then false else true
		lbl3.enabled = if rdoProceed.state == 1 then false else true
		lbl3.text = (oldSel.count as string) + " nodes"
		pb1.visible = false
		pb2.visible = false
	)
)

---------------------------------------------------------------
-- fnFindPteroMatWithoutCollisions
---------------------------------------------------------------
struct _noColMatList (material = #(), name = #(), models = #(), multimats = #())
fn fnFindPteroMatWithoutCollisions =
(
	rollout noColMatDialog "PteroMaterials without collisions" width:536 height:264
	(
		local list

		GroupBox grp2 "Result" pos:[8,8] width:256 height:248
		listbox lbxResult "" pos:[16,24] width:240 height:17
		GroupBox grp1 "" pos:[272,8] width:256 height:176
		button btnAbout "?" pos:[504,24] width:16 height:16
		listbox lbxMMats "Used in Multimaterials:" pos:[280,22] width:168 height:4
		button btnAddToSlot ">>" pos:[456,72] width:64 height:24 toolTip:"Add selected multimaterial to active material slot"
		listbox lbxModels "Used on models:" pos:[280,102] width:168 height:4
		button btnSelect "Select" pos:[456,120] width:64 height:24 toolTip:"Select current node"
		button btnSelectAll "Select All" pos:[456,152] width:64 height:24 toolTip:"Select all nodes in list"
		label lbl2 "Note:" pos:[272,192] width:32 height:32
		label lbl1 "Adding selected material to active material slot will overwrite actual material in this slot!" pos:[304,192] width:224 height:32
		button btnAdd "Add material to active slot" pos:[272,232] width:136 height:24
		button btnSearch "Search" pos:[464,232] width:64 height:24
/*
		listbox lbxResult "Result:" pos:[8,8] width:256 height:17
		GroupBox grp1 "" pos:[8,256] width:256 height:176
		button btnAbout "?" pos:[240,272] width:16 height:16
		listbox lbxMMats "Used in Multimaterials:" pos:[16,270] width:168 height:4
		button btnAddToSlot ">>" pos:[192,320] width:64 height:24 toolTip:"Add selected multimaterial to active material slot"
		listbox lbxModels "Used on models:" pos:[16,350] width:168 height:4
		button btnSelect "Select" pos:[192,368] width:64 height:24 toolTip:"Select current node"
		button btnSelectAll "Select All" pos:[192,400] width:64 height:24 toolTip:"Select all nodes in list"
		label lbl2 "Note:" pos:[8,440] width:32 height:32
		label lbl1 "Adding selected material to active material slot will overwrite actual material in this slot!" pos:[40,440] width:224 height:32
		button btnAdd "Add material to active slot" pos:[8,480] width:136 height:24
		button btnSearch "Search" pos:[200,480] width:64 height:24
*/		
		fn fnUpdateUI =
		(
			local tmp
			
			if list.multimats[1] != undefined and list.multimats[lbxResult.selection][1] != "" then
			(	-- append multimats to listbox
				tmp = #()
				for m in list.multimats[lbxResult.selection] do append tmp m.name
				lbxMMats.items = tmp
				btnAddToSlot.enabled = true
			)
			else
			(	-- remove multimats from list
				lbxMMats.items = #()
				btnAddToSlot.enabled = false
			)
			if list.models[1] != undefined and list.models[lbxResult.selection][1] != "" then
			(	-- append nodes to listbox
				tmp = #()
				for m in list.models[lbxResult.selection] do append tmp m.name
				lbxModels.items = tmp
				btnSelect.enabled = true
				btnSelectAll.enabled = true
			)
			else
			(	-- remove nodes from list
				lbxModels.items = #()
				btnSelect.enabled = false
				btnSelectAll.enabled = false
			)
		)
		
		fn fnUpdateList =
		(
			list = fnFindNoCollisionMaterial sceneMaterials (_noColMatList())
			
			if list.name.count > 0 then
			(	-- append materials to list
				lbxResult.items = list.name
				btnAdd.enabled = true
			)
			else
			(	-- remove materials from list
				lbxResult.items = #("There is no problem in this scene.")
				btnAdd.enabled = false
			)
			fnUpdateUI()
		)
		
		fn fnAddMatToSlot mat =
		(	-- add material to active mEdit slot
			max mtledit
			meditMaterials[activemeditSlot] = mat
			medit.updateMtlEditorBrackets()
		)
		
		on btnAdd			pressed do fnAddMatToSlot list.material[lbxResult.selection]
		on btnAddToSlot		pressed do fnAddMatToSlot list.multimats[lbxResult.selection][lbxMMats.selection]
		on btnSelect		pressed do select list.models[lbxResult.selection][lbxModels.selection]
		on btnSelectAll		pressed do select list.models[lbxResult.selection]
		on btnSearch		pressed do fnUpdateList()
		on btnAbout			pressed	do (PteroToolsTemp = #("PteroMats without collisions", 1.0); fnAboutDialog())
		on lbxResult		selected val do fnUpdateUI()
		on noColMatDialog	open do fnUpdateList()
	)
	

	try (destroyDialog noColMatDialog) catch ()
	createDialog noColMatDialog --modal:true
)

---------------------------------------------------------------
-- fnFindPteroMatWithoutCollisions
---------------------------------------------------------------
fn fnShowBitmapInViewport mat tex_id = 
(
	local texCh, workMap

	if (texCh = fnReturnTexChannel n:tex_id) == undefined do ( if _DEBUG_ do format "Error: fnShowBitmapInViewport() - tex_id:%\n" tex_id; return false )

	if mat.isShowing[tex_id].x != 1 and mat.maps[texCh] != undefined and mat.mapIsUsed[texCh] != false do
	(
		workMap	= mat.maps[texCh]

		for i = 1 to 24 do mat.isShowing[i] = [0,0,0]
		mat.isShowing[tex_id] = [1,0,0]

		mat.delegate.diffuseMap	= copy workMap

		mat.delegate.diffuseMap.RGBoutput				= 0
		mat.delegate.diffuseMap.coordinates.mapping		= 0
		mat.delegate.diffuseMap.coordinates.u_tiling	= mat.delegate.diffuseMap.coordinates.v_tiling = if n != 2 then 1 else PRM_DIFF2_TILE
		mat.delegate.diffuseMap.coordinates.mappingType	= if n == 5 then 1 else 0
		mat.showInViewport = true

		return true
	)
)

fn fnEnableBitmapsInViewport =
(
	rollout dialogEnableBitmapsInViewport "Show bitmaps in viewport" width:312 height:136
	(
		local sel

		label lbl1 "Selected:" pos:[8,8] width:56 height:16
		label lblSelected "Label" pos:[64,8] width:96 height:16
		groupBox grp1 "Show" pos:[8,24] width:152 height:104
		radiobuttons rdoShow "" pos:[16,44] width:135 height:80 labels:#("Diffuse #1 - Ground", "Diffuse #2 - Multitexture", "Diffuse #3 - Overlay", "LightMap", "Environment") columns:1
		button		btnAbout "?" pos:[288,8] width:16 height:16
		label lbl16 "Note:" pos:[168,30] width:32 height:16
		label lbl17 "This tool works with pteroMaterial ONLY!" pos:[200,30] width:104 height:88
		button btnApply "Apply" pos:[168,104] width:64 height:24
		button BtnCancel "Cancel" pos:[240,104] width:64 height:24
		
		fn fnApply =
		(
			local tex_id = rdoShow.state
		
			-- exit if nothing selected
			if sel.count == 0 do
			(
				destroyDialog dialogEnableBitmapsInViewport
				return true
			)

			for obj in sel do
			(
				if obj.material == undefined then
				(
					continue
				)
				else if (classof obj.material) == pteroMaterial then
				(
					fnShowBitmapInViewport obj.material tex_id
				)
				else if (classof obj.material) == Multimaterial then
				(
					for mat in obj.material.materialList do
					(
						if (classof mat) == pteroMaterial then
						(
							fnShowBitmapInViewport mat tex_id
						)
					)
				)
			)
			
			-- update material in medit
			medit.setActiveMtlSlot (medit.getActiveMtlSlot()) true
		)
		
		-- event handles
		on btnAbout pressed do (PteroToolsTemp = #("Show bitmaps in viewports", 1.0); fnAboutDialog())
		on btnApply pressed do 
		(
			fnApply()
			destroyDialog dialogEnableBitmapsInViewport
		)
		on btnCancel pressed do 
		(
			destroyDialog dialogEnableBitmapsInViewport
		)
		on dialogEnableBitmapsInViewport open do
		(
			sel = selection
			if sel.count == 0 do sel = geometry
		
			if sel.count == 0 then
			(
				lblSelected.text = "NOTHING"
				btnApply.enabled = rdoShow.enabled = false
			)
			else
			(
				if sel.count == geometry.count then 
					lblSelected.text = "WHOLE SCENE"
				else
					lblSelected.text = sel.count as string + " NODE(s)"
			)
		)
	)
	
	createDialog dialogEnableBitmapsInViewport modal:true
)

-- EOF
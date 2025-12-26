---------------------------------------------------------------
--
-- pteroSectorChecker
--
-- by Pan Collette
--
-- Create:		16.12.2003
-- Modified:	17.12.2004
--
---------------------------------------------------------------

-- check sector structs
struct _sectorList ( sector, portals = #(), errors = #() )
struct _portalList ( portal, doublers = #(), sector, errors = #() )
-- globals
global checkSectorsDialogActive

-- fnFindPortal()
fn fnFindPortal portalList source =
(
	for p in portalList do
		if p.portal == source do
			return p

	return undefined
)
-- fnFindSector()
fn fnFindSector sectorList source =
(
	for s in sectorList do
		if s.sector == source do
			return s

	return undefined
)

-- fnCheckSectorProps()
fn fnCheckSectorProps node =
(
	local buffer = getUserPropBuffer node
	local ret = #(#none, #())
	
	if (findString buffer "Sector") != undefined then
	(
		ret[1] = #Sector
		if node.parent != undefined then
		(
			local tmp = fnCheckSectorProps node.parent
			if tmp[1] == #Portal then
			(	-- wrong parent
				append ret[2] #wrongParent
			)
			else if tmp[1] == #Sector and node.children.count > 0 then
			(	-- wrongParent
				append ret[2] #wrongParent
			)
			else if tmp[1] == #Sector and node.children.count == 0 then
			(	-- propably is portal
				ret[1] = #Portal
				append ret[2] #wrongProps
			)
		)
	)
	else if (findString buffer "Portal") != undefined then
	(
		ret[1] = #Portal
		if node.parent == undefined then
		(	-- no Parent
			append ret[2] #noParent
		)
		else
		(
			local tmp = fnCheckSectorProps node.parent
			if tmp[1] != #Sector then
			(	-- wrongParent
				append ret[2] #wrongParent
			)
		)
		if node.children.count > 0 do
		(	-- wrongChild
			append ret[2] #wrongChild
		)
	)
	return ret
)

-- fnSearchForSectorsAndPortals()
fn fnSearchForSectorsAndPortals sel =
(
	local sectorList = #()
	local portalList = #()
	
	for node in sel do
	(
		local tmp = fnCheckSectorProps node
		
		case tmp[1] of
		(
			#Portal : append portalList (_portalList node #() undefined tmp[2])
			#Sector : append sectorList (_sectorList node #() tmp[2])
		)
		
		-- search in nodes children
		if node.children.count > 0 do
		(
			tmp = fnSearchForSectorsAndPortals node.children
			for n in tmp[1] do if findItem sectorList n == undefined do append sectorList n
			for n in tmp[2] do if findItem portalList n == undefined do append portalList n
		)
	)
	
	return #(sectorList, portalList)
)

-- fnCollideWall
fn fnCollideWall mesh point normal faceIDX =
(
	local t = 0
	local b = false
	
	return #(t, b)
)

-- fnCheckSectorsWalls
fn fnCheckSectorsWalls sector =
(
	local sMesh = copy sector.sector.mesh
	local t0 = 1
	local k = false
	local n = true
	local sNormal, sCenter, point, r, temp
	
	for f = 1 to (getNumFaces sMesh) do
	(	-- get sector's face normal
		sNormal = ((getFaceNormal sMesh f) * sector.sector.objecttransform) - ([0,0,0] * sector.sector.objecttransform)
		sNormal = normalize sNormal
		-- get sector's face center
		sCenter = (meshop.getFaceCenter sMesh f) * sector.sector.objecttransform
		
		-- get point in a space
		point = sNormal + sCenter

--		format "%\t%\n" point (-sNormal)
		
		temp = fnCollideWall sMesh point (-sNormal) f
		
		if temp[2] then
		(
			k = not k
			if temp[1] < t0 then n = not n
		)
		
/*
		if k then
		(
			if not n then
		)
		else
		(
		)
*/
	)
	return sector
)

-- fnCheckPortalsPosition
fn fnCheckPortalsPosition sector =
(
	local tresh = 0.001
	local aTresh = 0.002
	local sMesh = copy sector.sector.mesh
	local pMesh, pNormal, sNormal, pCenter, sCenter, u
	
	for p in sector.portals do
	(	-- get portal's mesh
		pMesh = copy p.portal.mesh
		local type = #none
		
		for pf = 1 to (getNumFaces pMesh) do
		(	-- get portal's face normal
			pNormal = ((getFaceNormal pMesh pf) * p.portal.objecttransform) - ([0,0,0] * p.portal.objecttransform)

			-- get sector's face center
			pCenter = (meshop.getFaceCenter pMesh pf) * p.portal.objecttransform
			
			for sf = 1 to (getNumFaces sMesh) do
			(	-- get sector's face normal
				sNormal = ((getFaceNormal sMesh sf) * sector.sector.objecttransform) - ([0,0,0] * sector.sector.objecttransform)
				sNormal = normalize sNormal

				-- get sector's face center
				sCenter = (meshop.getFaceCenter sMesh sf) * sector.sector.objecttransform
				
				-- get dist from portal face to sector face
				dist = (sNormal.x * (pCenter.x - sCenter.x)) + (sNormal.y * (pCenter.y - sCenter.y)) + (sNormal.z * (pCenter.z - sCenter.z))
				
				-- check portal's face distance from sector's face
				if abs(dist) < tresh then
				(	-- portal's face lay on sector's face

					u = pNormal.x * sNormal.x + pNormal.y * sNormal.y + pNormal.z * sNormal.z

					-- check normals flipping
					-- ok
					if u > (1 - aTresh) and u <= (1 + aTresh) then type = #good
					-- portal's normal is flipped
					else if u > (- 1 - aTresh) and u < (-1 + aTresh) then type = #flipped
					-- normals are different
					else type = #different
				)
			)
			case type of
			(
				#none :			append p.errors #wrongFace
				#flipped :		append p.errors #flippedFace
				#different :	append p.errors #rotatedFace
				default:		continue
			)
			exit
--			format "%\t%\n\n" p.portal.name type
		)
	)
	
	return sector
)

-- fnCheckResult()
fn fnCheckResult sectorList portalList = 
(
	local temp
	-- check sectors
	for s in sectorList do
	(
		-- find sector's portals
		for c in s.sector.children do
		(
			portal = fnFindPortal portalList c
			if portal != undefined do
			(
				portal.sector = s.sector
				append s.portals portal
			)
		)
		-- check sectors walls facing
		s = fnCheckSectorsWalls s
		-- check position ad rotation of portals
		s = fnCheckPortalsPosition s
	)
	-- check portals
	for p in portalList do
	(
		-- find portal doubler(s)
		for pp in portalList do if p.portal != pp.portal do
		(	-- compare pivot pos
			if abs(p.portal.pivot.x - pp.portal.pivot.x) < 0.001 and
			   abs(p.portal.pivot.y - pp.portal.pivot.y) < 0.001 and
			   abs(p.portal.pivot.z - pp.portal.pivot.z) < 0.001 do
			(
				append p.doublers pp
			)
		)
		
		if p.doublers.count > 1 then
		(	-- too much doublers
			append p.errors #wrongPivot
		)
		else if p.doublers.count == 0 then
		(	-- doubler is world portal
			append p.errors #noDoubler
		)
	)
	-- check if portal doubler isn't from the same sector
	for p in portalList do
		for d in p.doublers do
			if p.sector == d.sector do
			(
				append p.errors #wrongDoubler
				exit
			)

	return #(sectorList, portalList)
)

-- checkSectorsDialog
rollout checkSectorsDialog "Sector checker" width:500 height:400
(
	local width = 500
	local height = 400
	local sectorList, portalList
	
	-- GUI
	label lblSectors "" pos:[8,8] width:(width/2 - 28)
	label lblPortals "" pos:[8 + width/2 - 20,8] width:(width/2 - 16 + 20)
	activeXControl axSectorList "MSComctlLib.TreeCtrl" pos:[8,8+16] width:(width/2 - 28) height:(height - 16 - 16)
	activeXControl axListView "MSComctlLib.ListViewCtrl" pos:[8 + width/2 - 20,8+16] width:(width/2 - 16 + 20) height:(15 * 4 - 1)
	edittext edtUserProps "" pos:[4 + width/2 - 20,15 * 4 + 16 * 2] width:(width/2 - 16 + 20 + 4) height:(15*8)
	button btnPrevBug "Previous bug" pos:[355,249] width:137 height:24 enabled:false
	button btnNextBug "Next bug" pos:[355,220] width:137 height:24 enabled:false
	button btnRefresh "Refresh" pos:[width - 64 * 2 - 8 * 2, height - 24 - 8] width:64 height:24
	button btnClose "Close" pos:[width - 64 - 8, height - 24 - 8] width:64 height:24
	-- Image list controls for holding icons
	activeXControl	ilTvSmallIcons "{2C247F23-8591-11D1-B16A-00C0F0283628}" height:0 width:0
	
	-- ax init functions
	fn fnInitIcons il =
	(
		local iconPath = fnReturnPath #ico 
		-- define temp bitmap control (small icons)
		il.imageheight = 14
		il.imagewidth = 14
		il.maskColor = color 212 212 212
		il.useMaskColor = true
		-- add small icons
		il.listImages.add 1 #new (loadPicture (iconPath + "\\sector.bmp"))
		il.listImages.add 2 #new (loadPicture (iconPath + "\\portal.bmp"))
		il.listImages.add 3 #new (loadPicture (iconPath + "\\doubler.bmp"))
	)
	-- fnInitListView()
	fn fnInitListView lv =
	(
		local LVM_SETCOLUMNWIDTH = (0x1000 + 30)
		local ch
		
		enableAccelerators = true
		lv.Appearance = #ccFlat
		lv.BorderStyle = #ccFixedSingle
		lv.FullRowSelect = true
		lv.GridLines = true
		lv.HideColumnHeaders = true
		lv.HideSelection = false
		lv.LabelEdit = #lvwManual
		lv.MultiSelect = false
		lv.Sorted = false
		lv.SortOrder = #lvwAscending		
		lv.View = #lvwReport

		ch = lv.ColumnHeaders.add()
		ch.text = ""
		windows.sendMessage lv.hwnd LVM_SETCOLUMNWIDTH 0 (lv.size.x - 18)
	)
	-- fnInitTreeView()
	fn fnInitTreeView tv =
	(
		tv.Appearance = #ccFlat
		tv.BorderStyle = #ccFixedSingle
		tv.FullRowSelect = true
		tv.HideSelection = false
		tv.HotTracking = false
		tv.Indentation = 10
		tv.LabelEdit = #tvwManual
		tv.LineStyle = #tvwRootLines --#tvwTreeLines --
		tv.Pathseparator = "."
		tv.Scroll = true
		tv.SingleSel = false
		tv.Style = #tvwTreelinesPlusMinusPictureText --
		tv.imageList = ilTvSmallIcons
	)

	-- fnFillListView
	fn fnFillListView lv item =
	(
		local node, type, lvItem

		if item == undefined do return false
		if (node = fnFindSector sectorList item.tag) != undefined then
		(
			type = #sector
			lblPortals.text = node.portals.count as string + " portal(s) in sector"
			edtUserProps.text = getUserPropBuffer node.sector
		)
		else if (node = fnFindPortal portalList item.tag) != undefined then
		(
			type = #portal
			lblPortals.text = node.doublers.count as string + " portal's doubler(s)"
			edtUserProps.text = getUserPropBuffer node.portal
		)
		else
			return false

		lv.listItems.clear()
		for e in node.errors do
		(
			lvItem = lv.ListItems.add()
			case e of
			(
				#wrongParent :	lvItem.text = "Node has wrong parent or wrong properties."
				#wrongProps :	lvItem.text = "Node has wrong properties."
				#wrongChild :	lvItem.text = "Node has wrong Child(ren)."
				#noParent :		lvItem.text = "Portal isn't associated with any sector."
				#wrongPivot :	lvItem.text = "Portal has too many doublers (wrong pivot)."
				#noDoubler :	lvItem.text = "Portal has no doubler (propably is world portal)."
				#wrongDoubler : lvItem.text = "Portal has wrong doubler (in the same sector)."
				#wrongFace :	lvItem.text = "Portal doesn't lay on any sector's wall."
				#flippedFace :	lvItem.text = "Portal has flipped face."
				#rotatedFace :	lvItem.text = "Portal has rotated face."
				default : 		lvItem.text = e as string
			)
			lvItem.ToolTipText = lvItem.Text
			lvItem.tag = node
		)
	)

	-- fnFillListTree()
	fn fnFillListTree tv =
	(
		local tvNode, tvSubNode, tvSubSubNode
		
		tv.nodes.clear()
		
		-- add sectors and portals
		for s in sectorList do
		(
			tvNode = tv.nodes.add()
			tvNode.tag = s.sector
			tvNode.text = s.sector.name
			tvNode.image = 1
			if s.errors.count > 0 do
			(
				tvNode.ForeColor = (color 0 0 255)
			)
			
			for p in s.portals do
			(	-- add sector's portals
				tvSubNode = tv.nodes.add tvNode.index 4 "" p.portal.name
				tvSubNode.tag = p.portal
				tvSubNode.image = 2
				if p.errors.count == 1 and (findItem p.errors #noDoubler) > 0 then
				(	-- doubler is world portal
					tvSubNode.ForeColor = (color 255 0 0)
					tvNode.Expanded = true
				)
				else if p.errors.count > 0 do
				(	-- highlighted error
					tvSubNode.ForeColor = (color 0 0 255)
					tvNode.Expanded = true
				)
				for d in p.doublers do
				(	-- add portal's doublers
					tvSubSubNode = tv.nodes.add tvSubNode.index 4 "" d.portal.name
					tvSubSubNode.tag = d.portal
					tvSubSubNode.image = 3
				)
			)
		)
		-- add portals with no sector
		for p in portalList do
		(
			if findItem p.errors #noParent > 0 or findItem p.errors #wrongParent > 0 do
			(
				tvNode = tv.nodes.add()
				tvNode.text = p.portal.name
				tvNode.tag = p.portal
				tvNode.ForeColor = (color 0 0 255)
				tvNode.image = 2
			)
		)
	)
	
	-- fnUpdateUI()
	fn fnUpdateUI =
	(
		local temp
		setWaitCursor()

		with redraw off
		(
			-- get sectors data
			temp = fnSearchForSectorsAndPortals geometry
			temp = fnCheckResult temp[1] temp[2]
			sectorList = temp[1]
			portalList = temp[2]
	
			-- fill data into tree view
			axSectorList.enabled = false
			fnFillListTree axSectorList
			axSectorList.selectedItem = axSectorList.nodes[1]
			axSectorList.enabled = true
			
			-- fill data into list view and user props
			fnFillListView axListView axSectorList.selectedItem
			
			lblSectors.text = sectorList.count as string + " sector(s) in scene"
		)
		
		setArrowCursor()
	)
	
	-- fnProcessKeys()
	fn fnProcessKeys keyCode shift type =
	(
		case keyCode of
		(
			-- tab
			9 : ()
			-- enter
			13 :	if type == #tree then
					(
						try (select axSectorList.selectedItem.tag) catch (fnUpdateUI())
					)
			-- esc
--			27 : destroyDialog checkSectorsDialog
			-- end
			35 :	if type == #tree then
					(
						axSectorList.selectedItem = axSectorList.nodes[axSectorList.nodes.count]
						fnFillListView axListView axSectorList.selectedItem
					)
			-- home
			36 :	if type == #tree then
					(
						axSectorList.selectedItem = axSectorList.nodes[1]
						fnFillListView axListView axSectorList.selectedItem
					)
			-- left
			37 :	if type == #tree then
					(
						if axSectorList.selectedItem.children > 0 and axSectorList.selectedItem.expanded then
							axSectorList.selectedItem.expanded = false
						else if axSectorList.selectedItem.parent == undefined then
							axSectorList.selectedItem.expanded = false
						else
							axSectorList.selectedItem.parent.expanded = false
						fnFillListView axListView axSectorList.selectedItem
					)
			-- up
			38 :	if type == #tree then
					(
						fnFillListView axListView axSectorList.selectedItem
					)
			-- right
			39 :	if type == #tree then
					(
						if axSectorList.selectedItem.children > 0 then
							axSectorList.selectedItem.expanded = true
						fnFillListView axListView axSectorList.selectedItem
					)
			-- down
			40 :	if type == #tree then
					(
						fnFillListView axListView axSectorList.selectedItem
					)
		)
	)
	
	-- event handles
	on axSectorList keyup keyCode shift do fnProcessKeys keyCode shift #tree
	on axListView keyup keyCode shift do fnProcessKeys keyCode shift #list
	on axSectorList click do fnFillListView axListView axSectorList.selectedItem
	on axSectorList dblclick do try (select axSectorList.selectedItem.tag) catch (fnUpdateUI())
	on axSectorList MouseUp button shift x y do if axSectorList.selectedItem != undefined do
	(
		if button == 2 do
		(
			rcmenu rcmSectorChecker
			(
				menuItem miSelectNode		"Select node\tEnter"	checked:false
				
				on miSelectNode picked do  try (select axSectorList.selectedItem.tag) catch (fnUpdateUI())
				on rcmSectorChecker open do ()
			)
			
			popUpMenu rcmSectorChecker pos:[axSectorList.pos.x + x,axSectorList.pos.y + y] rollout:checkSectorsDialog
		)
	)
	on btnRefresh pressed do fnUpdateUI()
	on btnClose pressed do destroyDialog checkSectorsDialog
	on edtUserProps entered text do try (setUserPropBuffer axSectorList.selectedItem.tag text) catch (fnUpdateUI())
	on checkSectorsDialog open do
	(
		-- init ax
		fnInitIcons ilTvSmallIcons
		fnInitTreeView axSectorList
		fnInitListView axListView

		-- update UI
		fnUpdateUI()
	)
	on checkSectorsDialog close do
	(
		checkSectorsDialogActive = undefined
		updateToolbarButtons()
	)
)

/*
	#nodeRenamed
	#nodeLinked
	#nodeUnlinked
--	#nodePostDelete
--	#nodeCloned
	#postNodesCloned
	#postNodeUserPropChanged
	#sceneNodeAdded
	#selectedNodesPostDelete
	#selectionSetChanged
*/
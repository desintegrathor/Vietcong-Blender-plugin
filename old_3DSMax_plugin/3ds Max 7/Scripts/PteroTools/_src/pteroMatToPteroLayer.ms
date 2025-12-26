fn fnDoCollectPteroMats ret a newMat:undefined =
(
	for m in a do
	(
		local id = m.classid
		
		if (id[1] == 1699607506) and (id[2] == 1692035545) then
		(	-- pteroMat
			if (findItem ret m) == 0 do
			(
				append ret m
				if newMat != undefined do
					m = newMat
			)
		)
		else
		if (id[1] == 512) and (id[2] == 0) then
		(	-- multiMaterial
			fnDoCollectPteroMats ret m.materialList
		)
	)
	return ret
)

fn fnCollectPteroMats sel:$ newMat:undefined =
(
	local ret = #()

	if sel == undefined then
	(
		ret = fnDoCollectPteroMats ret meditMaterials newMat:newMat
		ret = fnDoCollectPteroMats ret sceneMaterials newMat:newMat
	)
	else for n in sel do
	(
		if n.material != undefined do ret = fnDoCollectPteroMats ret #(n.material) newMat:newMat
	)

	return ret
)

rollout dlgPteroMatToPteroLayer "Convert pteroMat to pteroLayer" width:392 height:504
(
	local blankColor = ((colorMan.getColor #background) as color) * 255
	local blankBmp = bitmap 2 2 color:blankColor
	local bitmapCache = #()
	
	label lbl1 "Materials:" pos:[8,8]
	activeXControl axMaterialList "MSComctlLib.TreeCtrl" pos:[8,27] width:184 height:280
	imgtag imgBmp pos:[8,312] width:184 height:184 style:#bmp_center bitmap:blankBmp transparent:blankColor
	dropDownList ddlShader "Shader:" pos:[200,8] width:164 height:40
	button btnDefault "D" pos:[363,26] width:20 height:20 tooltip:"Default by pteroMat" enabled:false
	dropDownList ddlSubShader "Sub-Shader:" pos:[200,56] width:184 height:40
	label lbl3 "Layers:" pos:[200,104]
	activeXControl axLayers "MSComctlLib.ListViewCtrl" pos:[200,122] width:184 height:185
	groupBox grp1 "Note" pos:[200,312] width:184 height:56
	label lbl5 "This tool will convert all instances of selected material." pos:[208,328] width:166 height:32
	button btnClearCache "Clear bitmap cache" pos:[200,430] width:184 height:23
	button btnConvert "Convert" pos:[200,472] width:88 height:23
	button btnClose "Close" pos:[296,472] width:88 height:23
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
		il.listImages.add 2 #new (loadPicture (iconPath + "\\texture_loaded.bmp"))
		il.listImages.add 3 #new (loadPicture (iconPath + "\\texture_notfound.bmp"))
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
		ch.text = "Layer"
		windows.sendMessage lv.hwnd LVM_SETCOLUMNWIDTH 0 ((lv.size.x - 18) / 2)
		ch = lv.ColumnHeaders.add()
		ch.text = "Bitmap"
		windows.sendMessage lv.hwnd LVM_SETCOLUMNWIDTH 1 ((lv.size.x - 18) / 2)
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

	-- fnFillListTree()
	fn fnFillListTree tv items =
	(
		local tvNode, tvSubNode
		
		tv.nodes.clear()
		
		-- add sectors and portals
		for i in items do
		(
			tvNode = tv.nodes.add()
			tvNode.tag = i
			tvNode.text = i.name
			tvNode.image = 1

			for n = 1 to i.maps.count do
			(	-- add materials maps
				local m = i.maps[n]
				if m == undefined do continue
				local str = case n of
				(
					13: "Diff: "
					14:	"Struc: "
					15:	"Over: "
					20:	"LM: "
					19:	"Env: "
				)
				tvSubNode = tv.nodes.add tvNode.index 4 "" (str + m.name)
				tvSubNode.tag = m
				if (doesFileExist m.filename) then
					tvSubNode.image = 2
				else
					tvSubNode.image = 3
			)
		)
	)

	-- fnFillListView
	fn fnFillListView =
	(
		local ret = true
		local lvItem, lvSubItem

		axLayers.listItems.clear()
		
		local shdr = pteroShaderList.fnGetSubShaderData ddlShader.selected ddlSubShader.selected
		local layerOrder = sort (shdr.layers as array)

		for n = 1 to layerOrder.count do
		(
			for t = 1 to pteroLayerDefinition.count do
			(
				local map = undefined
				local texCh = fnReturnTexChannel n:layerOrder[n]

				if layerOrder[n] != pteroLayerDefinition[t].texID do continue

				lvItem = axLayers.ListItems.add Text:pteroLayerDefinition[t].label
				lvItem.ToolTipText = "ID " + layerOrder[n] as string + ": " + pteroLayerDefinition[t].label
				lvItem.Tag = layerOrder[n]
				lvSubItem = lvItem.ListSubItems.add()
				
				if axMaterialList.selectedItem == undefined do
				(	-- material list is empty
					ret = false
					continue
				)
				
				if axMaterialList.selectedItem.image != 1 then
					item = axMaterialList.selectedItem.Parent
				else
					item = axMaterialList.selectedItem

				if texCh != undefined then map = item.tag.maps[texCh]

				if map == undefined then
				(	-- shader needs more bitmap
					if bitmapCache[layerOrder[n]] == undefined then
					(
						lvSubItem.Text = " - no bitmap -"
						lvSubItem.ToolTipText = "Double click to select bitmap"
						lvSubItem.Tag = -1
						lvItem.ForeColor = (color 0 0 255)
						lvSubItem.ForeColor = (color 0 0 255)
						ret = false
					)
					else
					(
						lvSubItem.Text = getFilenameFile bitmapCache[layerOrder[n]]
						lvSubItem.ToolTipText = bitmapCache[layerOrder[n]]
						lvSubItem.Tag = 0
						lvItem.ForeColor = (color 255 0 0)
						lvSubItem.ForeColor = (color 255 0 0)
					)
				)
				else
				(
					lvSubItem.Text = getFilenameFile map.filename
					lvSubItem.ToolTipText = map.filename
					lvSubItem.Tag = 1
					lvItem.ForeColor = (color 0 0 0)
					lvSubItem.ForeColor = (color 0 0 0)
				)
			)
		)

		return ret
	)

	fn fnShowBitmap item =
	(
		if item == undefined do return false
		if item.image == 2 then
		(
			imgBmp.bitmap = fnScaleBitmap m:item.tag.bitmap w:184 h:184
			imgBmp.tooltip = item.tag.filename
		)
		else
		(
			imgBmp.bitmap = blankBmp
			imgBmp.tooltip = ""
		)
	)
	
	-- fnFillSubType()
	fn fnFillSubType = (
		local subShdArray = #()
		local shd = pteroShaderList.fnGetShaderData ddlShader.selected
		local old = ddlSubShader.selected
		local idx

		-- cancel operation if loading material and mEdit is open
		if shd == undefined do return false
		
		-- fill sub-shaders names to array
		for n = 1 to shd.count do
			append subShdArray shd[n].name 
		ddlSubShader.items = subShdArray
		ddlSubShader.selection = if (idx = findItem ddlSubShader.items old) == 0 then 1 else idx

		-- cancel operation if sub-shader list is empty
		if subShdArray.count == 0 do return false
		
		return true
	)

	-- fnUpdateUI()
	fn fnUpdateUI refresh:false type:#none =
	(
		local temp, mats, canConvert

		setWaitCursor()

		-- refresh tables
		if bitmaptable.filenames.count == 0 or refresh do bitmaptable.refresh()
		if pteroShaderList.names.count == 0 do pteroShaderList.fnUpdate()
		
		-- collect pteroMats		
		mats = fnCollectPteroMats()

		-- fill data into tree view
		if refresh do
		(
			axMaterialList.enabled = false
			fnFillListTree axMaterialList mats
			axMaterialList.selectedItem = axMaterialList.nodes[1]
			axMaterialList.enabled = true
		)
		
		-- fill shader lists
		if refresh do
		(
			ddlShader.items = pteroShaderList.names
		)
		canConvert = fnFillSubType()
		if not fnFillListView() then canConvert = false
		
		-- show bitmap
--		case type of
		(
--			#matlist:
				fnShowBitmap axMaterialList.selectedItem
--			#layerlist: fnShowBitmap bitmapCache[axLayers.selectedItem.tag]
		)
		
		-- enable / disable convert button
		btnConvert.enabled = canConvert
		btnClearCache.enabled = if bitmapCache.count > 0 then true else false
		
		-- cleaning
		gc()
		
		setArrowCursor()
	)

	fn fnDoConvert =
	(
		local mat, newMat, shdr, layerOrder
		
		if axMaterialList.selectedItem == undefined do return false
		
		setWaitCursor()

		if axMaterialList.selectedItem.image != 1 then
			mat = axMaterialList.selectedItem.Parent.tag
		else
			mat = axMaterialList.selectedItem.tag

		newMat = pteroLayer()
		
		shdr = pteroShaderList.fnGetSubShaderData ddlShader.selected ddlSubShader.selected
		layerOrder = shdr.layers as array

		for n = 1 to layerOrder.count do
		(
			for t = 1 to pteroLayerDefinition.count do
			(
				local map = undefined
				local texCh = fnReturnTexChannel n:layerOrder[n]
				local idx = layerOrder[n]
				
				if idx != pteroLayerDefinition[t].texID do continue

				if texCh != undefined then map = mat.maps[texCh]
				
				if map == undefined then
				(
					newMat.layerFilename[idx] = bitmapCache[idx]
					newMat.layerChannel[idx] = idx
					newMat.layerTileU[idx] = true
					newMat.layerTileV[idx] = true
					newMat.layerTilingU[idx] = 1
					newMat.layerTilingV[idx] = 1
					newMat.layerMipmap[idx] = true
				)
				else
				(
					newMat.layerFilename[idx] = map.filename
					newMat.layerChannel[idx] = map.coords.mapChannel
					newMat.layerTileU[idx] = map.coords.U_Tile
					newMat.layerTileV[idx] = map.coords.V_Tile
					newMat.layerTilingU[idx] = map.coords.U_Tiling
					newMat.layerTilingV[idx] = map.coords.V_Tiling 
					newMat.layerMipmap[idx] = if map.output.bump_amount > 0.01 then true else false
					if texCh == 14 do -- Diffuse #2
						newMat.layerOverlayMultitex = mat.PRM_MIPMAP_OVERLAY
				)
			)
		)

		newMat.name = mat.name
		newMat.layerOrder = layerOrder
		newMat.shaderType = ddlShader.selected
		newMat.shaderFilename = shdr.filename
		newMat.subShaderType = ddlSubShader.selected
		
		newMat.matDiffuse = mat.delegate.Diffuse_Color
		newMat.matAmbient = newMat.matDiffuse / 2.5
		newMat.matSpecular = (color 229 229 229)
		newMat.matOpacity = mat.delegate.opacity
		
		newMat.surface = mat.PRM_COLLISION_TYPE
		newMat.grassType = mat.PRM_GROW_TYPE
		newMat.growType = mat.PRM_GRASS_TYPE
		
		for n = 1 to trnspArray.count do
		(
			if (subString trnspArray[n] 1 2) == mat.PRM_TRANSPARENT_TYPE do
			(
				newMat.transparency = n
				exit
			)
		)
		newMat.twoSided = mat.delegate.twoSided
		newMat.faceted = mat.delegate.faceted

--		mat = newMat
--		format "%\t%\n" mat newMat
		meditmaterials[6] = newMat
		
		fnReplaceOneMaterial mat newMat:newMat
--		local mats = fnCollectPteroMats newMat:newMat
/*		for m in mats do
		(
			if m == mat do m = newMat
		)
*/		
		bitmaptable.refresh()
		medit.setActiveMtlSlot activeMeditSlot true
		
		fnUpdateUI refresh:true

		setArrowCursor()
	)
	
	fn fnSelectBitmap =
	(
		if axLayers.selectedItem == undefined do return false
		if axLayers.selectedItem.ListSubItems[1].tag == 1 do return false
		
		-- hide window
		local dlgWidth = dlgPteroMatToPteroLayer.width
		local dlgHeight = dlgPteroMatToPteroLayer.height
		dlgPteroMatToPteroLayer.width = 0
		dlgPteroMatToPteroLayer.height = 0

		-- select file		
		local newFile = fnSelectBitmapDialog type:#pteroLayer
		if newFile[1] != 0 then
			bitmapCache[axLayers.selectedItem.tag] = newFile[2]
		
		-- unhide window
		dlgPteroMatToPteroLayer.width = dlgWidth
		dlgPteroMatToPteroLayer.height = dlgHeight
		
		-- update ui
		fnUpdateUI()
	)
	
	-- event handles
	on axMaterialList click do fnUpdateUI type:#matlist
--	on axLayers click do fnUpdateUI type:#layerlist
	on axLayers dblclick do fnSelectBitmap()
	on ddlShader selected sel do fnUpdateUI()
	on ddlSubShader selected sel do fnUpdateUI()
	on btnClearCache pressed do (bitmapCache = #(); fnUpdateUI())
	on btnConvert pressed do fnDoConvert()
	on btnClose pressed do destroyDialog dlgPteroMatToPteroLayer
	on dlgPteroMatToPteroLayer open  do
	(
		-- init ax
		fnInitIcons ilTvSmallIcons
		fnInitTreeView axMaterialList
		fnInitListView axLayers

		-- update UI
		fnUpdateUI refresh:true
	)
	on dlgPteroMatToPteroLayer close  do
	(
		-- final cleaning
		gc()
	)
)

--createDialog dlgPteroMatToPteroLayer modal:true

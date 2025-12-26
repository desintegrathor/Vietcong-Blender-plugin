---------------------------------------------------------------
--
-- PteroLayer - Body
--
-- by Pan Collette
--
-- Create:		09.12.2003
-- Modified:	29.11.2004
--
---------------------------------------------------------------

	---------------------------------------------------------------
	-- plugin locals
	---------------------------------------------------------------
	local scriptPath	= fnReturnPath #ms
	local _iniSect		= "pteroLayer"	
	local _bkcolor		= (color ((colorman.getColor #background).x*255) ((colorman.getColor #background).y*255) ((colorman.getColor #background).z*255))
	local _blankBmp		= bitmap 72 72 color:_bkcolor
	local _top			= medit.getTopMtlSlot activeMeditSlot
	local _this			= medit.getCurMtl()
	local layerFilenameExist = #()
--	local shdArray		= #()
--	local rolloutList	= #()
--	local oldShader		= [1,1]
--	local whichShow		= _whichShow 0 #none
	

	-- predefined functions and rollouts
	local roLayers
	local fnUtilizeTexture
	local fnUtilizeViewportBitmap
	
	---------------------------------------------------------------
	-- plugin parameters
	---------------------------------------------------------------
	parameters paramMain rollout:MaxMatRollout (
		maps				type:#texturemapTab	tabSize:1
		mapEnables			type:#boolTab		tabSize:1
		matDiffuse			type:#color		ui:pckDiffuse
		matAmbient			type:#color		ui:pckAmbient
		matSpecular			type:#color		ui:pckSpecular
		matSelfIllum		type:#color		ui:pckSelfIllum
		matOpacity			type:#integer	ui:spnOpacity			default:100
		matOpacityFalloff	type:#float		ui:spnOpacityFalloff	default:0
		matGlossiness		type:#integer	ui:spnGlossiness		default:10
		matSpecLevel		type:#integer	ui:spnSpecLevel			default:0

		on matOpacity set val do (
			delegate.opacity = val
			if ( b = getMTLMEditFlags this ) != matDialogSets do ()
			if val < 100 and (findItem b 2) == 0 do setMTLMEditFlags this (append b 2)
			if val == 100 and (findItem b 2) > 0 do setMTLMEditFlags this (deleteItem b 2)
		)
		on matOpacityFalloff set val do (
			delegate.opacityFallOff = val
		)
		on matDiffuse set val do (
			delegate.Diffuse_Color = val
		)
		on matAmbient set val do (
			delegate.Ambient_Color = val
		)
		on matSpecular set val do (
			delegate.Specular_Color = val
		)
		on matSelfIllum set val do (
			delegate.SelfIllumColor = val
		)
		on matSpecLevel set val do (
			delegate.SpecularLevel = val
		)
		on matGlossiness set val do (
			delegate.glossiness = val
		)
	)
	parameters paramSurface rollout:roSurface (
		surface			type:#string						default:""
		grassType		type:#string	ui:edtGrass			default:""
		growType		type:#string	ui:edtGrow			default:""
	)
	parameters paramLayer rollout:roLayers (
		shaderType		type:#string						default:""
		shaderFilename	type:#string						default:""
		subShaderType	type:#string						default:""
		transparency	type:#integer	ui:drpTransparent	default:1
 		twoSided		type:#boolean	ui:chk2Sided		default:false
		faceted			type:#boolean	ui:chkFaceted		default:false

		on faceted set val do delegate.faceted = val
		on twoSided set val do delegate.twoSided = val
	)
	parameters paramLayers (
		layerOrder				type:#intTab	tabSizeVariable:true
		layerMipmap				type:#boolTab	tabSize:13			default:true
		layerTileU				type:#boolTab	tabSize:13			default:true
		layerTileV				type:#boolTab	tabSize:13			default:true
		layerTilingU			type:#floatTab	tabSize:13			default:1.0
		layerTilingV			type:#floatTab	tabSize:13			default:1.0
		layerMove				type:#boolTab	tabSize:13			default:false
		layerMoveType			type:#intTab	tabSize:13			default:1
		layerMoveSoft			type:#boolTab	tabSize:13			default:false
		layerMoving				type:#point3Tab	tabSize:13			default:[0.0,0.0,0.0]
		layerChannel			type:#intTab	tabSize:13			default:1
		layerFilename			type:#stringTab	tabSize:13			default:""
		whichShow				type:#point3						default:[0,0,0]
--		layerFilenameExist		type:#intTab	tabSize:13			default:0
		-- OLD SPECIAL PARAMS
		layerOverlayMultitex	type:#boolean						default:false
		layerLMApplyLight		type:#boolean						default:false
		layerEnvType			type:#boolean						default:false
		-- NEW SPECIAL PARAMS
		OverlayMultitex			type:#intTab						default:0
		LMApplyLight			type:#intTab						default:0
		EnvType					type:#intTab						default:0
		-- DTA_WATER, DTA_GLASS
		isWater					type:#integer						default:0
		isGlass					type:#integer						default:0
		waterEnvBlend			type:#float							default:0.3
		waterAlphaAngle			type:#float							default:0.6
		waterSharpness			type:#point3						default:[0.5,0.5,0.5]
		waterShiftingXY			type:#point3						default:[1.0,1.0,0.0]
		waterShiftingUV			type:#point3						default:[-1.0,1.0,0.0]
		
/*		on layerClipUV set val do
			if (val.z as integer) != 0 do if layerCrop[(val.z as integer)] do fnUtilizeViewportBitmap (val.z as integer) #btnCrop
		on layerClipWH set val do
			if (val.z as integer) != 0 do if layerCrop[(val.z as integer)] do fnUtilizeViewportBitmap (val.z as integer) #btnCrop
*/	)

	-----------------------------------------------
	-- fnCloseRollOut()
	-----------------------------------------------
	fn fnCloseRollOut r = (
		fnSaveINI ( r.name + "RolledUp" ) ( ( not r.open ) as string ) (fnReturnFilename #ini) _iniSect
		return true
	)

	-----------------------------------------------
	-- fnOpenRollOut()
	-----------------------------------------------
	fn fnOpenRollOut r = (
		local tmp = fnLoadINI ( r.name + "RolledUp" ) (fnReturnFilename #ini) _iniSect

		case (fnUpcase tmp) of (
			"FALSE"	: r.open = true
			default	: r.open = false
		)

		return true
	)

	-----------------------------------------------
	-- fnRolloutIDXbyLabel()
	-----------------------------------------------
	fn fnRolloutIDXbyLabel label = (
		local tmp = 0

		for n = 1 to pteroLayerRolloutList.count do
			if pteroLayerRolloutList[n].label == label do (
				tmp = n
				exit
			)

		return tmp
	)

	-----------------------------------------------
	-- fnRolloutIDXbyTexID()
	-----------------------------------------------
	fn fnRolloutIDXbyTexID tex_id = (
		local tmp = 0

-- todo		print pteroLayerRolloutList
		
		for n = 1 to pteroLayerRolloutList.count do
			if pteroLayerRolloutList[n].tex_id == tex_id do (
				tmp = n
				exit
			)

		return tmp
	)

	-----------------------------------------------
	-- fnControlIDXbyLabel()
	-----------------------------------------------
	fn fnControlIDXbyLabel label idx = (
		local tmp = 0

		if idx != 0 do
			for n = 1 to pteroLayerRolloutList[idx].name.controls.count do
				if pteroLayerRolloutList[idx].name.controls[n].name == label as string do (
					tmp = n
					exit
				)
	
		return tmp

	)

	-----------------------------------------------
	-- fnAppendRollOut()
	-----------------------------------------------
	fn fnAppendRollOut name label = (
		local tex_id	= try ( name.fnTexID() ) catch ( 0 )
		local tmp		= _roListInfo name label tex_id
		local idx		= fnRolloutIDXbyLabel label

		if idx != 0 do return false
		append pteroLayerRolloutList tmp

--		print pteroLayerRolloutList
		
		return true
	)

	-----------------------------------------------
	-- fnAddRollOut()
	-----------------------------------------------
	fn fnAddRollOut label s:undefined = (
		local idx = fnRolloutIDXbyLabel label

		if s == undefined do return false
		if idx == 0 do return false

		if s then
			addRollOut pteroLayerRolloutList[idx].name
		else
			removeRollOut pteroLayerRolloutList[idx].name

		return true
	)

	-----------------------------------------------
	-- fnCreateTexture()
	-----------------------------------------------
	fn fnCreateTexture id = (
	)

	-----------------------------------------------
	-- fnShowFileDetails()
	-----------------------------------------------
	fn fnShowFileDetails tex_id type = (
		local str = if type == #name then "- none -" else ""
--		local fileExist
		
--		fileExist = doesFileExist layerFilename[tex_id]
		
		if layerFilename[tex_id] != "" do
			case type of (
				#name : (
					str = if layerFilenameExist[tex_id] == 1 then "" else "NOT FOUND: "
					str += getFilenameFile layerFilename[tex_id] + getFilenameType layerFilename[tex_id]
					str = fnCutString s:str length:195
				)
				#path : (
					str = getFilenamePath layerFilename[tex_id]
					if str == "" do str = "NOT FOUND"
					str = fnCutString s:str length:195
				)
				#size : if layerFilenameExist[tex_id] == 1 do (
--					local bmpID = findItem bitmapTable.fileNames (getFilenameFile layerFilename[tex_id])
					local bmpID = bitmapTable.getIDX layerFilename[tex_id]
					try
					(
--						local map = bitmapTable.textures[bmpID].bitmap --openBitmap layerFilename[tex_id]
						local map = (bitmapTable.getTextureByIDX bmpID).bitmap
						str = (map.width) as string + " x " + (map.height) as string
						str = fnCutString s:str length:115
					)
					catch
					(
						str = "error loading bitmap"
						str = fnCutString s:str length:115
					)
				)
			)

		return str
	)
	
	-----------------------------------------------
	-- fnFillTextureValues()
	-----------------------------------------------
	fn fnFillTextureValues tex_id map type = (
		local types = if type == #all then
			#(type)
		else
			#(#spnChannel, #spnTilingU, #spnTilingV, #btnTileU, #btnTileV) --, #btnCrop)

		for type in types do
			case type of (
				#spnChannel :	map.coordinates.mapChannel = layerChannel[tex_id]
				#spnTilingU :	map.coordinates.u_tiling = layerTilingU[tex_id]
				#spnTilingV :	map.coordinates.v_tiling = layerTilingV[tex_id]
				#btnTileU :		map.coordinates.u_tile = layerTileU[tex_id]
				#btnTileV :		map.coordinates.v_tile = layerTileV[tex_id]
/*				#btnCrop : (
								map.apply = layerCrop[tex_id]
								map.cropPlace = 0
								map.clipu = layerClipUV[tex_id].x
								map.clipv = layerClipUV[tex_id].y
								map.clipw = layerClipWH[tex_id].x
								map.cliph = layerClipWH[tex_id].y
				)
*/			)
	)
	
	-----------------------------------------------
	-- fnUtilizeViewportBitmap()
	-----------------------------------------------
	fn fnUtilizeViewportBitmap tex_id type = (
		local workMap

--		format "tex_id: %\ttype: %\n" tex_id (type as string)
		-- if wrong tex_id exit
		if tex_id != whichShow[1] do return false

		-- check it
		if tex_id == 0 then (
			type = #delete
		) else
			-- if file doesn't exist exit
			if layerFilenameExist[tex_id] != 1 do return false
	
		case type of (
			#create :
			(
				-- create bitmapTexture(s) for viewport
				workMap = bitmapTexture filename:layerFilename[tex_id]
				delegate.diffuseMap	= copy workMap
				delegate.diffuseMap.name = "Diffuse: " + (getFilenamefile layerFilename[tex_id])
				delegate.diffuseMapEnable = true
				delegate.diffuseMap.coordinates.mapping	= 0 
				delegate.diffuseMap.RGBoutput = 0
				delegate.diffuseMap.alphaSource = 2
				delegate.diffuseMap.preMultAlpha = true
				fnFillTextureValues tex_id delegate.diffuseMap #all
				case whichShow[2] of (
					1: (--#btnShowBitmap : (
						delegate.filterMap = undefined
						delegate.filterMapEnable = false

						delegate.opacityMap	= undefined
						delegate.opacityMapEnable = false
					)
					2: (--#btnShowAlpha : (
						delegate.filterMap = undefined
						delegate.filterMapEnable = false

						delegate.diffuseMap.RGBoutput = 1
						delegate.diffuseMap.alphasource = 0
						delegate.opacityMap	= undefined
						delegate.opacityMapEnable = false
					)
					3: (--#btnShowTransp : (
						delegate.filterMap = delegate.diffuseMap
						delegate.filterMapEnable = true
						
						delegate.opacityMap	= copy workMap
						delegate.opacityMap.name = "Opacity: " + delegate.diffuseMap.name
						delegate.opacityMapEnable = true
						delegate.opacityMap.monoOutput = 1
						delegate.opacityMap.alphaSource = 0
						delegate.opacityMap.output.invert = true
						fnFillTextureValues tex_id delegate.opacityMap #all
					)
				)
				this.showInViewport = true
			)
			#reload :
			(
				if delegate.diffuseMap == undefined do return false
				delegate.diffuseMap.filename = layerFilename[tex_id]
				case whichShow[2] of (
					1:
					(
						delegate.filterMap = undefined
						delegate.opacityMap	= undefined						-- #btnShowBitmap :	
					)
					2:
					(
						delegate.filterMap = undefined
						delegate.opacityMap	= undefined						-- #btnShowAlpha :
					)
					3:
					(
						delegate.filterMap = delegate.diffuseMap
						delegate.opacityMap.filename = layerFilename[tex_id] --#btnShowTransp 
					)
				)
			)
			#delete :
			(
				this.showInViewport = false
				delegate.opacityMap	= undefined
				delegate.diffuseMap	= undefined
				delegate.filterMap = undefined
				delegate.diffuseMapEnable = false
				delegate.opacityMapEnable = false
				delegate.filterMapEnable = false
			)
			default :
			(
				local imaps = #()
				if delegate.diffuseMap != undefined do append imaps delegate.diffuseMap
				if delegate.opacityMap != undefined do append imaps delegate.opacityMap
				for map in imaps do
					fnFillTextureValues tex_id map type
			)
		)
		maps[1] = delegate.diffuseMap
		mapEnables[1] = if maps[1] != undefined then true else false
	)
	
	-----------------------------------------------
	-- fnSelectBitmap()
	-----------------------------------------------
	fn fnSelectBitmap tex_id = (
		local ret = false
		local newFile = fnSelectBitmapDialog type:#pteroLayer
		
		if newFile == undefined do return ret
		
		local tmpPath = if newFile[2] != undefined then getFilenamePath newFile[2] else ""
		local fTypes = fnReturnFileTypes()
		local type = #all
		local map
		
		-- try another paths if bitmap hasn't one		
		if tmpPath == "" do
			tmpPath = fnReturnPath #max
		if tmpPath == "" do
			tmpPath = fnReturnPath #scn
		
		if newFile[2] != undefined then (
			-- check if file exists and if not find it
			if not (doesFileExist newFile[2]) and tmpPath != "" do (
				newFile[1] = (fnRecursiveSearch tmpPath newFile[2] fTypes type:#bitmap)
				if newfile[1] != undefined do newFile[2] = newFile[1]
			)
			
			if newFile[1] != undefined then (
				-- if file exist
				map = copy (bitmapTexture filename:newFile[2])
				layerFilename[tex_id] = map.filename
				layerFilenameExist[tex_id] = 1
			) else (
				-- if file doesn't exist
				layerFilename[tex_id] = newFile[2]
				whichShow = [0,0,0] --.setup 0 #none
				layerFilenameExist[tex_id] = 0
			)

			ret = true
		) else
			-- filename is missing
--			if layerEnabled[tex_id] and 
			if layerFilename[tex_id] != "" then
				ret = true
			else
				type = #light
		
		-- refresh bitmap table
		bitmapTable.refresh()

		-- setup layer
		pteroLayerRolloutList[(fnRolloutIDXbyTexID tex_id)].name.fnUpdateUI type
		fnUtilizeViewportBitmap tex_id #reload
		
		return ret
	)
	
	-----------------------------------------------
	-- fnDoThumb()
	-----------------------------------------------
	fn fnDoThumb tex_id type control:undefined = (
		local map = undefined
		local tip = ""
		local bmpID
		
		-- process if file exists
		if layerFilenameExist[tex_id] == 1 then (
			bmpID = bitmapTable.getIDX layerFilename[tex_id]
--			bmpID = findItem bitmapTable.fileNames (getFilenameFile layerFilename[tex_id])
			if bmpID == 0 then
				map = copy _blankBmp
			else
			(
--				try map = bitmapTable.textures[bmpID].bitmap --openBitmap layerFilename[tex_id]
				try map = (bitmapTable.getTextureByIDX bmpID).bitmap
				catch map = _blankBmp
				case type of (
					#small:
					(
						map = fnScaleBitmap m:map w:72 h:72
						tip = layerFilename[tex_id]
						if (tex_id == whichShow[1]) and (delegate.diffuseMap.filename != layerFilename[tex_id]) do
						(	-- reload bitmap for viewport if different path
							fnUtilizeViewportBitmap tex_id #reload
						)
					)
					#big: display map
				)
			)
		)

		-- setup control values
		if control != undefined do (
			control.bitmap = map
			control.tooltip = tip
		)
		
		return map
	)
	
	-----------------------------------------------
	-- fnUndefineBitmap()
	-----------------------------------------------
	fn fnUndefineBitmap tex_id = (
		layerFilename[tex_id] = ""

		pteroLayerRolloutList[(fnRolloutIDXbyTexID tex_id)].name.fnUpdateUI #light
		if whichShow[1] == tex_id do (
			whichShow = [0,0,0] --.setup 0 #none
			fnUtilizeViewportBitmap whichShow[1] #delete
			fnUtilizeTexture tex_id #btnShowBitmap read:true
			fnUtilizeTexture tex_id #btnShowAlpha read:true
			fnUtilizeTexture tex_id #btnShowTransp read:true
		)

		-- refresh bitmap table
		bitmapTable.refresh()
	)

	-----------------------------------------------
	-- fnReloadBitmap()
	-----------------------------------------------
	fn fnReloadBitmap tex_id =
	(
		if layerFilename[tex_id] != undefined do --and layerBitmap[tex_id] != undefined do 
			if (doesFileExist layerFilename[tex_id]) do (
				local map = copy (bitmapTexture filename:layerFilename[tex_id])
			)
		-- refresh bitmap table
		bitmapTable.refresh()
	)
	
	-----------------------------------------------
	-- fnEnableLayer()
	-----------------------------------------------
/*	fn fnEnableLayer tex_id state type:#light = (
		if layerFilename[tex_id] == "" then
			layerChannel[tex_id] = tex_id
--		layerEnabled[tex_id] = state
		pteroLayerRolloutList[(fnRolloutIDXbyTexID tex_id)].name.fnUpdateUI type
	)
*/
	-----------------------------------------------
	--	fnIsLayerEnabled()
	-----------------------------------------------
	fn fnIsLayerEnabled idx = (
		local shdr = pteroShaderList.fnGetSubShaderData shaderType subShaderType
		local ret = findItem shdr.layers idx
		ret = if ret > 0 then true else false
		return ret
	)
	
	-----------------------------------------------
	--	fnEnableUserProps()
	-----------------------------------------------
	fn fnEnableUserProps idx tex_id state =
	(
--		format "%\t%\t%\n" idx state pteroLayerRolloutList[idx].name.name
		
		case pteroLayerRolloutList[idx].name.name of
		(
			"DTA_WATER": isWater = if state then tex_id else 0
			"DTA_GLASS": isGlass = if state then tex_id else 0
			"TEX_ENVIRONMENT": EnvType[tex_id] = if state then 1 else 0
		)
	)
	 	-----------------------------------------------
	--	fnIsRolloutActive()
	-----------------------------------------------
	fn fnIsRolloutActive label = (
		local ret = false
		local idx = fnRolloutIDXbyLabel label
		local tex_id

		if idx != 0 do (
--			local shdr = pteroShaderList.fnGetSubShaderData shaderType subShaderType
			tex_id = pteroLayerRolloutList[idx].tex_id

			if (findItem layerOrder tex_id) > 0 do ret = true
		)

		fnEnableUserProps idx tex_id ret 
		
		return ret
	)

	-----------------------------------------------
	--	fnShowUsedRollouts()
	-----------------------------------------------
	fn fnShowUsedRollouts newShader:true = 
	( --hideAll:false = (
--		format "%\n" pteroLayerRolloutList
		for n = 1 to pteroLayerRolloutList.count do
			if pteroLayerRolloutList[n].tex_id > 0 do
			(
				if newShader do
				(
					removeRollout pteroLayerRolloutList[n].name
				)
				if not newShader or newShader and (fnIsRolloutActive pteroLayerRolloutList[n].label) do
				(
					addRollout pteroLayerRolloutList[n].name
					pteroLayerRolloutList[(fnRolloutIDXbyTexID pteroLayerRolloutList[n].tex_id)].name.fnUpdateUI #all
				)
			)
	)

	-----------------------------------------------
	-- fnDoShowBitmap()
	-----------------------------------------------
	fn fnDoShowBitmap tex_id control state read = (
		local idx	= fnRolloutIDXbyTexID tex_id
		local cIDX	= fnControlIDXbyLabel control idx
		local controlID = 0
		
		case control of
		(
			#btnShowBitmap: controlID = 1
			#btnShowAlpha : controlID = 2
			#btnShowTransp: controlID = 3
		)
		if read then
		(
			-- set value to control
			if tex_id == whichShow[1] and whichShow[2] == controlID then
				pteroLayerRolloutList[idx].name.controls[cIDX].checked = true
			else
				if cIDX > 0 do pteroLayerRolloutList[idx].name.controls[cIDX].checked = false
		)
		else
		(
			-- if file doesn't exist exit
			if layerFilenameExist[tex_id] != 1 do (
				fnUtilizeTexture pteroLayerRolloutList[idx].tex_id control read:true
				return false
			)

			-- get value from control
			if state then (
				-- setup bitmapTexture(s) for viewport
				whichShow = [tex_id, controlID, 0]
				for n = 1 to pteroLayerRolloutList.count do
					if pteroLayerRolloutList[n].tex_id > 0 and (fnIsRolloutActive pteroLayerRolloutList[n].label) do (
						fnUtilizeTexture pteroLayerRolloutList[n].tex_id #btnShowBitmap read:true
						fnUtilizeTexture pteroLayerRolloutList[n].tex_id #btnShowAlpha read:true
						fnUtilizeTexture pteroLayerRolloutList[n].tex_id #btnShowTransp read:true
					)
				fnUtilizeViewportBitmap tex_id #create
  			) else
				whichShow = [0,0,0] --.setup 0 #none
		)

		-- if there is nothing to show clear all data
		if whichShow[2] == 0 and delegate != undefined and delegate.diffuseMap != undefined do
			fnUtilizeViewportBitmap whichShow[1] #delete
	)
	
	-----------------------------------------------
	-- fnUtilizeTexture()
	-----------------------------------------------
	fn fnUtilizeTexture tex_id control state:undefined read:false = (
		local idx	= fnRolloutIDXbyTexID tex_id
		local cIDX	= fnControlIDXbyLabel control idx

		case control of (
			#itgBitmap :	if read then
								fnDoThumb tex_id #small control:pteroLayerRolloutList[idx].name.controls[cIDX]
							else 
								fnDoThumb tex_id #big
			#btnMipmap :	if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerMipmap[tex_id]
							else
								layerMipmap[tex_id] = state
/*			#btnCrop :		if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerCrop[tex_id]
							else
								layerCrop[tex_id] = state
*/			#btnTexMove :	if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerMove[tex_id]
							else
								layerMove[tex_id] = state
			#btnTileU :		if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerTileU[tex_id]
							else
								layerTileU[tex_id] = state
			#btnTileV :		if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerTileV[tex_id]
							else
								layerTileV[tex_id] = state
			#spnTilingU :	if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = layerTilingU[tex_id]
							else
								layerTilingU[tex_id] = state
			#spnTilingV :	if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = layerTilingV[tex_id]
							else
								layerTilingV[tex_id] = state
			#spnChannel :	if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = layerChannel[tex_id]
							else
								layerChannel[tex_id] = state
			#btnExtend :	if not read then
								fnExtendedProps tex_id this
			#btnFilename :	if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].text = fnShowFileDetails tex_id #name
							else
								fnSelectBitmap tex_id
			#lblPath :		if read do
								pteroLayerRolloutList[idx].name.controls[cIDX].text = fnShowFileDetails tex_id #path
			#lblSize :		if read do
								pteroLayerRolloutList[idx].name.controls[cIDX].text = fnShowFileDetails tex_id #size
			#btnFindObject : if not read do 
								fnSelectMapObjects this layerFilename[tex_id]
			#BtnUndefine :	if not read do
								fnUndefineBitmap tex_id
			#btnReload : 	if not read do
								fnReloadBitmap tex_id
			#btnShowBitmap :	fnDoShowBitmap tex_id control state read
			#btnShowAlpha :		fnDoShowBitmap tex_id control state read
			#btnShowTransp :	fnDoShowBitmap tex_id control state read
			#btnOverlay : if read then
							(
--								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerOverlayMultitex
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = if OverlayMultitex[tex_id] == 0 then false else true
							)
							else
							(
--								layerOverlayMultitex = state
								OverlayMultitex[tex_id] = if state then 1 else 0
							)
			#btnApplyLight : if read then
							(
--								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerLMApplyLight
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = if LMApplyLight[tex_id] == 0 then false else true
							)
							else
							(
--								layerLMApplyLight = state
								LMApplyLight[tex_id] = if state then 1 else 0
							)
			#btnEnvType : if read then
							(
--								pteroLayerRolloutList[idx].name.controls[cIDX].checked = layerEnvType
								pteroLayerRolloutList[idx].name.controls[cIDX].checked = if EnvType[tex_id] == 0 then false else true
							)
							else
							(
--								layerEnvType = state
								EnvType[tex_id] = if state then 1 else 0
							)
			-- TEX_WATER
			#spnShiftX : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterShiftingXY[1]
							else
							(
								local temp = waterShiftingXY
								temp[1] = state
								waterShiftingXY = temp
							)
			#spnShiftY : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterShiftingXY[2]
							else
							(
								local temp = waterShiftingXY
								temp[2] = state
								waterShiftingXY = temp
							)
			#spnShiftU : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterShiftingUV[1]
							else
							(
								local temp = waterShiftingUV
								temp[1] = state
								waterShiftingUV = temp
							)
			#spnShiftV : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterShiftingUV[2]
							else
							(
								local temp = waterShiftingUV
								temp[2] = state
								waterShiftingUV = temp
							)
			#spnBlend : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterEnvBlend
							else
								waterEnvBlend = state

			#spnDiff1 : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterSharpness[1]
							else
							(
								local temp = waterSharpness
								temp[1] = state
								waterSharpness = temp
							)
			#spnDiff2 : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterSharpness[2]
							else
							(
								local temp = waterSharpness
								temp[2] = state
								waterSharpness = temp
							)
			#spnEnv : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterSharpness[3]
							else
							(
								local temp = waterSharpness
								temp[3] = state
								waterSharpness = temp
							)
			#spnAngle : if read then
								pteroLayerRolloutList[idx].name.controls[cIDX].value = waterAlphaAngle
							else
								waterAlphaAngle = state
		)
		if not read do
			fnUtilizeViewportBitmap tex_id control
	)

	---------------------------------------------------------------
	-- rollout MaxMatRollout
	---------------------------------------------------------------
	rollout MaxMatRollout "Standard Material Properties" rolledUp:true (
		-- rollout locals
		local _name
		local _label

		-- init GUI
		GroupBox	grp1	"Color"	pos:[6,2] width:122 height:96
			label		lbl1				"Ambient:"				pos:[16,19] width:50 height:16
			colorPicker	pckAmbient			""						pos:[66,18] width:32 height:16 fieldWidth:30
			label		lbl2				"Diffuse:"				pos:[16,36] width:50 height:16
			colorPicker	pckDiffuse			""						pos:[66,35] width:32 height:16 color:(color 0 0 155) fieldWidth:30
			button		btnRandom			"c"						pos:[102,35] width:16 height:16 toolTip:"Set random color"
			label		lbl3				"Specular:"				pos:[16,53] width:50 height:16
			colorPicker	pckSpecular			""						pos:[66,52] width:32 height:16 color:(color 0 0 155) fieldWidth:30
			label		lbl4				"Self-Illum.:"			pos:[16,75] width:50 height:16
			colorPicker	pckSelfIllum		""						pos:[66,74] width:32 height:16 color:(color 0 0 0) fieldWidth:30
		GroupBox	grp2	""		pos:[134,2] width:187 height:96
			spinner		spnOpacity			"Opacity:"				pos:[224,18] width:83 height:16 range:[0,100,100] type:#integer scale:1 fieldwidth:40
			spinner		spnOpacityFalloff	"Opacity Falloff:"		pos:[193,36] width:114 height:16 range:[0.0,100.0,100.0] type:#float scale:0.01 fieldwidth:40
			spinner		spnSpecLevel		"Specular Level:"		pos:[187,56] width:120 height:16 range:[0,999,999] type:#integer scale:1 fieldwidth:40
			spinner		spnGlossiness		"Glossiness:"			pos:[210,74] width:97 height:16 range:[0,100,100] type:#integer scale:1 fieldwidth:40
	
		-- Init RollOut
		fn fnName	= MaxMatRollout
		fn fnLabel	= "Standard Material Properties"
		fn fnUpdateUI = try (
			pckMAXcolor.color	= delegate.Diffuse_Color
			spnOpacity.value	= delegate.opacity
		) catch ()

		--	event handles
		on btnAbout		pressed do (PteroToolsTemp = #("PteroLayer Material", 0.7); fnAboutDialog())
		on btnRandom	pressed do (
			pckDiffuse.color = (random gray white)
			pckAmbient.color = pckDiffuse.color / 2.5
			pckSpecular.color = (color 229 229 229)
		)

		--	rollout open handle
		on MaxMatRollout open do (
			_name	= fnName()
			_label	= fnLabel()

			fnOpenRollOut _name
			fnUpdateUI()
		)

		--	rollout close handle
		on MaxMatRollout close do (
			local _name	= fnName()
			fnCloseRollOut _name
		)
	)

	---------------------------------------------------------------
	-- rollout roSurface
	---------------------------------------------------------------
	rollout roSurface "Surface Properties" (
		-- rollout locals
		local _name
		local _label

		-- init GUI
		label			lbl1		"Surface Type:"	pos:[6,11]		width:70	height:16
		dropdownList	drpSurface	""				pos:[75,8]		width:150		height:21	items:_tmpItems
		groupBox		grp1		"Types"			pos:[235,2]		width:85		height:60
		edittext		edtGrass	"Grass:"		pos:[250,18]	fieldwidth:23	height:16
		edittext		edtGrow		"Grow:"			pos:[252,38]	fieldwidth:23	height:16
		label			lbl2		"Note: Surface can be 1-sided only."	pos:[35,42]

		-- Init RollOut
		fn fnName	= roSurface
		fn fnLabel	= "Surface Properties"
		fn fnUpdateUI = (
			-- setup Surfaces list
			if _colMatTable[2] == undefined do _colMatTable = fnReturnColMats type:#ini
			if _colMatTable[2] == undefined do _colMatTable = fnLoadMats()

			drpSurface.items = _colMatTable
			for i = 1 to _colMatTable.count do
				 if (substring _colMatTable[i] 1 2) == surface do drpSurface.selection = i
			if drpSurface.selected == undefined do drpSurface.selection = 1
		)

		--	event handles
		on drpSurface	selected val	do surface = substring drpSurface.selected 1 2
		on edtGrass		changed val		do edtGrass.text = fnTrimString val	type:#last
		on edtGrow		changed val		do edtGrow.text  = fnTrimString val type:#last

		--	rollout open handle
		on roSurface open do (
			_name	= fnName()
			_label	= fnLabel()

			fnOpenRollOut _name
			fnUpdateUI()
		)

		--	rollout close handle
		on roSurface close do (
			local _name	= fnName()
			fnCloseRollOut _name
		)
	)

	--------------------------------------------------------
	--	rollout roLayers
	--------------------------------------------------------
	rollout roLayers "Shader Properties" (
		-- rollout locals
		local _name
		local _label

		-- init GUI
		label			lbl1				"Shader Type:"		pos:[6,11]		width:70	height:16
		dropdownList	drpShaderType		""					pos:[75,8]		width:150	height:21	items:_tmpItems
		label			lbl2				"Sh.Sub-Type:"		pos:[6,35]		width:70	height:16
		dropdownList	drpSubShaderType	""					pos:[75,32]		width:150	height:21	items:_tmpItems
		label			lbl3				"Transparency:"		pos:[6,59]		width:70	height:16
		dropdownList	drpTransparent		""					pos:[75,56]		width:150	height:21	items:_tmpItems
		groupBox		grp2				"Other"				pos:[235,2]		width:85	height:74
		checkbox		chk2Sided			"2-Sided"			pos:[245,18]	width:60	height:16
		checkbox		chkFaceted			"Faceted"			pos:[245,34]	width:60	height:16

		-- Init RollOut
		fn fnName	= roLayers
		fn fnLabel	= "Shader Properties"

		-- fnFillParams()
		fn fnDoShaderChange = (
			local shdr, tmp
			
			-- correct shader info
			tmp = drpShaderType.selected
			if tmp != undefined do shaderType = tmp
			tmp = drpSubShaderType.selected
			if tmp != undefined do subShaderType = tmp
			fnSaveINI ( "ShaderType" ) shaderType (fnReturnFilename #ini) _iniSect
			fnSaveINI ( "SubShaderType" ) subShaderType (fnReturnFilename #ini) _iniSect
			
			-- correct textures order info
			shdr = pteroShaderList.fnGetSubShaderData shaderType subShaderType
			if shdr == undefined do return false
			layerOrder = shdr.layers as array
			shaderFilename = shdr.filename

			fnShowUsedRollouts()
		)
		
		-- fnFillSubType()
		fn fnFillSubType = (
			local subShdArray = #()
			local shd = pteroShaderList.fnGetShaderData drpShaderType.selected
			local idx

			-- cancel operation if loading material and mEdit is open
			if shd == undefined do return false
			
			-- fill sub-shaders names to array
			for n = 1 to shd.count do
				append subShdArray shd[n].name 
			drpSubShaderType.items = subShdArray

			-- cancel operation if sub-shader list is empty
			if subShdArray.count == 0 do return false
			
			-- find selection			
			idx = fnFindString drpSubShaderType.items subShaderType
			drpSubShaderType.selection = if idx > 0 then idx else 1
			
			-- correct sub-shader info
			subShaderType = drpSubShaderType.selected
		)
		
		-- fnUpdateUI()
		fn fnUpdateUI = (
			local idx = fnFindString drpShaderType.items shaderType
			local shd

			-- check shader list			
			if pteroShaderList.list.count < 1 do pteroShaderList.fnUpdate()

			drpShaderType.selection = if idx > 0 then idx else 1
			
			-- fill sub-shader dropdown list
			fnFillSubType()
			
			-- correct shader info
			if shaderType	 == ""	do shaderType	 = drpShaderType.selected
			if subShaderType == ""	do subShaderType = drpSubShaderType.selected

			shd = pteroShaderList.fnGetSubShaderData shaderType subShaderType
			if shd == undefined do
			(
				shd = fnGetBasicShader()
				shaderType = shd.name
				subShaderType = shd.subTypes[1].name
				shd = pteroShaderList.fnGetSubShaderData shaderType subShaderType
			)
			layerOrder = shd.layers as array
			shaderFilename = shd.filename
		)

		--	event handles
		on drpShaderType	selected val do (
			fnFillSubType()
			fnDoShaderChange()
		)
		on drpSubShaderType	selected val do (
			fnDoShaderChange()
		)

		--	rollout open handle
		on roLayers open do (
			local fTypes = fnReturnFileTypes()
			local ret, tmpPath

			_name	= fnName()
			_label	= fnLabel()

			drpShaderType.items = pteroShaderList.names
			drpTransparent.items = trnspArray

			for n in layerOrder do if layerFilename[n] != "" do
			(
				ret = findItem bitmapTable.fileNames (getFilenameFile layerFilename[n])
--				format "n: %\tfilename: %\tret: %\n" n (getFilenameFile layerFilename[n]) ret
				if ret > 0 then
				(
					layerFilename[n] = bitmapTable.filePaths[ret] + bitmapTable.fileNames[ret] + bitmapTable.fileTypes[ret]
--					format "layerFilename[%]: %\n" n layerFilename[n]
					layerFilenameExist[n] = 1
				)
				else
					layerFilenameExist[n] = 0
			)
			
			fnOpenRollOut _name
			fnUpdateUI()
		)

		--	rollout close handle
		on roLayers close do (
			local _name	 = fnName()
			fnCloseRollOut _name
		)
	)

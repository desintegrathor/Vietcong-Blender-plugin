-- TODO: matDialogSets
-- TOFO: PRM_IMPORT_MAT

-- TODO: opravit import - nacitani textur
-- TODO: opravit import - nacitani mipmap
-- TODO: reload bitmapy v diffuse a alpha, pokud ji nactu v instanci textury
-- TODO: nefunguje porad zobrazeni instance a mipmap mezi materialy !!!!!

---------------------------------------------------------------
--
-- PteroMat
--
-- by Pan Collette
--
-- Create: 20.12.2002
-- Modified: 29.10.2003
--
---------------------------------------------------------------

plugin material PteroMaterial
name:"PteroMat"
classID:#(0x654df3d2, 0x64da69d9)
extends:Standard replaceUI:true
version:2
(
	---------------------------------------------------------------
	-- plugin locals
	-------------------------------------------------------------
	local _isMax5			= false
	local _isGmax			= false
	local _isLibInstalled	= false
	local scriptPath		= fnReturnPath #ms --( GetDir #scripts ) + "\\pteroTools"
	local iconPath			= fnReturnPath #ico --( GetDir #scripts ) + "\\pteroTools"
	local iniPath			= fnReturnPath #ini
	local _logFile			= scriptPath + "\\!_listener_!.log"
	local _iniFile			= iniPath + "\\pteroCollette.ini"
	local _defFile			= iniPath + "\\pteroCollette.ini"
	local _iniSect			= "PteroMaterial"
	local _defSect			= "MaterialDefs"
	local tTypes			= #( "- none - (opaque)", "#0 - transparent, zbufwrite, sort", "#1 - transparent, zbufwrite, sort, 1-bit alpha", "#2 - translucent, no_zbufwrite, sort", "#3 - transparent, zbufwrite, nosort, 1-bit alpha", "#4 - translucent - add with background, no_zbufwrite, sort")
	local blankBmp			= bitmap 2 2 color:(color 210 255 255)
	local matDialogSets
	local _rollouts			= #()
	local whatUpdate		= ""

	---------------------------------------------------------------
	-- parameters MaxMatParams
	---------------------------------------------------------------
	parameters MaxMatParams rollout:MaxMatRollout (
		spinnerOpacity	type:#integer	ui:spinnerOpacity	default:100
		pickerMAXcolor	type:#color		ui:pickerMAXcolor
		checkFaceted	type:#boolean	ui:checkFaceted		default:false

		on spinnerOpacity set val do (
										delegate.opacity = val
										if ( b = getMTLMEditFlags this ) != matDialogSets do ()
										if val < 100 and (findItem b 2) == 0 do setMTLMEditFlags this (append b 2)
										if val == 100 and (findItem b 2) > 0 do setMTLMEditFlags this (deleteItem b 2)
									 )
		on pickerMAXcolor set val do (
										delegate.Diffuse_Color = val
										delegate.Ambient_Color = val / 2.5
										delegate.Specular_Color = (color 229 229 229)
									 )
		on checkFaceted   set val do delegate.faceted = val
	)

	---------------------------------------------------------------
	-- parameters VERSION_1.0_COMPATIBLE
 	---------------------------------------------------------------
	parameters paramMain rollout:roMain (
	)
	parameters paramDiffuse1 rollout:roDiffuse1 (
		prmUse1			type:#boolean	animatable:false	subanim:false	default:false
	)
	parameters paramDiffuse2 rollout:roDiffuse2 (
		prmUse2			type:#boolean	animatable:false	subanim:false	default:false
	)
	parameters paramDiffuse3 rollout:roDiffuse3 (
		prmUse3			type:#boolean	animatable:false	subanim:false	default:false
	)
	parameters paramDiffuse4 rollout:roDiffuse4 (
		prmUse4			type:#boolean	animatable:false	subanim:false	default:false
	)
	parameters paramEnvironment rollout:roEnvironment (
		prmUse5			type:#boolean	animatable:false	subanim:false	default:false
	)

	---------------------------------------------------------------
	-- parameters PTERO_MAT_PARAMS
 	---------------------------------------------------------------
	parameters PTERO_MAT_PARAMS (
		PRM_COLLISION_TYPE		type:#string		animatable:false	subanim:false	default:"- "
		PRM_TRANSPARENT_TYPE 	type:#string		animatable:false	subanim:false	default:"- "
		PRM_GROW_TYPE 			type:#string		animatable:false	subanim:false	default:""
		PRM_GRASS_TYPE 			type:#string		animatable:false	subanim:false	default:""
		PRM_ENVIRONMENT_TYPE	type:#integer		animatable:false	subanim:false	default:1
		PRM_DIFF2_TILE			type:#integer		animatable:false	subanim:false	default:1
		PRM_LIGHT				type:#boolean		animatable:false	subanim:false	default:false
		PRM_IMPORT_MAT			type:#boolean		animatable:false	subanim:false	default:false
		PRM_MIPMAP				type:#booltab		animatable:false	subanim:false	default:false	tabsize:24	tabsizevariable:false
		PRM_MIPMAP_OVERLAY		type:#boolean		animatable:false	subanim:false	default:false

		maps					type:#texturemaptab	animatable:false	subanim:false					tabsize:24	tabsizevariable:false
		matArray				type:#stringTab		animatable:false	subAnim:false					tabsize:1	tabsizevariable:true
		isShowing				type:#point3Tab		animatable:false	subAnim:false					tabsize:1	tabsizevariable:true
		mapIsUsed				type:#booltab		animatable:false	subanim:false	default:false	tabsize:24	tabsizevariable:false

		UseThumb				type:#boolean		animatable:false	subanim:false	default:true
	)


	---------------------------------------------------------------
	-- fnGetCreateData()
	---------------------------------------------------------------
	fn fnGetCreateData = (
		local _version = maxversion()

		try ( _isLibInstalled = fnLibInstalled() ) catch ( _isLibInstalled = false )
		if _version[2] >=  11 and _version[1] >= 5100 do _isMax5 = true
		if _version[2] >= 128 and _version[1] >= 4200 do _isMax5 = _isGmax = true

		if _isMax5 and _isLibInstalled do matArray = fnLoadMats()
	)

	---------------------------------------------------------------
	-- fnCloseRollOut()
	---------------------------------------------------------------
	fn fnCloseRollOut ro:undefined = (
		if ro == undefined then ( if _DEBUG_ do format "Error: PteroMat - fnCloseRollOut() - ro:%\n" ro; return false )
		try (
			fnSaveINI ( ro.name + "RolledUp" ) ( ( not ro.open ) as string ) _iniFile _iniSect
			return true
		) catch ( if _DEBUG_ do format "Error: PteroMat - fnCloseRollOut()\n"; return false )
	)

	---------------------------------------------------------------
	-- fnOpenRollOut()
	---------------------------------------------------------------
	fn fnOpenRollOut ro:undefined n:undefined = try (
		local tmp

		if ro == undefined then ( if _DEBUG_ do format "Error: PteroMat - fnOpenRollOut() - ro:%\n" ro; return false )
		if n == undefined then ( if _DEBUG_ do format "Error: PteroMat - fnOpenRollOut() - n:%\n" n; return false )

		_rollouts[n] = ro
		if isShowing[n] == undefined do isShowing[n] = [0.0, 0.0, 0.0]

		tmp = fnLoadINI ( ro.name + "RolledUp" ) _iniFile _iniSect

		case (fnUpcase tmp) of (
			"TRUE"	: ro.open = false
			default	: ro.open = true
		)

		return true
	) catch ( if _DEBUG_ do format "Error: PteroMat - fnOpenRollOut()\n"; fnCloseRollOut ro:ro; return false )

	---------------------------------------------------------------
	-- fnOpenBitmap()
	---------------------------------------------------------------
	fn fnOpenBitmap n:undefined f:undefined = try (
		local tName, newBitmap

		if (texCh = fnReturnTexChannel n:n) == undefined then ( if _DEBUG_ do format "Error: PteroMat - fnOpenBitmap() - n:%\n" n; return undefined )
		try( newBitmap	= openBitmap f ); catch( return undefined )

		tName = (getFilenameFile newBitmap.filename) + " #" + (random 1 9999) as string

		if delegate.maps[texCh] == undefined then (
			delegate.maps[texCh] = maps[texCh]		= bitmapTex bitmap:newBitmap filename:newBitmap.filename name:tName
			delegate.maps[texCh].jitter = 0
			delegate.maps[texCh].coordinates.mapChannel	= n
		) else (
			delegate.maps[texCh].bitmap				= newBitmap
			delegate.maps[texCh].filename			= newBitmap.filename
			delegate.maps[texCh].name				= tName
			delegate.maps[texCh].jitter				= 0
			maps[texCh]								= delegate.maps[texCh]
		)
		delegate.maps[texCh].monoOutput				= 0
		delegate.maps[texCh].RGBoutput				= 0
		delegate.maps[texCh].alphaSource			= 2
		gc()

		return delegate.maps[texCh]
 	) catch ( if _DEBUG_ do format "Error: PteroMat - fnOpenBitmap()\n"; return false )

	--------------------------------------------------------
	--	fnShowBitmap()
	--------------------------------------------------------
	fn fnShowBitmap n:undefined t:undefined s:false = try (
		local texCh, workMap
		local q			= #()
		local rgbOut	= 0
		local c			= if s then 1.0 else 0.0

		if (texCh = fnReturnTexChannel n:n) == undefined do ( if _DEBUG_ do format "Error: PteroMat - fnShowBitmap() - n:%\n" n; return false )

		workMap	= delegate.maps[texCh]

		for i = 1 to _rollouts.count do
			if _rollouts[i] != undefined do	(
				for j = 1 to 3 do
					q[j] = if (i==n) and (j==t) then c else 0.0
				isShowing[i]	= [q[1], q[2], q[3]]
			)

		delegate.opacityMap	= if s and t == 3 then copy workMap else undefined
		delegate.diffuseMap	= if s then copy workMap else undefined
		delegate.filterMap	= if s and t == 3 then delegate.diffuseMap else undefined

		if s then	(
			delegate.diffuseMap.RGBoutput				= 0
			delegate.diffuseMap.coordinates.mapping		= 0
			delegate.diffuseMap.coordinates.u_tiling	= delegate.diffuseMap.coordinates.v_tiling = if n != 2 then 1 else PRM_DIFF2_TILE
			case t of (
				1	: 	(
							delegate.diffuseMap.coordinates.mappingType	= if n == 5 then 1 else 0
						)
				2	:	(
							delegate.diffuseMap.RGBoutput	= 1
						)
				3	:	(
							delegate.opacityMap.monoOutput	= 1
							delegate.opacityMap.alphaSource	= 0
							delegate.opacityMap.coordinates.u_tiling = delegate.opacityMap.coordinates.v_tiling = if not n == 2 then 1 else PRM_DIFF2_TILE
						)
				default	: ( if _DEBUG_ do format "Error: PteroMat - fnShowBitmap() - t:%\n" t; return false )
			)
			this.showInViewport = true
		)
		else
			this.showInViewport = false

		return true
 	) catch ( if _DEBUG_ do format "Error: PteroMat - fnShowBitmap()\n"; return false )

	---------------------------------------------------------------
	--	fnUpdateUI()
	---------------------------------------------------------------
	fn fnUpdateUI n = try (
		local texCh, workMap, tempName, c
		local fTypes	= fnReturnFileTypes() --#( ".dds", ".bmp", ".tga", ".ifl" )
		local isTGA		= false
		local notFound	= false
		local bitmapTxt	= "none"
		local sizeTxt	= "Size: "
		local pathTxt	= "Path: "
		local iMax		= try (_rollouts[n].controls.count) catch ( if _DEBUG_ do format "Error: PteroMat - fnUpdateUI() - iMax:%\n" undefined; return false )
		local i 		= 1

--		if not canUpdate do return true
		if n == 0 or n > 100 do return true
		if (texCh = fnReturnTexChannel n:n) == undefined then ( if _DEBUG_ do format "Error: PteroMat - fnUpdateUI() - n:%\n" n; return false )

		if (workMap = delegate.maps[texCh]) != undefined do (
			if (fnUpcase (getfilenametype workMap.filename)) == ".TGA" or (fnUpcase (getfilenametype workMap.filename)) == ".DDS" then
				isTGA = true
			else if isShowing[n].y == 1 or isShowing[n].z == 1 do ( -- isShowing
				isShowing[n] = [1, 0, 0]
				delegate.opacityMap = undefined
				workMap.RGBoutput	= 0
			)

			local fPath = getfilenamepath workMap.filename --fnUpDirectory ( getfilenamepath workMap.filename )
			local fName = (getfilenamefile workMap.filename) + (getfilenametype workMap.filename)

			if (tempName = (fnRecursiveSearch fPath fName fTypes type:#bitmap)) != undefined then
				if tempName != workMap.filename do workMap = (fnOpenBitmap n:n f:tempName)
			else
				notFound	= true
			pathTxt			= fnCutString s:(pathTxt + (getfilenamepath workMap.filename) as string) c:36
			bitmapTxt		= try ( fnCutString s:workMap.name c:30 ) catch ( fnCutString s:("NOT FOUND: " + workMap.name) c:30 )
			sizeTxt			= try ( fnCutString s:(sizeTxt + (workMap.bitmap.width as string) + " x " + (workMap.bitmap.height as string)) c:20 ) catch ( sizeTxt )
		)

		if whatUpdate != "" do (
			iMax = i = 0
			whatUpdate = fnUpcase whatUpdate
			for r in _rollouts[n].controls do
				if whatUpdate == ( fnUpcase r.name ) do c = r
		)

 		while i <= iMax do (
			if i > 0 do (
				c = _rollouts[n].controls[i]
				whatUpdate = fnUpcase c.name
			)

			case ( whatUpdate ) of (
				"BTNALPHA"		: (
									c.enabled	= if mapIsUsed[texCh] then isTGA else false
									if isShowing[n] == ([0,1,0]) then (
										c.checked = true
										if delegate.diffuseMap != undefined do
											if ( fnUpcase delegate.diffuseMap.filename ) != ( fnUpcase workMap.filename ) do
												fnShowBitmap n:n t:2 s:true
									) else (
										c.checked = false
									)
								  )
				"BTNBITMAP"		: (
									c.text		= bitmapTxt
								  )
				"BTNENVT1"		: (
									c.enabled	= mapIsUsed[texCh]
									c.checked	= if PRM_ENVIRONMENT_TYPE == 1 then true else false
								  )
				"BTNENVT2"		: (
									c.enabled	= mapIsUsed[texCh]
									c.checked	= if PRM_ENVIRONMENT_TYPE == 2 then true else false
								  )
				"BTNFINDOBJECT"	: (
									c.enabled	= mapIsUsed[texCh]
								  )
				"BTNINSTANCE"	: (
									--c.enabled	= mapIsUsed[texCh]
								  )
				"BTNLIGHT"		: (
									c.enabled	= mapIsUsed[texCh]
									c.checked	= PRM_LIGHT
								  )
				"BTNMIPMAP"		: (
--									format "fnUpdateUI: PRM_IMPORT_MAT: %\n" PRM_IMPORT_MAT
--									format "fnUpdateUI: PRM_MIPMAP[%]: %\n" texCh PRM_MIPMAP[texCh]
--									format "fnUpdateUI: workMap.output.bump_amount: %\n" workMap.output.bump_amount
									
									c.enabled	= mapIsUsed[texCh]
									if PRM_IMPORT_MAT then
									(
										c.checked = not PRM_MIPMAP[texCh]
										try ( workMap.output.bump_amount = if PRM_MIPMAP[texCh] then 0 else 1 ) catch ()
									)
									else
									(
										c.checked = try ( if workMap.output.bump_amount > 0.01 then true else false ) catch ( false )
										PRM_MIPMAP[texCh] = not c.checked
									)
								  )
				"BTNNONE"		: (
									if mapIsUsed[texCh] then
										c.enabled	= true
									else
										c.enabled	= if workMap != undefined then true else false
								  )
				"BTNOVERLAY"	: (
									c.enabled	= mapIsUsed[texCh]
									c.checked	= PRM_MIPMAP_OVERLAY
								  )
				"BTNRELOAD"		: (
									c.enabled	= mapIsUsed[texCh]
								  )
				"BTNSHOW"		: (
									c.enabled	= mapIsUsed[texCh]
									if isShowing[n] == ([1,0,0]) then (
										c.checked = true
										if delegate.diffuseMap != undefined do
											if ( fnUpcase delegate.diffuseMap.filename ) != ( fnUpcase workMap.filename ) do
												fnShowBitmap n:n t:1 s:true
									) else
										c.checked = false
								  )
				"BTNTILEU"		: (
									c.enabled	= mapIsUsed[texCh]
									c.checked	= try (workMap.coordinates.u_tile) catch (false)
								  )
				"BTNTILEV"		: (
									c.enabled	= mapIsUsed[texCh]
									c.checked	= try (workMap.coordinates.v_tile) catch (false)
								  )
				"BTNTRANSP"		: (
									c.enabled	= if mapIsUsed[texCh] then isTGA else false
									if isShowing[n] == ([0,0,1]) then (
										c.checked = true
										if delegate.diffuseMap != undefined do
											if ( fnUpcase delegate.diffuseMap.filename ) != ( fnUpcase workMap.filename ) do
												fnShowBitmap n:n t:3 s:true
									) else
										c.checked = false
								  )
				"CHKUSE"		: (
									c.checked	= mapIsUsed[texCh]
								  )
				"ITGBITMAP"		: (
									c.enabled	= mapIsUsed[texCh]
									c.tooltip	= try (workMap.filename) catch ("")
									c.opacity	= if c.enabled then 0.0 else 0.75
									if useThumb then
										c.bitmap = try ( fnScaleBitmap m:workMap.bitmap w:78 h:78 ) catch ( blankBmp )
									else
										c.bitmap = blankBmp
								  )
				"LBLPATH"		: (
									c.text		= pathTxt
								  )
				"LBLSIZE"		: (
									c.text		= sizeTxt
								  )
				"SPNCH"			: (
									c.enabled	= mapIsUsed[texCh]
									c.value		= try (workMap.coordinates.mapChannel) catch (n)
								  )
				"SPNTILE"		: (
									c.enabled	= mapIsUsed[texCh]
									c.value		= PRM_DIFF2_TILE
								  )
				default			: ( format "Unknown control: %\n" whatUpdate )
			)
			i += 1
		)
		whatUpdate	= ""
		return true
	) catch ( if _DEBUG_ do format "Error: PteroMat - fnUpdateUI()\n"; return false )

	---------------------------------------------------------------
	-- parameters UPDATE_PARAMS
 	---------------------------------------------------------------
	parameters UPDATE_PARAMS (
		whichUpdate				type:#integer		animatable:false	subanim:false	default:0
		canUpdate				type:#boolean		animatable:false	subanim:false	default:false

		on whichUpdate set n do
			if n != 0 and canUpdate do (
				fnUpdateUI n
				whichUpdate = 0
		)

		on canUpdate set val do
			if val do (
				local texCh
				for n = 1 to _rollouts.count do (
					if (texCh = fnReturnTexChannel n:n) != undefined do
						if  n < 100 and _rollouts[n] != undefined and delegate.maps[texCh] != undefined do
							whichUpdate = n
				)
				whichUpdate = 0
			)
	)

	---------------------------------------------------------------
	--	fnUpdateAll()
	---------------------------------------------------------------
	fn fnUpdateAll whatUpdate:"" = try (
		local texCh

		for n = 1 to _rollouts.count do
			if n < 100 and (texCh = fnReturnTexChannel n:n) != undefined and _rollouts[n] != undefined and delegate.maps[texCh] != undefined do
				case (classof whatUpdate) of (
					String:		whichUpdate = n
					Array:		for wu in whatUpdate do (
									whatUpdate	= wu
									whichUpdate = n
								)
					default:	(
									 if _DEBUG_ do format "Error: PteroMat - fnUpdateAll() - whatUpdate:%\n" whatUpdate
									 return false
								)
			)

		PRM_IMPORT_MAT	= false

		return true
	) catch ( return false )

	---------------------------------------------------------------
	--	fnUpdateMainRO()
	---------------------------------------------------------------
	fn fnUpdateMainRO = try (
		local n = 0
		local texCh
 		for i in _rollouts[103].controls do
			case (classOf i) of (
				CheckButtonControl: (
										n += 1 										if (texCh = fnReturnTexChannel n:n) == undefined do ( if _DEBUG_ do format "Error: PteroMat - fnUpdateMainRO() - n:%\n" n; return false )--fnUpdateMainRO(); return false )
										i.checked = mapIsUsed[texCh]
									)
				CheckBoxcontrol:	(
										i.checked = delegate.twosided
									)
 	) catch ( if _DEBUG_ do format "Error: PteroMat - fnUpdateMainRO()\n"; return false )

	--------------------------------------------------------
	--	fnCreateTexture()
	--------------------------------------------------------
	fn fnCreateTexture n:undefined s:true = try (
		local wMap, texCh, t
		if (texCh = fnReturnTexChannel n:n) == undefined do ( if _DEBUG_ do format "Error: PteroMat - fnCreateTexture() - n:%\n" n; return false )--fnUpdateMainRO(); return false )

		delegate.mapEnables[texCh]	= s
		mapIsUsed[texCh]			= s
		
		if s then (
			wMap = fnSelectBitmapDialog c:( if delegate.maps[texCh] == undefined then true else false )

			if not isShowing[n] == undefined do
				case isShowing[n] of (
					([1, 0, 0]):	fnShowBitmap n:n t:1 s:true
					([0, 1, 0]):	fnShowBitmap n:n t:2 s:true
					([0, 0, 1]):	fnShowBitmap n:n t:3 s:true
			)

			case wMap[1] of (
				1:	( -- instance
						delegate.maps[texCh] = maps[texCh] = wMap[2]
						delegate.maps[texCh].jitter = 0
						fnUpdateAll()
					)
				2:	( -- copy / create new
						delegate.maps[texCh] = maps[texCh] = undefined
						fnOpenBitmap n:n f:wMap[2]
						delegate.maps[texCh].jitter = 0
--						PRM_IMPORT_MAT	= true
						whichUpdate		= n
--						PRM_IMPORT_MAT	= false
					)
				3:	( -- into map
						fnOpenBitmap n:n f:wMap[2]
						delegate.maps[texCh].jitter = 0
						fnUpdateAll()
					)
				default: (
						if delegate.maps[texCh] == undefined do
						(
							delegate.mapEnables[texCh]	= false
							mapIsUsed[texCh]			= false
						)
						whichUpdate	= n
					)
			)
		) else (
			delegate.maps[texCh]	= maps[texCh] = undefined
			PRM_LIGHT				= false
			PRM_DIFF2_TILE			= 1
			PRM_MIPMAP[texCh]		= true
			PRM_ENVIRONMENT_TYPE	= 1
			PRM_MIPMAP_OVERLAY		= false

			if isShowing[n].x == 1 or isShowing[n].y == 1 or isShowing[n].z == 1 do fnShowBitmap n:n t:0 s:false
			if n == 5 do PRM_ENVIRONMENT_TYPE = 1
			whichUpdate	= n
		)

		fnUpdateMainRO()
		delegate.mapEnables[texCh] = if delegate.maps[texCh] == undefined then false else true

		return true
 	) catch ( if _DEBUG_ do format "Error: PteroMat - fnCreateTexture()\n"; return false )

	---------------------------------------------------------------
	--	fnUtilizeTexture()
	---------------------------------------------------------------
	fn fnUtilizeTexture n:undefined g:undefined s:undefined = try (
		local texCh, flag, workMap
		local _inst	= false
		local _x	= isShowing[n].x
		local _y	= isShowing[n].y
		local _z	= isShowing[n].z
		local ret	= false

		if (texCh = fnReturnTexChannel n:n) == undefined then ( if _DEBUG_ do format "Error: PteroMat - fnUtilizeTexture() - n:%\n" n; return false )

		fn fnError s:s = ( if _DEBUG_ do format "Error: PteroMat - fnUtilizeTexture() - s:%\n" s )

		if ( fnUpcase g ) == "CHKUSE" do
			if s == undefined then fnError() else
				if delegate.maps[texCh] == undefined then
					if not fnCreateTexture n:n do ( whichUpdate = n; return false )
				else
					delegate.mapEnables[texCh] = s

		workMap = delegate.maps[texCh]
		for m = 1 to maps.count do if not maps[m] == undefined do
			if workMap == maps[m] do
				for i = 1 to 3 do if not isShowing[i] == undefined do
					case isShowing[i] of (
						([1, 0, 0]): _inst = true
						([0, 1, 0]): _inst = true
						([0, 0, 1]): _inst = true
					)

		if workMap != undefined do if (getfiles workMap.filename).count == 1 do (
			ret = true
			case ( fnUpcase g ) of (
				"BTNALPHA"		: if s == undefined then fnError() else (
									fnShowBitmap n:n t:2 s:s
									fnUpdateAll whatUpdate:#("btnShow", "btnAlpha", "btnTransp")
								  )
				"BTNENVT1"		: (
									PRM_ENVIRONMENT_TYPE = 1
									whatUpdate	= "BTNENVT2"
									whichUpdate = n
								  )
				"BTNENVT2"		: (
									PRM_ENVIRONMENT_TYPE = 2
									whatUpdate	= "BTNENVT1"
									whichUpdate = n
								  )
				"BTNFINDOBJECT"	: (
									fnSelectMapObjects this workMap
								  )
/*				"BTNINSTANCE"	: (
									tempFile = copy workMap.filename
									workMap.jitter = 0
									workMap = maps[texCh] = undefined
									fnOpenBitmap n:n f:tempFile
									workMap.jitter = 0
								  )
*/
				"BTNLIGHT"		: if s == undefined then fnError() else (
									PRM_LIGHT = s
								  )
				"BTNMIPMAP"		: (
									PRM_MIPMAP[texCh] = not s
									workMap.output.bump_amount = if s then 1.0 else 0.01
									fnUpdateAll whatUpdate:g
								  )
				"BTNOVERLAY"	: if s == undefined then fnError() else (
									PRM_MIPMAP_OVERLAY = s
								  )
				"BTNRELOAD"		: (
									fnOpenBitmap n:n f:workMap.filename
									if _inst do (
										if isShowing[n].x == 1 do fnShowBitmap n:n t:1 s:true
										if isShowing[n].y == 1 do fnShowBitmap n:n t:2 s:true
										if isShowing[n].z == 1 do fnShowBitmap n:n t:3 s:true
									)
								  )
				"BTNSHOW"		: if s == undefined then fnError() else (
									fnShowBitmap n:n t:1 s:s
									fnUpdateAll whatUpdate:#("btnShow", "btnAlpha", "btnTransp")
								  )
				"BTNTILEU"		: if s == undefined then fnError() else ( 									workMap.coordinates.u_tile = s
									if _inst do (
										delegate.diffuseMap.coordinates.u_tile = s
										if  not delegate.opacityMap == undefined do delegate.opacityMap.coordinates.u_tile =s
									)
									fnUpdateAll whatUpdate:g
								  )
				"BTNTILEV"		: if s == undefined then fnError() else (
									workMap.coordinates.v_tile = s
									if _inst do (
										delegate.diffuseMap.coordinates.v_tile = s
										if  not delegate.opacityMap == undefined do delegate.opacityMap.coordinates.v_tile =s
									)
									fnUpdateAll whatUpdate:g
								  )
				"BTNTRANSP"		: if s == undefined then fnError() else (
									fnShowBitmap n:n t:3 s:s
									fnUpdateAll whatUpdate:#("btnShow", "btnAlpha", "btnTransp")
								  )
				"CHKUSE"		: (
									mapIsUsed[texCh] = s
									whichUpdate = n

									fnUpdateMainRO()
								  )
				"ITGBITMAP"		: (
									display workMap.bitmap
								  )
				"SPNCH"			: if s == undefined then fnError() else (
									workMap.coordinates.mapChannel = s
									if _inst do (
										delegate.diffuseMap.coordinates.mapChannel = s
										if  not delegate.opacityMap == undefined do delegate.opacityMap.mapChannel = s
									)
									fnUpdateAll whatUpdate:g
								  )
				"SPNTILE"		: if s == undefined then fnError() else (
									PRM_DIFF2_TILE = s
									workMap.coordinates.u_tiling = s
									workMap.coordinates.v_tiling = s
									if _x == 1 or _y == 1 or _z == 1 do (
										delegate.diffuseMap.coordinates.u_tiling = s
										delegate.diffuseMap.coordinates.v_tiling = s
										if not delegate.opacityMap == undefined do delegate.opacityMap.coordinates.u_tiling = delegate.opacityMap.coordinates.v_tiling = s
									)
								  )
				default			: (
									format "Unknown control: %\n" g
									ret = false
								  )
			)
		)

		return ret
 	) catch ( if _DEBUG_ do format "Error: PteroMat - fnUtilizeTexture()\n"; return false )

	---------------------------------------------------------------
	-- rollout MaxMatRollout
	---------------------------------------------------------------
	rollout MaxMatRollout "Standard Material Properties" rolledUp:true silentErrors:true (
			local _n = 101													-- NEZAPOMENOUT ZMENIT
			local _name

			colorPicker	pickerMAXcolor	"Material color:"				height:16	align:#left	across:4 enabled:true	fieldwidth:30
			button		buttonRandom	"c"					width:16	height:16	align:#center		 enabled:true	toolTip:"Set random color"
			spinner		spinnerOpacity	"Opacity:"						height:16	align:#right		 enabled:true	fieldwidth:30 range:[0,100,100] type:#integer scale:1
			checkbox	checkFaceted	"Faceted"			width:60	height:16	align:#right		 enabled:true

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on buttonRandom pressed do (
			pickerMAXcolor.color = random gray white
		)
		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on MaxMatRollout open do (											-- NEZAPOMENOUT ZMENIT
			_name = MaxMatRollout											-- NEZAPOMENOUT ZMENIT

	--		clearListener()

			if ( not _isMax5 ) or ( not _isLibInstalled ) do fnGetCreateData()

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			fnOpenRollOut ro:_name n:_n
		)
		on MaxMatRollout	close	do fnCloseRollOut ro:_name				-- NEZAPOMENOUT ZMENIT

	)

	---------------------------------------------------------------
	-- rollout roCollisions
	---------------------------------------------------------------
	rollout roCollisions "PteroCollisions Properties" rolledUp:true silentErrors:true (
			local _n = 102													-- NEZAPOMENOUT ZMENIT
			local b = #()
			local _name

			dropdownList	drpColMat		"Collision Material:"	height:32	width:265	items:#("- NEVYTVARET KOLIZE -")	align:#left					across:3
			button			btnBrowse		"..."					height:16	width:16							align:#right	offset:[83,20]			toolTip:"Find material database"
			button			btnReload		"r"						height:16	width:16							align:#right	offset:[0,20]				toolTip:"Reload material database"
			edittext		edtGrow			"Grow Type:"			height:16	width:80							align:#left		offset:[0,0]		across:2
			edittext		edtGrass		"Grass Type:"			height:16	width:80							align:#center	offset:[-70,0]

		fn fnPrepareMats = (
			b = #()
			for a in matArray do append b ( a as string )
			drpColMat.items	= if b[1] == "undefined" then #("- NEVYTVARET KOLIZE -") else b
			if drpColMat.selected == undefined do drpColMat.selection = 1
		)

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on drpColMat	selected val	do	PRM_COLLISION_TYPE	= substring drpColMat.selected 1 2
		on edtGrow		changed val		do	PRM_GROW_TYPE 		= edtGrow.text	= fnTrimString val
		on edtGrass		changed val		do	PRM_GRASS_TYPE		= edtGrass.text	= fnTrimString val
		on btnBrowse	pressed			do	(
												fnFindMatIni f:true
												matArray = fnLoadMats()
												fnPrepareMats()
											)
		on btnReload	pressed			do	(
												matArray = fnLoadMats()
												fnPrepareMats()
											)
		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roCollisions open do (											-- NEZAPOMENOUT ZMENIT
			_name = roCollisions											-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			fnPrepareMats()
			fnOpenRollOut ro:_name n:_n

			for i = 1 to matArray.count do --print matArray[i]
				 if (substring matArray[i] 1 2) == PRM_COLLISION_TYPE do drpColMat.selection = i
			edtGrow.text	= PRM_GROW_TYPE
			edtGrass.text	= PRM_GRASS_TYPE
		)
		on roCollisions	close do fnCloseRollOut ro:_name					-- NEZAPOMENOUT ZMENIT

	)

	--------------------------------------------------------
	--	rollout roMain
	--------------------------------------------------------
	rollout roMain "PteroMaterial Properties" rolledUp:true silentErrors:true (
			local _n = 103													-- NEZAPOMENOUT ZMENIT
			local _name

			group "Used textures" (
				checkbutton	chkUse1			"1"		offset:[0,0]		width:16	height:16	align:#left		highlightColor:(color 255 255 132)	across:5	toolTip:"Enable Diffuse #1 - Ground"
				checkbutton	chkUse2			"2"		offset:[-35,0]		width:16	height:16	align:#left		highlightColor:(color 255 255 132)			toolTip:"Enable Diffuse #2 - Multitexture"
				checkbutton	chkUse3			"3"		offset:[-70,0]		width:16	height:16	align:#left		highlightColor:(color 255 255 132)			toolTip:"Enable Diffuse #3 - Overlay"
				checkbutton	chkUse4			"L"		offset:[-105,0]		width:16	height:16	align:#left		highlightColor:(color 255 255 132)			toolTip:"Enable LightMap"
				checkbutton	chkUse5			"E"		offset:[-140,0]		width:16	height:16	align:#left		highlightColor:(color 255 255 132)			toolTip:"Enable Environment"
			)
			dropdownList	drpTransparent	"Type of transparent:"					height:32	align:#left		items:tTypes
			checkbox		chk2Sided		"2-Sided"								height:16	align:#right	checked:false offset:[0,-45]	--	across:2
--			checkbutton		chkUseThumb		"T"		pos:[295,26]		width:16	height:16		highlightColor:(color 132 255 255)			toolTip:"Show Thumbs"


		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on chkUse1			changed state	do ( _rollouts[1].open = state; fnUtilizeTexture n:1 g:"chkUse"	s:state )
		on chkUse2			changed state	do ( _rollouts[2].open = state; fnUtilizeTexture n:2 g:"chkUse"	s:state )
		on chkUse3			changed state	do ( _rollouts[3].open = state; fnUtilizeTexture n:3 g:"chkUse"	s:state )
		on chkUse4			changed state	do ( _rollouts[4].open = state; fnUtilizeTexture n:4 g:"chkUse"	s:state )
		on chkUse5			changed state	do ( _rollouts[5].open = state; fnUtilizeTexture n:5 g:"chkUse"	s:state )
		on chk2Sided		changed state	do delegate.twosided = state
--		on chkUseThumb		changed state	do ( for i = 1 to _rollouts.count do if _rollouts[i] != undefined do	fnUpdateUI i	 )
		on drpTransparent	selected val	do PRM_TRANSPARENT_TYPE = substring drpTransparent.selected 1 2

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roMain open do (													-- NEZAPOMENOUT ZMENIT
			_name = roMain													-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			for i = 1 to tTypes.count do
				 if (substring tTypes[i] 1 2) == PRM_TRANSPARENT_TYPE do drpTransparent.selection = i

			fnOpenRollOut ro:_name n:_n
			fnUpdateMainRO()
		)
		on roMain	close do fnCloseRollOut ro:_name						-- NEZAPOMENOUT ZMENIT
	)

	---------------------------------------------------------------
	--	rollout roDiffuse1
	---------------------------------------------------------------
	rollout roDiffuse1 "Diffuse #1 - Ground" rolledUp:true silentErrors:true (				-- NEZAPOMENOUT ZMENIT
			local _n = 1													-- NEZAPOMENOUT ZMENIT
			local _name

			imgTag		itgBitmap					offset:[-3,0]		width:78	height:78	style:#bmp_center							tooltip:"Pic"			bitmap:blankBmp	transparent:(color 210 255 255)
			checkbutton	chkUse				"E"		offset:[61,-82]		width:16	height:16	align:#center	across:5					toolTip:"Enable bitmap"	highlightColor:(color 255 255 132)
			checkbutton	btnMipmap			"M"		offset:[35,-82]		width:16	height:16	aligh:#center				enabled:false		toolTip:"Mipmap bitmap"
			checkbutton	btnTileU			"U"		offset:[9,-82]		width:16	height:16	align:#center				enabled:false		toolTip:"Tile U"
			checkbutton	btnTileV			"V"		offset:[-34,-82]	width:16	height:16	align:#center				enabled:false		toolTip:"Tile V"
			spinner		spnCh				"Ch:"	offset:[0,-82]		width:55	height:16	align:#right				enabled:false						range:[1,99,1] type:#integer scale:1 value:1
			button		btnInstance			"i"		offset:[41,0]		width:16	height:16	align:#center	across:3	enabled:false		toolTip:"Make Unigue"
			button		btnBitmap			"none"	offset:[83,0]		width:183	height:16	align:#right								toolTip:"Texture"
			button		btnFindObject		"f"		offset:[42,0]		width:16	height:16	aligh:#right				enabled:false		toolTip:"Find objects width this texture"
			button		btnNone				"u"		offset:[83,0]		width:16	height:16	align:#left		across:6	enabled:false		toolTip:"Undefine bitmap"
			button		btnReload			"r"		offset:[50,0]		width:16	height:16	align:#left					enabled:false		toolTip:"Reload bitmap"
			label		lblSize				"Size:"	offset:[60,2]		width:120	height:16	align:#center				enabled:false
			checkbutton	btnShow				"s"		offset:[66,0]		width:16	height:16	align:#right 				enabled:false		toolTip:"Show bitmap in viewport"
			checkbutton	btnAlpha			"a"		offset:[33,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show alpha channel in viewport"
			checkbutton	btnTransp			"t"		offset:[0,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show transparent bitmap in viewport"
			label		lblPath				"Path:"	offset:[83,0]		width:217	height:16	align:#left					enabled:false

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on itgBitmap		click			do fnUtilizeTexture n:_n g:"itgBitmap"
		on chkUse			changed state	do fnUtilizeTexture n:_n g:"chkUse"			s:state
		on btnMipmap		changed state	do fnUtilizeTexture n:_n g:"btnMipmap"		s:state
		on btnTileU			changed state	do fnUtilizeTexture n:_n g:"btnTileU"		s:state
		on btnTileV			changed state	do fnUtilizeTexture n:_n g:"btnTileV"		s:state
		on spnCh			changed	value	do fnUtilizeTexture n:_n g:"spnCh"			s:value
		on btnInstance		pressed			do fnUtilizeTexture n:_n g:"btnInstance"
		on btnFindObject	pressed			do fnUtilizeTexture n:_n g:"btnFindObject"
		on btnReload		pressed			do fnUtilizeTexture n:_n g:"btnReload"
		on btnShow			changed	state	do fnUtilizeTexture n:_n g:"btnShow"		s:state --fnShowBitmap n:_n t:1 s:state
		on btnAlpha			changed	state	do fnUtilizeTexture n:_n g:"btnAlpha"		s:state --fnShowBitmap n:_n t:2 s:state
		on btnTransp		changed	state	do fnUtilizeTexture n:_n g:"btnTransp"		s:state --fnShowBitmap n:_n t:3 s:state
		on btnNone			pressed			do fnCreateTexture	n:_n 					s:false
		on btnBitmap		pressed			do fnCreateTexture	n:_n

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roDiffuse1 open do (												-- NEZAPOMENOUT ZMENIT
			_name = roDiffuse1												-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			fnOpenRollOut ro:_name n:_n
			whichUpdate = _n
		)
		on roDiffuse1	close	do fnCloseRollOut ro:_name					-- NEZAPOMENOUT ZMENIT
	)

	---------------------------------------------------------------
	--	rollout roDiffuse2
	---------------------------------------------------------------
	rollout roDiffuse2 "Diffuse #2 - Multitexture" rolledUp:true silentErrors:true (						-- NEZAPOMENOUT ZMENIT
			local _n = 2													-- NEZAPOMENOUT ZMENIT
			local _name

			imgTag		itgBitmap					offset:[-3,0]		width:78	height:78	style:#bmp_center							tooltip:"Pic"			bitmap:blankBmp	transparent:(color 210 255 255)
			checkbutton	chkUse				"E"		offset:[61,-82]		width:16	height:16	align:#center	across:5					toolTip:"Enable bitmap"	highlightColor:(color 255 255 132)
			checkbutton	btnMipmap			"M"		offset:[35,-82]		width:16	height:16	aligh:#center				enabled:false		toolTip:"Mipmap bitmap"
			checkbutton	btnTileU			"U"		offset:[9,-82]		width:16	height:16	align:#center				enabled:false		toolTip:"Tile U"
			checkbutton	btnTileV			"V"		offset:[-34,-82]	width:16	height:16	align:#center				enabled:false		toolTip:"Tile V"
			spinner		spnCh				"Ch:"	offset:[0,-82]		width:55	height:16	align:#right				enabled:false						range:[1,99,1] type:#integer scale:1 value:1
			button		btnInstance			"i"		offset:[41,0]		width:16	height:16	align:#center	across:3	enabled:false		toolTip:"Make Unigue"
			button		btnBitmap			"none"	offset:[83,0]		width:183	height:16	align:#right								toolTip:"Texture"
			button		btnFindObject		"f"		offset:[42,0]		width:16	height:16	aligh:#right				enabled:false		toolTip:"Find objects width this texture"
			button		btnNone				"u"		offset:[83,0]		width:16	height:16	align:#left		across:6	enabled:false		toolTip:"Undefine bitmap"
			button		btnReload			"r"		offset:[50,0]		width:16	height:16	align:#left					enabled:false		toolTip:"Reload bitmap"
			label		lblSize				"Size:"	offset:[60,2]		width:120	height:16	align:#center				enabled:false
			checkbutton	btnShow				"s"		offset:[66,0]		width:16	height:16	align:#right 				enabled:false		toolTip:"Show bitmap in viewport"
			checkbutton	btnAlpha			"a"		offset:[33,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show alpha channel in viewport"
			checkbutton	btnTransp			"t"		offset:[0,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show transparent bitmap in viewport"
			label		lblPath				"Path:"	offset:[83,0]		width:217	height:16	align:#left					enabled:false
			spinner		spnTile				"T:"	offset:[-60,-86]	width:40	height:16	align:#right				enabled:false						range:[1,999,1] type:#integer scale:1 value:1

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on itgBitmap		click			do fnUtilizeTexture n:_n g:"itgBitmap"
		on chkUse			changed state	do fnUtilizeTexture n:_n g:"chkUse"			s:state
		on btnMipmap		changed state	do fnUtilizeTexture n:_n g:"btnMipmap"		s:state
		on btnTileU			changed state	do fnUtilizeTexture n:_n g:"btnTileU"		s:state
		on btnTileV			changed state	do fnUtilizeTexture n:_n g:"btnTileV"		s:state
		on spnCh			changed	value	do fnUtilizeTexture n:_n g:"spnCh"			s:value
		on btnInstance		pressed			do fnUtilizeTexture n:_n g:"btnInstance"
		on btnFindObject	pressed			do fnUtilizeTexture n:_n g:"btnFindObject"
		on btnReload		pressed			do fnUtilizeTexture n:_n g:"btnReload"
		on spnTile			changed	value	do fnUtilizeTexture n:_n g:"spnTile"		s:value
		on btnShow			changed	state	do fnUtilizeTexture n:_n g:"btnShow"		s:state --fnShowBitmap n:_n t:1 s:state
		on btnAlpha			changed	state	do fnUtilizeTexture n:_n g:"btnAlpha"		s:state --fnShowBitmap n:_n t:2 s:state
		on btnTransp		changed	state	do fnUtilizeTexture n:_n g:"btnTransp"		s:state --fnShowBitmap n:_n t:3 s:state
		on btnNone			pressed			do fnCreateTexture	n:_n s:false
		on btnBitmap		pressed			do fnCreateTexture	n:_n

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roDiffuse2	open	do (											-- NEZAPOMENOUT ZMENIT
			_name = roDiffuse2													-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			spnTile.value = PRM_DIFF2_TILE

			fnOpenRollOut ro:_name n:_n
			whichUpdate = _n
		)
		on roDiffuse2	close	do fnCloseRollOut ro:_name						-- NEZAPOMENOUT ZMENIT
	)

	---------------------------------------------------------------
	--	rollout roDiffuse3
	---------------------------------------------------------------
	rollout roDiffuse3 "Diffuse #3 - Overlay" rolledUp:true silentErrors:true (								-- NEZAPOMENOUT ZMENIT
			local _n = 3													-- NEZAPOMENOUT ZMENIT
			local _name

			imgTag		itgBitmap					offset:[-3,0]		width:78	height:78	style:#bmp_center							tooltip:"Pic"			bitmap:blankBmp	transparent:(color 210 255 255)
			checkbutton	chkUse				"E"		offset:[66,-82]		width:16	height:16	align:#center	across:6					toolTip:"Enable bitmap"	highlightColor:(color 255 255 132)
			checkbutton	btnMipmap			"M"		offset:[50,-82]		width:16	height:16	aligh:#center				enabled:false		toolTip:"Mipmap bitmap"
			checkbutton	btnTileU			"U"		offset:[34,-82]		width:16	height:16	align:#center				enabled:false		toolTip:"Tile U"
			checkbutton	btnTileV			"V"		offset:[1,-82]		width:16	height:16	align:#center				enabled:false		toolTip:"Tile V"
			checkbutton	btnOverlay			"O"		offset:[-15,-82]	width:16	height:16	align:#center				enabled:false		toolTip:"Overlay Multitexture"
			spinner		spnCh				"Ch:"	offset:[0,-82]		width:55	height:16	align:#right				enabled:false						range:[1,99,1] type:#integer scale:1 value:1
			button		btnInstance			"i"		offset:[41,0]		width:16	height:16	align:#center	across:3	enabled:false		toolTip:"Make Unigue"
			button		btnBitmap			"none"	offset:[83,0]		width:183	height:16	align:#right								toolTip:"Texture"
			button		btnFindObject		"f"		offset:[42,0]		width:16	height:16	aligh:#right				enabled:false		toolTip:"Find objects width this texture"
			button		btnNone				"u"		offset:[83,0]		width:16	height:16	align:#left		across:6	enabled:false		toolTip:"Undefine bitmap"
			button		btnReload			"r"		offset:[50,0]		width:16	height:16	align:#left					enabled:false		toolTip:"Reload bitmap"
			label		lblSize				"Size:"	offset:[60,2]		width:120	height:16	align:#center				enabled:false
			checkbutton	btnShow				"s"		offset:[66,0]		width:16	height:16	align:#right 				enabled:false		toolTip:"Show bitmap in viewport"
			checkbutton	btnAlpha			"a"		offset:[33,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show alpha channel in viewport"
			checkbutton	btnTransp			"t"		offset:[0,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show transparent bitmap in viewport"
			label		lblPath				"Path:"	offset:[83,0]		width:217	height:16	align:#left					enabled:false

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on itgBitmap		click			do fnUtilizeTexture n:_n g:"itgBitmap"
		on chkUse			changed state	do fnUtilizeTexture n:_n g:"chkUse"			s:state
		on btnMipmap		changed state	do fnUtilizeTexture n:_n g:"btnMipmap"		s:state
		on btnTileU			changed state	do fnUtilizeTexture n:_n g:"btnTileU"		s:state
		on btnTileV			changed state	do fnUtilizeTexture n:_n g:"btnTileV"		s:state
		on spnCh			changed	value	do fnUtilizeTexture n:_n g:"spnCh"			s:value
		on btnInstance		pressed			do fnUtilizeTexture n:_n g:"btnInstance"
		on btnFindObject	pressed			do fnUtilizeTexture n:_n g:"btnFindObject"
		on btnReload		pressed			do fnUtilizeTexture n:_n g:"btnReload"
		on btnOverlay		changed state	do fnUtilizeTexture n:_n g:"btnOverlay"		s:state
		on btnShow			changed	state	do fnUtilizeTexture n:_n g:"btnShow"		s:state --fnShowBitmap n:_n t:1 s:state
		on btnAlpha			changed	state	do fnUtilizeTexture n:_n g:"btnAlpha"		s:state --fnShowBitmap n:_n t:2 s:state
		on btnTransp		changed	state	do fnUtilizeTexture n:_n g:"btnTransp"		s:state --fnShowBitmap n:_n t:3 s:state
		on btnNone			pressed			do fnCreateTexture	n:_n s:false
		on btnBitmap		pressed			do fnCreateTexture	n:_n

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roDiffuse3	open	do (											-- NEZAPOMENOUT ZMENIT
			_name = roDiffuse3													-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			fnOpenRollOut ro:_name n:_n
			whichUpdate = _n
		)
		on roDiffuse3	close	do fnCloseRollOut ro:_name						-- NEZAPOMENOUT ZMENIT
	)

	---------------------------------------------------------------
	--	rollout roDiffuse4
	---------------------------------------------------------------
	rollout roDiffuse4 "LightMap" rolledUp:true silentErrors:true (						-- NEZAPOMENOUT ZMENIT
			local _n = 4														-- NEZAPOMENOUT ZMENIT
			local _name

			imgTag		itgBitmap					offset:[-3,0]		width:78	height:78	style:#bmp_center							tooltip:"Pic"			bitmap:blankBmp	transparent:(color 210 255 255)
			checkbutton	chkUse				"E"		offset:[66,-82]		width:16	height:16	align:#center	across:6					toolTip:"Enable bitmap"	highlightColor:(color 255 255 132)
			checkbutton	btnMipmap			"M"		offset:[50,-82]		width:16	height:16	aligh:#center				enabled:false		toolTip:"Mipmap bitmap"
			checkbutton	btnTileU			"U"		offset:[34,-82]		width:16	height:16	align:#center				enabled:false		toolTip:"Tile U"
			checkbutton	btnTileV			"V"		offset:[1,-82]		width:16	height:16	align:#center				enabled:false		toolTip:"Tile V"
			checkbutton	btnLight			"L"		offset:[-14,-82]	width:16	height:16	align:#center				enabled:false		toolTip:"Apply Engine Lights"
			spinner		spnCh				"Ch:"	offset:[0,-82]		width:55	height:16	align:#right				enabled:false						range:[1,99,1] type:#integer scale:1 value:1
			button		btnInstance			"i"		offset:[41,0]		width:16	height:16	align:#center	across:3	enabled:false		toolTip:"Make Unigue"
			button		btnBitmap			"none"	offset:[83,0]		width:183	height:16	align:#right								toolTip:"Texture"
			button		btnFindObject		"f"		offset:[42,0]		width:16	height:16	aligh:#right				enabled:false		toolTip:"Find objects width this texture"
			button		btnNone				"u"		offset:[83,0]		width:16	height:16	align:#left		across:6	enabled:false		toolTip:"Undefine bitmap"
			button		btnReload			"r"		offset:[50,0]		width:16	height:16	align:#left					enabled:false		toolTip:"Reload bitmap"
			label		lblSize				"Size:"	offset:[60,2]		width:120	height:16	align:#center				enabled:false
			checkbutton	btnShow				"s"		offset:[66,0]		width:16	height:16	align:#right 				enabled:false		toolTip:"Show bitmap in viewport"
			checkbutton	btnAlpha			"a"		offset:[33,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show alpha channel in viewport"
			checkbutton	btnTransp			"t"		offset:[0,0]		width:16	height:16	align:#right				enabled:false		toolTip:"Show transparent bitmap in viewport"
			label		lblPath				"Path:"	offset:[83,0]		width:217	height:16	align:#left					enabled:false

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on itgBitmap		click			do fnUtilizeTexture n:_n g:"itgBitmap"
		on chkUse			changed state	do fnUtilizeTexture n:_n g:"chkUse"			s:state
		on btnMipmap		changed state	do fnUtilizeTexture n:_n g:"btnMipmap"		s:state
		on btnTileU			changed state	do fnUtilizeTexture n:_n g:"btnTileU"		s:state
		on btnTileV			changed state	do fnUtilizeTexture n:_n g:"btnTileV"		s:state
		on spnCh			changed	value	do fnUtilizeTexture n:_n g:"spnCh"			s:value
		on btnInstance		pressed			do fnUtilizeTexture n:_n g:"btnInstance"
		on btnFindObject	pressed			do fnUtilizeTexture n:_n g:"btnFindObject"
		on btnReload		pressed			do fnUtilizeTexture n:_n g:"btnReload"
		on btnLight			changed state	do fnUtilizeTexture n:_n g:"btnLight"		s:state
		on btnShow			changed	state	do fnUtilizeTexture n:_n g:"btnShow"		s:state --fnShowBitmap n:_n t:1 s:state
		on btnAlpha			changed	state	do fnUtilizeTexture n:_n g:"btnAlpha"		s:state --fnShowBitmap n:_n t:2 s:state
		on btnTransp		changed	state	do fnUtilizeTexture n:_n g:"btnTransp"		s:state --fnShowBitmap n:_n t:3 s:state
		on btnNone			pressed			do fnCreateTexture	n:_n s:false
		on btnBitmap		pressed			do fnCreateTexture	n:_n

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roDiffuse4	open	do (											-- NEZAPOMENOUT ZMENIT
			_name = roDiffuse4													-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			fnOpenRollOut ro:_name n:_n
			whichUpdate = _n
		)
		on roDiffuse4	close	do fnCloseRollOut ro:_name						-- NEZAPOMENOUT ZMENIT
	)

	---------------------------------------------------------------
	--	rollout Environment
	---------------------------------------------------------------
	rollout roEnvironment "Environment" rolledUp:true silentErrors:true (							-- NEZAPOMENOUT ZMENIT
			local _n = 5														-- NEZAPOMENOUT ZMENIT
			local _name

			imgTag		itgBitmap					offset:[-3,0]		width:78	height:78	style:#bmp_center							tooltip:"Pic"			bitmap:blankBmp	transparent:(color 210 255 255)
			checkbutton	chkUse				"E"		offset:[60,-82]		width:16	height:16	align:#center	across:5					toolTip:"Enable bitmap"	highlightColor:(color 255 255 132)
			checkbutton	btnMipmap			"M"		offset:[34,-82]		width:16	height:16	aligh:#center				enabled:false		toolTip:"Mipmap bitmap"
			checkbutton	btnEnvT1			"1"		offset:[10,-82]		width:16	height:16	aligh:#center				enabled:false		toolTip:"Change type of environment map to #1"
			checkbutton	btnEnvT2			"2"		offset:[-34,-82]	width:16	height:16	aligh:#center				enabled:false		toolTip:"Change type of environment map to #2"
			spinner		spnCh				"Ch:"	offset:[0,-82]		width:55	height:16	align:#right				enabled:false						range:[1,99,1] type:#integer scale:1 value:1
			button		btnInstance			"i"		offset:[41,0]		width:16	height:16	align:#center	across:3	enabled:false		toolTip:"Make Unigue"
			button		btnBitmap			"none"	offset:[83,0]		width:183	height:16	align:#right								toolTip:"Texture"
			button		btnFindObject		"f"		offset:[42,0]		width:16	height:16	aligh:#right				enabled:false		toolTip:"Find objects width this texture"
			button		btnNone				"u"		offset:[83,0]		width:16	height:16	align:#left		across:4	enabled:false		toolTip:"Undefine bitmap"
			button		btnReload			"r"		offset:[25,0]		width:16	height:16	align:#left					enabled:false		toolTip:"Reload bitmap"
			label		lblSize				"Size:"	offset:[0,2]		width:120	height:16	align:#center				enabled:false
			checkbutton	btnShow				"s"		offset:[0,0]		width:16	height:16	align:#right 				enabled:false		toolTip:"Show bitmap in viewport"
			label		lblPath				"Path:"	offset:[83,0]		width:217	height:16	align:#left					enabled:false

		--------------------------------------------------------
		--	event handles
		--------------------------------------------------------
		on itgBitmap		click			do fnUtilizeTexture n:_n g:"itgBitmap"
		on chkUse			changed state	do fnUtilizeTexture n:_n g:"chkUse"			s:state
		on btnMipmap		changed state	do fnUtilizeTexture n:_n g:"btnMipmap"		s:state
		on btnTileU			changed state	do fnUtilizeTexture n:_n g:"btnTileU"		s:state
		on btnTileV			changed state	do fnUtilizeTexture n:_n g:"btnTileV"		s:state
		on spnCh			changed	value	do fnUtilizeTexture n:_n g:"spnCh"			s:value
		on btnInstance		pressed			do fnUtilizeTexture n:_n g:"btnInstance"
		on btnFindObject	pressed			do fnUtilizeTexture n:_n g:"btnFindObject"
		on btnReload		pressed			do fnUtilizeTexture n:_n g:"btnReload"
		on btnEnvT1			changed state	do fnUtilizeTexture n:_n g:"btnEnvT1"
		on btnEnvT2			changed state	do fnUtilizeTexture n:_n g:"btnEnvT2"
		on btnShow			changed	state	do fnUtilizeTexture n:_n g:"btnShow"		s:state
		on btnNone			pressed			do fnCreateTexture	n:_n s:false
		on btnBitmap		pressed			do fnCreateTexture	n:_n

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on roEnvironment	open	do (										-- NEZAPOMENOUT ZMENIT
			_name = roEnvironment												-- NEZAPOMENOUT ZMENIT

			if ( not _isMax5 ) or ( not _isLibInstalled ) then (
				removeRollOut _name
				return false
			)

			fnOpenRollOut ro:_name n:_n
			whichUpdate = _n
		)
		on roEnvironment	close	do fnCloseRollOut ro:_name					-- NEZAPOMENOUT ZMENIT
	)


	-----------------------------------------------
	-- rollout FuckRollOut
	-----------------------------------------------
	rollout FuckRollOut "Version Error" rolledUp:false silentErrors:true (
		label lbl00 "" align:#center
		label lbl01 "! Wrong version !" align:#center
		label lbl02 "" align:#center
		label lbl03 "! SMUDLO !" align:#center
		label lbl05 "" align:#center

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on FuckRollOut open do (
			if _isMax5 do (
				removeRollOut FuckRollOut
				return false
			)
			if _isGmax then (
				lbl01.text = "Wrong version of Gmax."
				lbl03.text = "You need Gmax 1.2 or highter."
			) else (
				lbl01.text = "Wrong version of 3DS Max."
				lbl03.text = "You need 3DS Max 5.1 or highter."
			)
		)
	)

	-----------------------------------------------
	-- rollout FuckLibRollOut
	-----------------------------------------------
	rollout FuckLibRollOut "PteroLib Error" rolledUp:false silentErrors:true (
		label lbl00 "" align:#center
		label lbl01 "PteroLib is not installed." align:#center
		label lbl02 "" align:#center

		--------------------------------------------------------
		--	rollout open handle
		--------------------------------------------------------
		on FuckLibRollOut open do
			if _isLibInstalled then (
				removeRollOut FuckLibRollOut
				return false
			)
	)

	-----------------------------------------------
	-- rollout AboutRollOut
	-----------------------------------------------
	rollout AboutRollOut "About" rolledUp:true silentErrors:true (
		bitmap iconMap bitmap:(bitmap 144 80) align:#left across:2
		label lbl01 "PteroCollette Material" align:#right
		label lbl00 "" align:#right offset:[0,-40]
		label lbl03 "by Pan Collette" align:#right
		button btnPtero "www.pterodon.com" width:301 align:#center

 		---------------------------------------------------------------
		-- Event Handler
		---------------------------------------------------------------
		on btnPtero pressed do (
			assetBrowser.open()
			assetBrowser.gotoURL "http://www.pterodon.com/"
		)
		on AboutRollOut open do (
			local ver = "Version " + version as string + ".0"
			local _icon = iconPath + "\\PC_plugin.BMP"

			flag = (getfiles _icon).count
			case flag of (
				1:		iconMap.fileName = _icon
				default:	()
				)
			lbl00.text = ver

			canUpdate = true
		)

		on AboutRollOut close do (
			canUpdate = false
		)
	)

	--------------------------------------------------------
	--	plugin create handle
	--------------------------------------------------------
	on create do try (
		if _DEBUG_ do print "create in"
		matDelegate = delegate
		delegate.shaderByName = "Blinn"
		val = random gray white
		pickerMAXcolor = val
		for i = 1 to 24 do
			delegate.maps[i] = maps[i] = undefined
		if _DEBUG_ do print "create out"
	) catch ( if _DEBUG_ do format "Error: PteroMat - Create\n"; return false )

	--------------------------------------------------------
	--	plugin delete handle
	--------------------------------------------------------
	on delete do try (
		if _DEBUG_ do print "delete in"
	) catch ( if _DEBUG_ do format "Error: PteroMat - Delete\n"; return false )

	--------------------------------------------------------
	--	plugin load handle
	--------------------------------------------------------
	on load do try (
		if _DEBUG_ do print "load in"
		for n = 1 to 24 do
		(
--			format "n: %\n" n
--			try (format "maps[n].output.bump_amount: %\n" maps[n].output.bump_amount) catch ()
			try (PRM_MIPMAP[(fnReturnTexChannel n:n)] = if maps[(fnReturnTexChannel n:n)].output.bump_amount > 0.01 then false else true ) catch ( false )
		)
	) catch ( if _DEBUG_ do format "Error: PteroMat - Load\n"; return false )

	--------------------------------------------------------
	--	plugin update handle
	--------------------------------------------------------
	on update do try ( case version of (
		1:	(
				mapIsUsed[(fnReturnTexChannel n:1)] = prmUse1
				mapIsUsed[(fnReturnTexChannel n:2)] = prmUse2
				mapIsUsed[(fnReturnTexChannel n:3)] = prmUse3
				mapIsUsed[(fnReturnTexChannel n:4)] = prmUse4
				mapIsUsed[(fnReturnTexChannel n:5)] = prmUse5
			)
	) catch ( if _DEBUG_ do format "Error: PteroMat - Update\n"; return false )
)

-- EOF
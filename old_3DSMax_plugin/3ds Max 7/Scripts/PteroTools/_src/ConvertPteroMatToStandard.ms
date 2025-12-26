-------------------------------------------------------------------------
-- globals
-------------------------------------------------------------------------
global TexTable
global _dlgConvertPteroMatToStandart

-------------------------------------------------------------------------
-- fnCompareTextures
-------------------------------------------------------------------------
fn fnCompareTextures tex1 tex2 =
(
	if (classof tex1) != Bitmaptexture or
	   (classof tex2) != Bitmaptexture then return false
	else if tex1.filename				!= tex2.filename				then return false
	else if tex1.coordinates.mapChannel	!= tex2.coordinates.mapChannel	then return false
	else if tex1.coordinates.u_tiling	!= tex2.coordinates.u_tiling	then return false
	else if tex1.coordinates.v_tiling	!= tex2.coordinates.v_tiling	then return false
	else if tex1.coordinates.u_tile		!= tex2.coordinates.u_tile		then return false
	else if tex1.coordinates.v_tile		!= tex2.coordinates.v_tile		then return false
	else if tex1.alphaSource			!= tex2.alphaSource				then return false
	else if tex1.monoOutput				!= tex2.monoOutput				then return false
	else if tex1.RGBoutput				!= tex2.RGBoutput				then return false
	else if tex1.coordinates.mapping	!= tex2.coordinates.mapping		then return false
	
	return true
)

-------------------------------------------------------------------------
-- fnResetTextureParams
-------------------------------------------------------------------------
fn fnResetTextureParams tex type:#diff mat:undefined idx:undefined =
(
	if (tex == undefined) do return false
	
	case type of
	(
		#alpha:
		(
			tex.alphaSource			= 0
			tex.monoOutput			= 1
			tex.RGBoutput			= 1
		)
		default:
		(
			tex.alphaSource			= 2
			tex.monoOutput			= 0
			tex.RGBoutput			= 0
		)
	)
	tex.coordinates.mapping	= 0 
	
	if (mat != undefined) and (idx != undefined) do
	(
		tex.coordinates.u_tiling	= mat.layerTilingU[idx]
		tex.coordinates.v_tiling	= mat.layerTilingV[idx]
		tex.coordinates.u_tile		= mat.layerTileU[idx]
		tex.coordinates.v_tile		= mat.layerTileV[idx]
		tex.coordinates.mapChannel	= mat.layerChannel[idx]
	)

	local isSame = false
	for n = 1 to TexTable.count do
	(
		if (fnCompareTextures TexTable[n] tex) then
		(
--			format "%\t%\n" tex TexTable[n]
			tex = TexTable[n]
			isSame = true
			exit
		)
	)
	if not isSame do append TexTable tex
	
	return true
)

-------------------------------------------------------------------------
-- fnCreateMultiplyMap
-------------------------------------------------------------------------
fn fnCreateMultiplyMap map1 map2 mat:undefined idx:undefined =
(
	local mTex
	
	mTex = RGB_Multiply map1:map1 map2:map2
	
	fnResetTextureParams mTex.map2 mat:mat idx:idx
	
	mTex.map1Enabled = true
	mTex.map2Enabled = true
	mTex.alphaFrom	 = 0
	
	return mTex
)

-------------------------------------------------------------------------
-- fnCreateMaskMap
-------------------------------------------------------------------------
fn fnCreateMaskMap tex type:#diff2 mat:undefined idx:undefined =
(
	local mTex
	
	case type of
	(
		#diff3:
		(
			mTex = maskTex map:tex mask:(copy tex)
			mTex.maskInverted	= false
			fnResetTextureParams mTex.mask type:#alpha mat:mat idx:idx
		)
		default: -- #diff2
		(
			mTex = maskTex map:tex mask:tex
			mTex.maskInverted	= true
		)
	)

	fnResetTextureParams mTex.map mat:mat idx:idx

	mTex.mapEnabled		= true
	mTex.maskEnabled	= true

	return mTex
)

-------------------------------------------------------------------------
-- fnConvertPteroMatToStandard
-------------------------------------------------------------------------
fn fnConvertPteroMatToStandard pMat =
(
	if ((classof pMat) != pteroMaterial) do return undefined
	
	-- init locals
	local dTex	= undefined
	local dTex1	= undefined
	local dTex3	= undefined
	local oTex	= undefined
	local fTex	= undefined
	local diff1IDX = fnReturnTexChannel n:1
	local diff2IDX = fnReturnTexChannel n:2
	local diff3IDX = fnReturnTexChannel n:3

	-- create new material
	local sMat = copy pMat.delegate
	sMat.name		= pMat.name
	sMat.opacity	= 100
	sMat.faceted	= false
	sMat.SelfIllumColor	= (color 0 0 0)
	sMat.SpecularLevel	= 0
	sMat.glossiness		= 0
	
	-- remove old maps
	for n = 1 to 5 do sMat.maps[fnReturnTexChannel n:n] = undefined

	-- base map
	if (pMat.delegate.maps[diff1IDX] != undefined) and (pMat.mapIsUsed[diff1IDX]) then
	(
		dTex1 = copy pMat.delegate.maps[diff1IDX]
		fnResetTextureParams dTex1
	)
	else
	(
		dTex1 = RGB_Tint red:(color 255 0 0) green:(color 255 0 0) blue:(color 255 0 0)
	)

	-- overlay map
	if (pMat.delegate.maps[diff3IDX] != undefined) and (pMat.mapIsUsed[diff3IDX]) do
	(
		dTex3 = fnCreateMaskMap (copy pMat.delegate.maps[diff3IDX]) type:#diff3
--		dTex3.name = /*"diff3_" + */pMat.delegate.maps[diff3IDX].name
	)

	-- structure map
	if (pMat.delegate.maps[diff2IDX] != undefined) and (pMat.mapIsUsed[diff2IDX]) do
	(
		dTex1 = fnCreateMultiplyMap dTex1 (copy pMat.delegate.maps[diff2IDX])
		dTex1.name = "diff1_multiply"
--		dTex1.map2.name = /*"diff2_" + */pMat.delegate.maps[diff2IDX].name
		
		if (dTex3 != undefined) and (pMat.PRM_MIPMAP_OVERLAY == false) then
		(
			dTex3 = fnCreateMultiplyMap dTex3 dTex1.map2
			dTex3.name = "diff3_multiply"
		)
	)

	-- create diffuse map
	dTex = compositeTextureMap mapList:#(dTex1)
	if (dTex3 != undefined) then
	(
		dTex.mapList.count += 1
		dTex.mapList[dTex.mapList.count] = dTex3
	)

	-- create opacity and filter maps
	if (pMat.PRM_TRANSPARENT_TYPE != "- ") then
	(
		oTex = copy pMat.delegate.maps[diff1IDX]
--		oTex.name = /*"opacity_" + */pMat.delegate.maps[diff1IDX].name
		fnResetTextureParams oTex type:#alpha
--		oTex.output.invert	= true
		----
		fTex = pMat.delegate.maps[diff1IDX]
		fnResetTextureParams fTex
	)

	-- add maps to material
	sMat.diffuseMap	= dTex
	sMat.opacityMap	= oTex
	sMat.filterMap	= fTex

	sMat.showInViewport = pMat.showInViewport

	-- cleaning
	dTex	= undefined
	dTex1	= undefined
	dTex3	= undefined
	oTex	= undefined
	fTex	= undefined

	return sMat
)

-------------------------------------------------------------------------
-- fnConvertPteroLayerToStandard
-------------------------------------------------------------------------
fn fnConvertPteroLayerToStandard pMat =
(
	local pc = pMat.classid
	if (pc[1] != 1222670497) or (pc[2] != 782138873) do return undefined
	
	-- init locals
	local dTex	= undefined
	local dTex1	= undefined
	local dTex3	= undefined
	local oTex	= undefined
	local fTex	= undefined
	local bTex	= undefined
	local diff1IDX	= fnReturnTexID #TEX_DIFFUSE
	local diff2IDX	= fnReturnTexID #TEX_STRUCTURE
	local diff3IDX	= fnReturnTexID #TEX_OVERLAY
	local bumpIDX	= fnReturnTexID #TEX_BUMP
	local nMapIDX	= fnReturnTexID #TEX_NMAP
	
	-- create new material
	local sMat = standardMaterial name:pMat.name
	sMat.opacity = 100
	sMat.faceted = false
	sMat.adLock	 = false
	sMat.twoSided		= pMat.twoSided
	sMat.Diffuse_Color	= pMat.matDiffuse
	sMat.Ambient_Color	= pMat.matAmbient
	sMat.Specular_Color	= pMat.matSpecular
	sMat.SelfIllumColor	= pMat.matSelfIllum
	sMat.SpecularLevel	= pMat.matSpecLevel
	sMat.glossiness		= pMat.matGlossiness

	-- base map
	if (pMat.layerFilename[diff1IDX] != "") and (findItem pMat.layerOrder diff1IDX != 0) then
	(
		dTex1 = bitmaptexture filename:pMat.layerFilename[diff1IDX]
		dTex1.name = /*"diff1_" + */(getFilenameFile pMat.layerFilename[diff1IDX])
		fnResetTextureParams dTex1 mat:pMat idx:diff1IDX
	)
	else
	(
		dTex1 = RGB_Tint red:(color 255 0 0) green:(color 255 0 0) blue:(color 255 0 0)
	)

	-- overlay map
	if (pMat.layerFilename[diff3IDX] != "") and (findItem pMat.layerOrder diff3IDX != 0) then
	(
		dTex3 = fnCreateMaskMap (bitmaptexture filename:pMat.layerFilename[diff3IDX]) type:#diff3 mat:pMat idx:diff3IDX
		dTex3.name = /*"diff3_" + */(getFilenameFile pMat.layerFilename[diff3IDX])
	)

	-- structure map
	if (pMat.layerFilename[diff2IDX] != "") and (findItem pMat.layerOrder diff2IDX != 0) then
	(
		dTex1 = fnCreateMultiplyMap dTex1 (bitmaptexture filename:pMat.layerFilename[diff2IDX]) mat:pMat idx:diff2IDX
		dTex1.name = "diff1_multiply"
		dTex1.map2.name = /*"diff2_" + */(getFilenameFile pMat.layerFilename[diff2IDX])
		
		if (dTex3 != undefined) and (pMat.OverlayMultitex[diff3IDX] == 0) then
		(
			dTex3 = fnCreateMultiplyMap dTex3 dTex1.map2
			dTex3.name = "diff3_multiply"
		)
	)

	-- create diffuse map
	dTex = compositeTextureMap mapList:#(dTex1)
	if (dTex3 != undefined) then
	(
		dTex.mapList.count += 1
		dTex.mapList[dTex.mapList.count] = dTex3
	)

	-- create opacity and filter maps
	if (pMat.transparency > 1) then
	(
		oTex = bitmaptexture filename:pMat.layerFilename[diff1IDX]
		oTex.name = /*"opacity_" + */(getFilenameFile pMat.layerFilename[diff1IDX])
		fnResetTextureParams oTex type:#alpha
--		oTex.output.invert	= true
		----
		fTex = bitmaptexture filename:pMat.layerFilename[diff1IDX]
		fTex.name = /*"filter_" + */(getFilenameFile pMat.layerFilename[diff1IDX])
		fnResetTextureParams fTex mat:pMat idx:diff1IDX
	)

	-- bump map
	if (pMat.layerFilename[bumpIDX] != "") and (findItem pMat.layerOrder bumpIDX != 0) then
	(
		bTex = bitmaptexture filename:pMat.layerFilename[bumpIDX]
		bTex.name = /*"bump_" + */(getFilenameFile pMat.layerFilename[bumpIDX])
		fnResetTextureParams bTex mat:pMat idx:bumpIDX
	)
	
	-- normal map as bump map
	if (pMat.layerFilename[nMapIDX] != "") and (findItem pMat.layerOrder nMapIDX != 0) then
	(
		bTex = bitmaptexture filename:pMat.layerFilename[nMapIDX]
		bTex.name = /*"bump_" + */(getFilenameFile pMat.layerFilename[nMapIDX])
		fnResetTextureParams bTex mat:pMat idx:nMapIDX
		bTex = Normal_Bump normal_map:bTex
	)
	
	-- add maps to material
	sMat.diffuseMap	= dTex
	sMat.opacityMap	= oTex
	sMat.filterMap	= fTex
	sMat.bumpMap	= bTex
	
	sMat.showInViewport = pMat.showInViewport

	-- cleaning
	dTex	= undefined
	dTex1	= undefined
--	dTex2	= undefined
	dTex3	= undefined
	oTex	= undefined
	fTex	= undefined
	bTex	= undefined

	return sMat
)

-------------------------------------------------------------------------
-- fnOptimizeNewMats
-------------------------------------------------------------------------
fn fnOptimizeNewMats =
(
)

-------------------------------------------------------------------------
-- fnConvertOneMatToMax
-------------------------------------------------------------------------
fn fnConvertOneMatToMax mat =
(
	co = classof mat
	ci = mat.classid
	if (co == pteroMaterial) then
	(	-- process pteroMat
		mat = fnConvertPteroMatToStandard mat
	)
	else
	if (ci[1] == 1222670497) and (ci[2] == 782138873) then -- pteroLayer
	(	-- process pteroLayer
		mat = fnConvertPteroLayerToStandard mat
	)
	
	return mat
)

-------------------------------------------------------------------------
-- fnConvertMatsToMax
-------------------------------------------------------------------------
fn fnConvertMatsToMax matTable:undefined =
(
	local co, ci
	
	if matTable == undefined do return matTable
	
	if (classof matTable == Multimaterial) then
	(
		for m = 1 to matTable.materialList.count do
		(
			if (classof matTable.materialList[m] == Multimaterial) then
			(	-- continue processing multiMaterial
				matTable.materialList[m] = fnConvertMatsToMax matTable:matTable.materialList[m]
			)
			else
			(	-- process singleMat
				matTable.materialList[m] = fnConvertOneMatToMax matTable.materialList[m]
			)
		)
	)
	else
	(	-- process singleMat
--		format "IN:  %\n" matTable
		matTable = fnConvertOneMatToMax matTable
--		format "OUT: %\n" matTable
	)
	
	return matTable
)

-------------------------------------------------------------------------
-- dlgConvertPteroMatToStandart
-------------------------------------------------------------------------
rollout dlgConvertPteroMatToStandart "Material Twister" width:272 height:96
(
	local lTxt		= "Progress: "

	button btnAbout "?" pos:[248,8] width:16 height:16
	label lbl2 "" pos:[8,8] width:232 height:16
	label lbl1 "" pos:[8,24] width:232 height:16
	progressBar pb1 "" pos:[8,40] width:256 height:8
	progressBar pb2 "" pos:[8,48] width:256 height:8
	button btnOK "Close" pos:[8,64] width:256 height:24 --enabled:false
	
	on btnAbout pressed do
	(
		PteroToolsTemp = #("Material Twister", 1.0)
		fnAboutDialog()
	)
	on btnOK pressed do
	(
		destroyDialog dlgConvertPteroMatToStandart
	)
	on dlgConvertPteroMatToStandart open do
	(
		setFocus btnOK
	)
	on dlgConvertPteroMatToStandart close do
	(
		_dlgConvertPteroMatToStandart = undefined
	)
)

-------------------------------------------------------------------------
-- fnDoConvert
-------------------------------------------------------------------------
fn fnDoConvert =
(
	local matTable = #(#(), #())
	local progress = 0
	
	SetWaitCursor()

	if _dlgConvertPteroMatToStandart == undefined then
	(
		_dlgConvertPteroMatToStandart = createDialog dlgConvertPteroMatToStandart --modal:true
	)

	TexTable = #()
	
	with redraw off
	(
		-- convert materials
		for m = 1 to sceneMaterials.count do
		(
			progress = ((m as float / sceneMaterials.count as float) * 100) as integer
			if dlgConvertPteroMatToStandart.pb2.value != progress do
			(
				dlgConvertPteroMatToStandart.lbl2.text = "Processing materials ..."
				dlgConvertPteroMatToStandart.pb2.value = progress
			)
			dlgConvertPteroMatToStandart.lbl1.text = "Progress: " + m as string + " of " + sceneMaterials.count as string + " materials"
			append matTable[1] sceneMaterials[m]
			append matTable[2] (fnConvertMatsToMax matTable:sceneMaterials[m])
		)
		
		-- get selection or whole scene
		dlgConvertPteroMatToStandart.pb1.value = 100/3
		
		local sel = selection as array --$geometry
		if sel.count == 0 do sel = $geometry
		
		-- assign new materials to nodes
		for node = 1 to sel.count do
		(
			progress = ((node as float / sel.count as float) * 100) as integer
			if dlgConvertPteroMatToStandart.pb2.value != progress do
			(
				dlgConvertPteroMatToStandart.lbl2.text = "Processing geometry ..."
				dlgConvertPteroMatToStandart.pb2.value = progress
			)
			dlgConvertPteroMatToStandart.lbl1.text = "Progress: " + node as string + " of " + sel.count as string + " nodes"
			for n = 1 to matTable[1].count do
			(
				if (fnCompareMaterials sel[node].material matTable[1][n]) do
				(
	--				format "IN:  %\t%\n" node.material matTable[1][n]
					sel[node].material = matTable[2][n]
	--				format "OUT: %\t%\n" node.material matTable[2][n]
					exit
				)
			)
	--		format "%\n" n.name
	--		n.material = (fnConvertMatsToMax matTable:#(n.material))[1]
		)

		-- Cleaning	
		dlgConvertPteroMatToStandart.pb1.value = 100/3*2
		dlgConvertPteroMatToStandart.lbl2.text = "Cleaning ..."
		
--		print TexTable
		TexTable = undefined
		gc()

		-- Done		
		dlgConvertPteroMatToStandart.pb1.value = 100
		dlgConvertPteroMatToStandart.lbl2.text = "Done"
		dlgConvertPteroMatToStandart.lbl1.text = ""
--		dlgConvertPteroMatToStandart.btnOK.enabled = true
	)
		
	SetArrowCursor()
)


/*
TexTable = #()
meditmaterials[3] = fnConvertOneMatToMax meditmaterials[1]
$.material = meditmaterials[3]
*/
--fnConvertMatsToMax()
--fnDoConvert()

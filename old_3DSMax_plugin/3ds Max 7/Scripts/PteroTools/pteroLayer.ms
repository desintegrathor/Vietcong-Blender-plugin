-- todo: autorefresh if bitmap changed - upravit aby nepadal, pokud neni pteroLayer
-- todo: fix "used in materials" in pteroMap Browser

-- todo: save and load pressets for extended props
-- todo: add 2 textures mixing in viewport

---------------------------------------------------------------
--
-- PteroLayer
--
-- by Pan Collette
--
-- Create:		09.12.2003
-- Modified:	29.11.2004
--
---------------------------------------------------------------

---------------------------------------------------------------
-- PteroLayer Material bitmap database
---------------------------------------------------------------
struct _bitmapTable (
	fileNames = #(),
	fileTypes = #(),
	filePaths = #(),
	textures = #(),
	fn getIDX filename =
	(
		local tmp = getFilenameFile filename
		return (findItem fileNames tmp)
	), -- getIDX
	fn getTextureByIDX idx =
	(
		if idx == 0 do return undefined
		if textures[idx] == undefined do
		(
			local filename = filePaths[idx] + fileNames[idx] + fileTypes[idx]
			if (doesFileExist filename) then
				textures[idx] = (bitmapTexture filename:filename)
		)
		return textures[idx]
	), -- getTextureByIDX
	fn getTexture filename =
	(
		local idx = getIDX filename
		return (getTextureByIDX idx)
	), -- getTexture
	fn getBitmaps mat =
	(
		local ret = #()
		
		for f in mat.layerFilename do
			if f != undefined and f != "" do
				append ret f
		return ret
	), -- getBitmaps
	fn getMatBitmaps =
	(
		local ret = #()
		local tables = #()
		local c
		
		for n = 1 to meditMaterials.count do
			append tables meditMaterials[n]
		for n = 1 to sceneMaterials.count do
			append tables sceneMaterials[n]
		
		for m in tables do (
			if m == undefined do continue
			c = m.classid
			if c == undefined do continue
			--if Multimaterial
			if c[1] == 512 and c[2] == 0 then
			(
				for mm in m do
				(
					if mm == undefined do continue
					c = mm.classid
					if c == undefined do continue
					--if pteroLayer
--					if classof mm == pteroLayer do
					if c[1] == 1222670497 and c[2] == 782138873 do
						join ret (getBitmaps mm)
				)
			)
			-- if pteroLayer
			else if c[1] == 1222670497 and c[2] == 782138873 then
				join ret (getBitmaps m)
		)
		return ret
	), -- getMatBitmaps
	fn add filename =
	(
		local idx = getIDX filename
		
		if idx == 0 do try
		(
			local tmp = fnLoadINIexec "PrecacheBitmaps" (fnReturnFilename #ini) "General"
			if tmp == ok or tmp == undefined then tmp = true

			append fileNames (getFilenameFile filename)
			append fileTypes (getFilenameType filename)
			append filePaths (getFilenamePath filename)
			if tmp then
			(
				if (doesFileExist filename) then
					append textures (bitmapTexture filename:filename)
				else
					append textures undefined
			)
			else
				append textures undefined
			idx = filenames.count
		)
		catch
		(
			format "ERROR:\tNastala chyba pri pridavani textury do databaze pro pteroLayer material!!!\n\t\tHlaste ZADRovi.\n"
		)
		return idx
	), -- add
	fn delete filename =
	(
		local idx = getIDX filename
		local ret = false
		
		if idx != 0 do
		(
			deleteItem fileNames idx
			deleteItem fileTypes idx
			deleteItem filePaths idx
			deleteItem textures idx
			ret = true
		)
		return ret
	), -- delete
	fn reload filename =
	(
		local idx = getIDX filename
		local ret = false
		local map
		
		if idx != 0 do (
			map = copy (bitmapTexture filename:(fileNames[idx] + fileTypes[idx]))
			textures[idx] = map
			ret = true
		)
		return ret
	), -- reload
	fn refresh =
	(
		local sceneMaps = usedMaps()
		local n = 0
		local idx
		local fTypes = fnReturnFileTypes()
	
		setWaitCursor()
			
		-- append bitmaps from pteroLayer materials
		join sceneMaps (getMatBitmaps())
		
		-- check if bitmap exists in sceneMaps
		while (n += 1) <= filenames.count do
		(
			idx = findItem sceneMaps (filePaths[n] + fileNames[n] + fileTypes[n])
			if idx == 0 do
			(
				delete fileNames[n]
				n -= 1
			)
		)
		-- check if isn't new bitmap in usedMaps()
		for n = 1 to sceneMaps.count do
		(
			idx = findItem fileNames (getFilenameFile sceneMaps[n])
			if idx == 0 do
			(
				local newFile
				if not (doesFileExist sceneMaps[n]) then
				(
					pushPrompt ("Search for bitmap: " + (getFilenameFile sceneMaps[n]))
					newFile = fnRecursiveSearch (getFilenamePath sceneMaps[n]) (getFilenameFile sceneMaps[n]) fTypes type:#bitmap
--					format "%\t%\n" sceneMaps[n] newFile
					if newFile != undefined do sceneMaps[n] = newFile
				)
				else
					pushPrompt ("Update bitmap table: " + (getFilenameFile sceneMaps[n]))
				add sceneMaps[n]
				popPrompt()
			)
		)
		-- fix paths in usedMaps()
		sceneMaps = #()
		for mat in sceneMaterials do
			fnFillMapArray mat sceneMaps x:true
		for mat in meditMaterials do
			fnFillMapArray mat sceneMaps x:true

		for um in sceneMaps do
		(
			pushPrompt ("Fixing bitmap path: " + (getFilenameFile um.filename))
			local map = getTexture (getFilenameFile um.filename)
			if map != undefined and um.filename != map.filename do
			(
--				format "%\t%\n" um.filename map.filename
				um.filename = map.filename
			)
			popPrompt()
		)
		
		-- garbage collect
		sceneMaps = undefined
		fTypes = undefined
		gc()
		
		setArrowCursor()
	), -- refresh
	fn clear =
	(
		fileNames = #()
		fileTypes = #()
		filePaths = #()
		textures = #()
		gc()
		return true
	) -- clear
)
bitmapTable = _bitmapTable()

-----------------------------------------------
-- PteroLayer Material Extended Props
-----------------------------------------------
fn fnExtendedProps tex_id mat = (
	struct _thisMat (name, tex_id)
	global thisMat	= _thisMat mat tex_id --#(mat, tex_id)
	local pos		= mouse.screenpos
	local width		= 204 --208
	local height	= 88 --200
	local dPos		= [pos.x-width/2, pos.y-height/2]

	rollout roExtendedProps "Extended Properties" --width:204 height:146
	(
		-- init GUI
		groupBox		grp2			"TexMove"	pos:[8,4]		width:188		height:72
		radioButtons	rdoMove			""			pos:[16,20]		width:72		height:32	labels:#("Move", "Ping-Pong")	columns:1
		checkbox		chkSoft			"Soft"		pos:[35,52] 	fieldwidth:50	height:16
		spinner			spnDeltaU		"U:"		pos:[115,20]	fieldwidth:50	height:16	range:[-65535,65535,0]	scale:0.001
		spinner			spnDeltaV		"V:"		pos:[116,36]	fieldwidth:50	height:16	range:[-65535,65535,0]	scale:0.001
		spinner			spnTime			"Time:"		pos:[100,52]	fieldwidth:50	height:16	range:[0,65535,0]		scale:0.001

		-- event handles
		on spnClipU		changed val do (
			thisMat.name.layerClipUV[thisMat.tex_id] = [val, spnClipV.value, thisMat.tex_id]
			if val + spnClipW.value > 1 do (
				spnClipW.value = 1 - val
				thisMat.name.layerClipWH[thisMat.tex_id] = [spnClipW.value, spnClipH.value, thisMat.tex_id]
			)
		)
		on spnClipV		changed val do (
			thisMat.name.layerClipUV[thisMat.tex_id] = [spnClipU.value, val, thisMat.tex_id]
			if val + spnClipH.value > 1 do (
				spnClipH.value = 1 - val
				thisMat.name.layerClipWH[thisMat.tex_id] = [spnClipW.value, spnClipH.value, thisMat.tex_id]
			)
		)
		on spnClipW		changed val do (
			thisMat.name.layerClipWH[thisMat.tex_id] = [val, spnClipH.value, thisMat.tex_id]
			if val + spnClipU.value > 1 do (
				spnClipU.value = 1 - val
				thisMat.name.layerClipUV[thisMat.tex_id] = [spnClipU.value, spnClipV.value, thisMat.tex_id]
			)
		)
		on spnClipH		changed val do (
			thisMat.name.layerClipWH[thisMat.tex_id] = [spnClipW.value, val, thisMat.tex_id]
			if val + spnClipV.value > 1 do (
				spnClipV.value = 1 - val
				thisMat.name.layerClipUV[thisMat.tex_id] = [spnClipU.value, spnClipV.value, thisMat.tex_id]
			)
		)
		on rdoMove		changed val do thisMat.name.layerMoveType[thisMat.tex_id] = val
		on chkSoft		changed val do thisMat.name.layerMoveSoft[thisMat.tex_id] = val
		on spnDeltaU	changed val do thisMat.name.layerMoving[thisMat.tex_id] = [val, spnDeltaV.value, spnTime.value]
		on spnDeltaV	changed val do thisMat.name.layerMoving[thisMat.tex_id] = [spnDeltaU.value, val, spnTime.value]
		on spnTime		changed val do thisMat.name.layerMoving[thisMat.tex_id] = [spnDeltaU.value, spnDeltaV.value, val]

		on roExtendedProps open do (
			rdoMove.state	= thisMat.name.layerMoveType[thisMat.tex_id]
			chkSoft.checked	= thisMat.name.layerMoveSoft[thisMat.tex_id]
			spnDeltaU.value	= thisMat.name.layerMoving[thisMat.tex_id].x
			spnDeltaV.value	= thisMat.name.layerMoving[thisMat.tex_id].y
			spnTime.value	= thisMat.name.layerMoving[thisMat.tex_id].z
		)
	)

	createDialog roExtendedProps pos:dPos width:width height:height modal:true
)

---------------------------------------------------------------
-- PteroLayer Material callbacks
---------------------------------------------------------------
fn fnUpdatePteroLayer type:#normal =
(
	bitmapTable.refresh()
	medit.setActiveMtlSlot activeMeditSlot true
)
fn fnClearBitmapTable =
(
	bitmapTable.clear()
	freeSceneBitmaps()
)

callbacks.removeScripts id:#pteroBitmapTable
callbacks.addScript #filePostOpen		"fnUpdatePteroLayer type:#create" id:#pteroBitmapTable
callbacks.addScript #systemPostNew		"fnUpdatePteroLayer type:#create" id:#pteroBitmapTable
callbacks.addScript #systemPostReset	"fnClearBitmapTable type:#create" id:#pteroBitmapTable
callbacks.addScript #bitmapChanged		"fnUpdatePteroLayer()" id:#pteroBitmapTable
callbacks.addScript #filePreOpen		"fnClearBitmapTable" id:#pteroBitmapTable
callbacks.addScript #systemPreNew		"fnClearBitmapTable()" id:#pteroBitmapTable
callbacks.addScript #systemPreReset		"fnClearBitmapTable()" id:#pteroBitmapTable

---------------------------------------------------------------
-- PteroLayer Material Structures
---------------------------------------------------------------
struct _roListInfo	(name, label, tex_id)
--struct _whichShow	(tex_id, type, fn setup id tp = (tex_id = id; type = tp))

---------------------------------------------------------------
-- PteroLayer Material Globals
---------------------------------------------------------------
global pteroLayerRolloutList = #()
global _tmpItems	= #("                                                                                          ")
global trnspArray	= #( "- NONE - (opaque)", "#0 - transparent, zbufwrite, sort", "#1 - transparent, zbufwrite, sort, 1-bit alpha", "#2 - translucent, no_zbufwrite, sort", "#3 - transparent, zbufwrite, nosort, 1-bit alpha", "#4 - translucent - add with background, no_zbufwrite, sort")

---------------------------------------------------------------
-- PteroLayer Material Plugin
---------------------------------------------------------------
plugin material PteroLayer
name:"PteroLayer"
classID:#(0x48e078a1, 0x2e9e7df9)
extends:Standard
replaceUI:true
version:1
--autoPromoteDelegateProps:true
--silentErrors:true
(
	--------------------------------------------------------
	--	include plugin body
	--------------------------------------------------------
--	include "$scripts\\pteroTools\\pteroLayerBody.mse"
	include "$scripts\\pteroTools\\_src\\pteroLayerBody.ms"
	--------------------------------------------------------
	--	include rollouts
	--------------------------------------------------------
	include "$scripts\\pteroTools\\pteroLayer.ros"

	--------------------------------------------------------
	--	plugin create handle
	--------------------------------------------------------
	on create do (
		local val = random gray white
--		local shd
		local tmp

		-- read Collision materials
		if _colMatTable != undefined do (
			if _colMatTable[2] == undefined do _colMatTable = fnReturnColMats()
			if _colMatTable[2] == undefined do _colMatTable = fnLoadMats()
		)
		
		-- Prepare Shader List
		if pteroShaderList.list.count < 1 do pteroShaderList.fnUpdate()
--		shd = pteroShaderList.list
--		for n = 1 to shd.count do
--			append shdArray shd[n].name

		-- Load Last Shader State
		if (tmp = fnLoadINI "ShaderType" (fnReturnFilename #ini) _iniSect) == "" then
			shaderType = "" else shaderType = tmp
		if (tmp = fnLoadINI "SubShaderType" (fnReturnFilename #ini) _iniSect) == "" then
			subShaderType = "" else subShaderType = tmp

		if pteroShaderList.names.count == 0 do pteroShaderList.fnUpdate()
		if (pteroShaderList.fnGetSubShaderData shaderType subShaderType) == undefined do
		(
			local shd = fnGetBasicShader()
			shaderType = shd.name
			subShaderType = shd.subTypes[1].name
		)

		-- Append Rollouts to List
		if pteroLayerRolloutList.count < 1 do
		(
			fnAppendRollOut MaxMatRollout "Standard Material Properties"
			fnAppendRollOut roSurface "Surface Properties"
			fnAppendRollOut roLayers "Shader Properties"
			include "$scripts\\pteroTools\\pteroLayer.roa"
		)
		
		-- Setup Material
--		delegate.name = 
		delegate.shaderByName = "Blinn"
		delegate.UseSelfIllumColor = true
		matDiffuse	= val
		matAmbient	= val / 2.5
		matSpecular	= (color 229 229 229)
	)

	on load do
	(
		local shd

		-- read Collision materials
		if _colMatTable != undefined do (
			if _colMatTable[2] == undefined do _colMatTable = fnReturnColMats()
			if _colMatTable[2] == undefined do _colMatTable = fnLoadMats()
		)	
		
		-- Prepare Shader List
		if pteroShaderList.list.count < 1 do pteroShaderList.fnUpdate()
--		shd = pteroShaderList.list
--		for n = 1 to shd.count do
--			append shdArray shd[n].name

		-- Append Rollouts to List
		if pteroLayerRolloutList.count < 1 do
		(
			fnAppendRollOut MaxMatRollout "Standard Material Properties"
			fnAppendRollOut roSurface "Surface Properties"
			fnAppendRollOut roLayers "Shader Properties"
			include "$scripts\\pteroTools\\pteroLayer.roa"
		)
	)
)

-- EOF
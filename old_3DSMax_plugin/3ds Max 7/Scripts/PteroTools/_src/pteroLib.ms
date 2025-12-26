---------------------------------------------------------------
--
-- PteroLib
--
-- by Pan Collette
--
-- Create:		13.02.2003
-- Modified:	29.11.2004
--
---------------------------------------------------------------

global _CREATE_				= false

---------------------------------------------------------------
-- fucken activeX global info
global _activeXDoesntWork_ = false
rollout dlgAxTest "Testing ActiveX controls ..." width:0 height:0
(
	activeXControl	axcBmp			"MSComctlLib.ListViewCtrl" pos:[152,30] width:240 height:514  --TreeCtrl
	activeXControl	ilTv			"{2C247F23-8591-11D1-B16A-00C0F0283628}" height:0 width:0
)
try
(
	createDialog dlgAxTest pos:[0,0]
	destroyDialog dlgAxTest
	_activeXDoesntWork_ = false
)
catch
(
	_activeXDoesntWork_ = true
)
-- clean
dlgAxTest = undefined

---------------------------------------------------------------

--global iniPath				= ( GetDir #plugcfg )
--global _iniFile				= iniPath + "\\pteroCollette.ini"

global _isColMatListOpen	= false
global _colMatTable			= #()
global PteroToolsTemp		= #()
global fnPteroSettings
global fnAboutDialog
global fnReturnPath
global fnLoadINI
global fnSaveINI
global fnReturnFilename
global pteroMaterial

global bitmapTable

--global _PteroLayerRollouts	= #()

---------------------------------------------------------------
--	fnCheckNewScripts()
---------------------------------------------------------------
fn fnCheckNewScripts = (
	local fExists = doesFileExist "\\\\Zadr\\!OUT\\pteroScripts.ini"

	if not fExists do return false
	
	local iniPath = (getDir #plugcfg) + "\\pteroCollette.ini"
	local oldTime = fnLoadINI "LastUpdate" iniPath "General"
	local newTime = fnLoadINI "LastUpdate" "\\\\Zadr\\!OUT\\pteroScripts.ini" "General"
	
	if newTime == "" do return false
	
	rollout roNewScripts "pteroCollette info" width:392 height:208
	(
		bitmap bmp1 "Bitmap" pos:[8,8] width:144 height:80
		label lbl1 "" pos:[160,16] width:224 height:80
		label lbl2 "" pos:[8,100] width:376 height:60
		button btnOK "OK" pos:[312,176] width:72 height:24
		
		on btnOK pressed do destroyDialog roNewScripts
		on roNewScripts open do (
			local mainStr = fnLoadINI "MainString" "\\\\Zadr\\!OUT\\pteroScripts.ini" "General"
			local str	  = fnLoadINI "String" "\\\\Zadr\\!OUT\\pteroScripts.ini" "General"
			local splash  = fnReturnFilename #splash
	
			bmp1.filename = splash
			lbl2.text = mainStr + "\n\n" + str
			lbl1.text = "Vsechny scripty je mozne si pridat jako tlacitko do toolbary. V dialogu Customize User Interface, v zalozce Toolbars, si zmente Category na pteroTools. V seznamu se pak zobrazi vsechny nase scripty."
		)
	)
	
--	if str != "" do str = "\n\n" + str

	if fExists and oldTime != newTime do (
		fnSaveINI "LastUpdate" newTime iniPath "General"
		if oldTime != "" do (
			createDialog roNewScripts modal:true
			roNewScripts.controls[2].text = mainStr
			roNewScripts.controls[3].text = str
		)
	)
	return true
)

---------------------------------------------------------------
--	fnSaveNewScriptsEvent()
---------------------------------------------------------------
fn fnSaveNewScriptsEvent str:"" = (
	local mainStr = "Na VSS jsou nove scripty."
	local newTime = if (doesFileExist "F:\\!Shared\\!OUT\\pteroScripts.ini") then
		getFileModDate "F:\\!Shared\\!OUT\\pteroScripts.ini"
	else
		""
		
	fnSaveINI "LastUpdate"	newTime	"F:\\!Shared\\!OUT\\pteroScripts.ini" "General"
	fnSaveINI "MainString"	mainStr	"F:\\!Shared\\!OUT\\pteroScripts.ini" "General"
	fnSaveINI "String"		str		"F:\\!Shared\\!OUT\\pteroScripts.ini" "General"
)

---------------------------------------------------------------
--	fnEncrypt()
---------------------------------------------------------------
fn fnEncrypt = (
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroLib.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroMultiLayer.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroTools.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroMat.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroProps.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroLayer.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroLayerBody.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroLight.ms")catch()
	try(encryptscript "$scripts\\pteroTools\\_src\\pteroHelpers.ms")catch()
)

---------------------------------------------------------------
--	fnE2()
---------------------------------------------------------------
fn fnE2 str:"" = (
	fnEncrypt()
	fnSaveNewScriptsEvent str:str
)

---------------------------------------------------------------
--	fnLibInstalled()
---------------------------------------------------------------
fn fnLibInstalled = return true

---------------------------------------------------------------
--	fnChangeCase()
---------------------------------------------------------------
fn fnChangeCase s b:true = (--try (
	local upper, lower
	local outstring = copy s
	upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	lower = "abcdefghijklmnopqrstuvwxyz"

	for i=1 to outstring.count do (
		 j=findString (if b then upper else lower) outstring[i]
		if (j != undefined) do outstring[i]=(if b then upper[j] else lower[j])

	)

	return outstring
)-- catch ( format "Error: PteroLib - fnChangeCase()\n"; return false )

---------------------------------------------------------------
--	fnUpcase()
---------------------------------------------------------------
fn fnUpcase str = return (fnChangeCase str)

---------------------------------------------------------------
--	fnDncase()
---------------------------------------------------------------
fn fnDncase str = return (fnChangeCase str b:false)

-----------------------------------------------
-- fnFindControl()
-----------------------------------------------
fn fnFindControl controls controlName = (
	local idx = 0
	while (idx += 1) <= controls.count do
		try (if (controls[idx].name) as name == (controlName) as name do exit) catch ()
	if idx > controls.count do idx = 0
	return idx
)

-----------------------------------------------
-- fnFindString()
-----------------------------------------------
fn fnFindString strArray str = (
	local n = 0
	local ret = 0
	while (n += 1) <= strArray.count do (
		if (fnUpcase strArray[n]) == (fnUpcase str) do (
			ret = n
			exit
		)
	)
	return ret
)
	
---------------------------------------------------------------
--	fnReplaceString()
---------------------------------------------------------------
fn fnReplaceString target oldStr newStr = (
	local idx
	do (
		if (idx = findString target oldStr) == undefined do exit
		target = replace target idx oldStr.count newStr
	) while idx != 0
	return target
)

---------------------------------------------------------------
--	fnReplaceChars()
---------------------------------------------------------------
fn fnReplaceChars target chars str = (
	for c = 1 to chars.count do
		target = fnReplaceString target (subString chars c 1) str
	return target
)

---------------------------------------------------------------
--	fnCutString()
---------------------------------------------------------------
fn fnCutString s:"" c:0 length:0 = (--try (
	if (classof s) != String do return ""
	if c == 0 and length == 0 do return s

	local strLength	= s.count
	local realSize	= getTextExtent s
	local outstring	= copy s

	if length > 0 then
		if realSize.x > length do
			for n = 1 to strLength do (
				outstring = (substring s 1 (strLength / 2 - n )) + "..." + (substring s (strLength / 2 + n ) strLength)
				if (getTextExtent outstring).x <= length do exit
			)
	else
		if strLength > c do
			outstring = (substring s 1 (c / 2 - 2 )) + "..." + (substring s (strLength - c / 2 + 2 ) strLength)

	return outstring
)-- catch ( format "Error: PteroLib - fnCutString()\n"; return false )

---------------------------------------------------------------
--	fnTrimString()
---------------------------------------------------------------
fn fnTrimString val c:1 type:#first upcase:true dncase:false = (--try (
	if val == undefined do return ""
	if c > val.count do c = val.count
	if val.count > 1 do
		val = case type of (
			#first:		substring val 1 c
			#last:		substring val (val.count - c + 1) c
			#default:	""
		)
	if upcase do val = fnUpcase val
	if dncase do val = fnDncase val
	return val
)-- catch ( format "Error: PteroLib - fnTrimString()\n"; return false )

---------------------------------------------------------------
-- fnTrimRem()
---------------------------------------------------------------
fn fnTrimRem str idx = (
	local ret = #(str, idx)
	local subStr
	local n = 0
	
	while (n += 1) < ret[1].count do (
		subStr = subString ret[1] n 2
		case subStr of (
			"//" :	if n == 1 then ret[1] = ""
					else (
						ret[1] = subString ret[1] 1 (n - 1)
						n -= 1
					)
			"/*" :	if ret[2] == 0 do ret[2] = n
			"*/" :	(
						local tmp1 = if ret[2] < 2 then "" else subString ret[1] 1 (ret[2] - 1)
						local tmp2 = subString ret[1] (n + 2) (ret[1].count - n - 1)

						ret[1] = tmp1 + tmp2

						ret[2] = 0
						n = 0
					)
		)
	)
	
	if ret[2] == 1 do ret[1] = ""
	if ret[2] >= 2 do (
		ret[1] = subString ret[1] 1 (ret[2] - 1)
		ret[2] = 1
	)
		
	ret[1] = trimLeft ret[1]
	ret[1] = trimRight ret[1]
	
	return ret
)

---------------------------------------------------------------
-- fnUpDirectory()
---------------------------------------------------------------
fn fnUpDirectory dPath = (--try (
	local ret		= ""
	local pArray	= filterString dPath "\\"

	case pArray.count of (
		0 : ret = undefined
		1 : ret = pArray[1] + "\\"
		default : (
					deleteItem pArray pArray.count
					for n in pArray do ret += n + "\\"
				  )
	)

	return ret
)-- catch ( format "Error: PteroLib - fnUpDirectory()\n"; return undefined )

---------------------------------------------------------------
-- fnFindFile()
---------------------------------------------------------------
fn fnFindFile f fTypes = (--try (
	local ret	 = undefined
	local fPath  = getfilenamepath f
	local fName  = getfilenamefile f

--	if (getfiles f).count == 1 then	ret = f
	if (doesFileExist f) and not (getFileAttribute f #directory) then
	(
		ret = f
	)
	else for i in fTypes do
	(
		if (doesFileExist (fPath + fName + i)) and not (getFileAttribute (fPath + fName + i) #directory) do
			ret = fPath + fName + i
	)
--			if (getfiles (fPath + fName + i)).count == 1 then ret = fPath + fName + i
	
	return ret
)-- catch ( format "Error: PteroLib - fnFindFile()\n"; return undefined )

---------------------------------------------------------------
-- fnRecursiveSearch()
---------------------------------------------------------------
fn fnRecursiveSearch dMain fName fTypes type:#none = try (
	local iniPath	= fnReturnPath #ini 
	local _iniFile	= iniPath + "\\pteroCollette.ini"
	local ret		= undefined
	local dPath		= fnUpDirectory dMain
	local lPath		= fnUpDirectory maxFilePath
	local dArray	= #()

	if (subString dMain dMain.count 1) != "\\" do dMain += "\\"
	dArray = #(dMain)

	if dPath != dMain do append dArray dPath
	if maxFilePath != "" do append dArray maxFilePath
	if lPath != undefined and lPath != maxFilePath do append dArray lPath

--		format "fName: %\tdMain: %\t\n" fName dMain

	while ( ret == undefined ) and ( dArray.count > 0 ) do (
		local dTemp	= getDirectories ( dArray[1] + "*.*" )

		join dArray dTemp

		ret = fnFindFile ( dArray[1] + fName ) fTypes
		
--		format "%\t%\n" dArray[1] ret
		deleteItem dArray 1
	)

	-- search by type directory
	if ret == undefined do case type of
	(
		#bitmap :
		(
			dMain = fnLoadINI "TexturesPath" _iniFile "General"
			if dMain != "" do
				ret = fnRecursiveSearch dMain fName fTypes
		)
	)
--	format "ret: %\n" ret

	return ret
) catch ( format "Error: PteroLib - fnRecursiveSearch()\n"; return undefined )

-----------------------------------------------
-- fnReturnFileTypes()
-----------------------------------------------
fn fnReturnFileTypes = (
	return #(".dds", ".bmp", ".tga", ".ifl")
)

-----------------------------------------------
-- fnReturnPath()
-----------------------------------------------
fn fnReturnPath type = (
	local scriptsPath = GetDir #scripts
	local uiPath = getDir #ui
--	local iniPath	= fnReturnPath #ini 
	local _iniFile	= (getDir #plugcfg) + "\\pteroCollette.ini"
	local ret = case type of (
		#cfg : configPath
		#ico : scriptsPath + "\\pteroTools\\icon_bw"
		#ini : getDir #plugcfg
		#max : maxFilePath
		#mcr : uiPath + "\\MacroScripts"
		#ms  : scriptsPath + "\\pteroTools"
		#scn : getDir #scene
		#tex : fnLoadINI "TexturesPath" _iniFile "General"
		#model : fnLoadINI "ModelsPath" _iniFile "General"
		#engine : fnLoadINI "EnginePath" _iniFile "General"
		default : undefined
	)
	return ret
)

-----------------------------------------------
-- fnReturnFilename()
-----------------------------------------------
fn fnReturnFilename type = (
	local scriptPath	= fnReturnPath #ms --( GetDir #scripts ) + "\\pteroTools"
	local iconPath		= fnReturnPath #ico --( GetDir #scripts ) + "\\pteroTools\\icon_bw"
	local iniPath		= fnReturnPath #ini --( GetDir #plugcfg )
	local ret = case type of (
--		#scriptPath : scriptPath
		#log :		scriptPath + "\\!_listener_!.log"
		#ini :		iniPath + "\\pteroCollette.ini"
		#def :		iniPath + "\\pteroCollette.ini"
		#mat :		iniPath + "\\pteroColMat.ini"
		#iniLayer :	iniPath + "\\pteroLayer.ini"
		#splash :	iconPath + "\\PC_plugin.bmp"

		-- pteroProps icons		
		#lckIcon :	#( ( iconPath + "\\pin213i.bmp" ), ( iconPath + "\\pin213i.bmp" ), 4, 3, 2, 4, 1 )
		#lck2Icon :	#( ( iconPath + "\\pin13i.bmp" ), ( iconPath + "\\pin13i.bmp" ), 4, 3, 2, 4, 1 )
		#lck3Icon :	#( ( iconPath + "\\lck13i.bmp" ), ( iconPath + "\\lck13i.bmp" ), 4, 3, 2, 4, 1 )
		#showIcon :	#( ( iconPath + "\\show13i.bmp" ), ( iconPath + "\\show13i.bmp" ), 4, 3, 2, 4, 1 )
		#lay1Icon :	#( ( iconPath + "\\lay113i.bmp" ), ( iconPath + "\\lay113i.bmp" ), 4, 3, 2, 4, 1 )
		#dckLeft :	#( ( iconPath + "\\dock_l13i.bmp" ), ( iconPath + "\\dock_l13i.bmp" ), 4, 3, 2, 4, 1 )
		#dckRght :	#( ( iconPath + "\\dock_r13i.bmp" ), ( iconPath + "\\dock_r13i.bmp" ), 4, 3, 2, 4, 1 )
		#setIcon :	#( ( iconPath + "\\set13i.bmp" ), ( iconPath + "\\set13i.bmp" ), 4, 3, 2, 4, 1 )
		#defIcon :	#( ( iconPath + "\\def13i.bmp" ), ( iconPath + "\\def13i.bmp" ), 4, 3, 2, 4, 1 )
		#savIcon :	#( ( iconPath + "\\sav13i.bmp" ), ( iconPath + "\\sav13i.bmp" ), 4, 3, 2, 4, 1 )
		#delIcon :	#( ( iconPath + "\\del13i.bmp" ), ( iconPath + "\\del13i.bmp" ), 4, 3, 2, 4, 1 )
		#acqIcon :	#( ( iconPath + "\\acq13i.bmp" ), ( iconPath + "\\acq13i.bmp" ), 4, 3, 2, 4, 1 )
		#tpeIcon :	#( ( iconPath + "\\tpe13i.bmp" ), ( iconPath + "\\tpe13i.bmp" ), 4, 3, 2, 4, 1 )
		
		-- pteroLayer icons
		#plCrop :	#( ( iconPath + "\\pl_crop13.bmp" ), ( iconPath + "\\pl_crop13.bmp" ), 4, 3, 2, 4, 1 )
		#plDel :	#( ( iconPath + "\\pl_delete13.bmp" ), ( iconPath + "\\pl_delete13.bmp" ), 4, 3, 2, 4, 1 )
		#plFind :	#( ( iconPath + "\\pl_find13.bmp" ), ( iconPath + "\\pl_find13.bmp" ), 4, 3, 2, 4, 1 )
		#plMip :	#( ( iconPath + "\\pl_mipmap13.bmp" ), ( iconPath + "\\pl_mipmap13.bmp" ), 4, 3, 2, 4, 1 ) 
		#plMove :	#( ( iconPath + "\\pl_texMove13.bmp" ), ( iconPath + "\\pl_texMove13.bmp" ), 4, 3, 2, 4, 1 )
		#plReload :	#( ( iconPath + "\\pl_reload13.bmp" ), ( iconPath + "\\pl_reload13.bmp" ), 4, 3, 2, 4, 1 ) 
		#plSet :	#( ( iconPath + "\\pl_setup13.bmp" ), ( iconPath + "\\pl_setup13.bmp" ), 4, 3, 2, 4, 1 ) 
		#plShow1 :	#( ( iconPath + "\\pl_show113.bmp" ), ( iconPath + "\\pl_show113.bmp" ), 4, 3, 2, 4, 1 )
		#plShow2 :	#( ( iconPath + "\\pl_show213.bmp" ), ( iconPath + "\\pl_show213.bmp" ), 4, 3, 2, 4, 1 )
		#plShow3 :	#( ( iconPath + "\\pl_show313.bmp" ), ( iconPath + "\\pl_show313.bmp" ), 4, 3, 2, 4, 1 )
		#plOver :	#( ( iconPath + "\\pl_overlay13.bmp" ), ( iconPath + "\\pl_overlay13.bmp" ), 4, 3, 2, 4, 1 )
		#plLight :	#( ( iconPath + "\\pl_light13.bmp" ), ( iconPath + "\\pl_light13.bmp" ), 4, 3, 2, 4, 1 )
		#plEnvT :	#( ( iconPath + "\\pl_envtype13.bmp" ), ( iconPath + "\\pl_envtype13.bmp" ), 4, 3, 2, 4, 1 )
		
		default : undefined
	)
	return ret
)

---------------------------------------------------------------
-- fnSaveINI()
---------------------------------------------------------------
fn fnSaveINI key val _iniFile _iniSect = (--try (
	local res = setINISetting _iniFile _iniSect key val
	return res
)-- catch ( format "Error: PteroLib - fnSaveINI()\n"; return false )

---------------------------------------------------------------
-- fnLoadINI()
---------------------------------------------------------------
fn fnLoadINI _key _iniFile _iniSect = (--try (
	local val = getINISetting _iniFile _iniSect _key
	return val
)-- catch ( format "Error: PteroLib - fnLoadINI()\n"; return false )

---------------------------------------------------------------
-- fnLoadINIexec()
---------------------------------------------------------------
fn fnLoadINIexec _key _iniFile _iniSect = (--try (
	local val = execute ( getINISetting _iniFile _iniSect _key )
	return val
)-- catch ( format "Error: PteroLib - fnLoadINI()\n"; return false )

---------------------------------------------------------------
-- fnReturnStandardTexChannel()
---------------------------------------------------------------
fn fnReturnStandardTexChannel n:undefined = (--try (
	case n of (
		1: return 2		-- Old Diffuse #1
		2: return 12	-- Old Diffuse #2
		3: return 8		-- Old Diffuse #3
		4: return 13	-- Old LightMap
		5: return 10	-- Old Environment #1
		6: return 11	-- Old Environment #2
		default: return undefined
	)
)-- catch ( format "Error: PteroLib - fnReturnStandardTexChannel()\n"; return false )

---------------------------------------------------------------
-- fnReturnTexChannel()
---------------------------------------------------------------
fn fnReturnTexChannel n:undefined = (--try (
	case n of (
		1: return 13	-- Diffuse #1
		2: return 14	-- Diffuse #2
		3: return 15	-- Diffuse #3
		4: return 20	-- LightMap
		5: return 19	-- Environment
		default: return undefined
	)
)-- catch ( format "Error: PteroLib - fnReturnTexChannel()\n"; return false )

---------------------------------------------------------------
-- fnGetLayersDefinition()
---------------------------------------------------------------
struct _pteroLayerDefinition (name, label, texID, items)
global pteroLayerDefinition = #()
fn fnGetLayersDefinition = (
	local iniFile = (fnReturnFilename #iniLayer)
	local texArray = fnLoadINIexec "layers" iniFile "define"

	for texName in texArray do (
		local Label	= fnLoadINI "label" iniFile (texName as string)
		local texID	= fnLoadINIexec "texID" iniFile (texName as string)
		local Items	= fnLoadINIexec "items" iniFile (texName as string)
		append pteroLayerDefinition (_pteroLayerDefinition texName Label texID Items)
	)
)
fnGetLayersDefinition()

---------------------------------------------------------------
-- fnReturnTexID()
---------------------------------------------------------------
fn fnReturnTexID tex = (
	local ret = 0

	if pteroLayerDefinition.count > 0 do (
		for n = 1 to pteroLayerDefinition.count do
			if pteroLayerDefinition[n].name == (tex as name) do
				ret = pteroLayerDefinition[n].texID
	)
	
	return ret
)

---------------------------------------------------------------
-- fnGetSubShader()
---------------------------------------------------------------
struct _subShader (name = "", filename = "", layers = #())
fn fnGetSubShader file =
(
	local ret = _subShader()
	local lay, id
	local n = 0
	
	-- parse file
	ret.name = fnLoadINI "name" file "general"
	
	if ret.name == "" do return ret
	
	for n = 0 to 999 do
	(
		lay = fnLoadINI (n as string) file "textures"
		id = fnReturnTexID lay
		
		if id == 0 do exit
		
		if (finditem ret.layers id) == 0 then append ret.layers id
	)
		
	-- finalize data
	ret.filename = (getFilenameFile file) + (getFilenameType file)
	ret.name = trimRight ret.name
	
--	format "%\n" ret 
	return ret
)

---------------------------------------------------------------
-- fnGetShaders()
---------------------------------------------------------------
struct _shader (name = "", subTypes = #())
fn fnGetBasicShader = 
(
	return _shader "basic"	#(_subShader "diffuse"	"bas0.gsh"	#(1))
)
fn fnGetShaders =
(
	local shaderDir = "\\ini\\gsh\\"
	local dir = ""
	local ret = #()
	local dirs
	local shaders = #()

/*	rollout dlgLoadingShares "Loading Shaders" width:360 height:32
	(
		label lblText "Prepare for loading shaders ..." pos:[8,8] width:344 height:16
	)
*/	
--	createDialog dlgLoadingShares
	
	-- get engine directory
	while dir == "" do (
		local tmp = fnLoadINI "EnginePath" (fnReturnFilename #ini) "General"
		if tmp == "undefined" or tmp == "" or tmp == ok then fnPteroSettings()
		else dir = tmp
	)
	
	-- get shaders directories
	pushPrompt ("Listing shaders ...")
	dirs = getDirectories (dir + shaderDir + "\\*.*")
	for str in dirs do (
		local strArray = filterString str "\\"
		append shaders strArray[strArray.count]
	)
	popPrompt()
	
	-- default Direct3D shader
--	ret[1] = _shader "- Direct3D -"	#(_subShader "Default"	""	#{1..4,7})
	
	-- create shaders data
	for n = 1 to shaders.count do (
		local files = getFiles (dir + shaderDir + shaders[n] + "\\*.gsh")
		local tmpShader = _shader()

--		format "%\n" files
		if files.count == 0 do continue
		tmpShader.name = shaders[n]
		for f in files do
		(
			pushPrompt ("Loading shader: " + f)
			local tmp = fnGetSubShader f
--			dlgLoadingShares.lblText.text
			if tmp.name != "" do
			(
				append tmpShader.subTypes tmp
			)
			popPrompt()
		)

		if tmpShader.subTypes.count != 0 do
			append ret tmpShader
	)
	
	-- default Direct3D shader
	if ret.count == 0 do
	(
		messageBox "Shaders list doesn't exist or can't be generated.\n\nIt may cause problems with pteroLayer material.\n\nNote: Used Basic (Simple) shader only!" title:"Get pteroShader List Error"
		ret[1] = fnGetBasicShader() --_shader "basic"	#(_subShader "diffuse"	"bas0.gsh"	#(1))
	)

--	format "%\n" ret
--	destroyDialog dlgLoadingShares
	
	return ret
)

---------------------------------------------------------------
-- pteroShaderList()
---------------------------------------------------------------
struct _shaderList (
	names = #(),
	list = #(),
	fn fnGetShaderIDX shader = (
		local n = 0
		local ret = 0
		if shader != undefined do
			while (n += 1) <= list.count do
				if (fnUpcase list[n].name) == (fnUpcase shader) do (
					ret = n
					exit
				)
		return ret
	),
	fn fnGetSubShaderIDX shader subShader = (
		local shaderIDX
		local n = 0
		local ret = 0
		if shader != undefined and subShader != undefined do (
			shaderIDX = fnGetShaderIDX shader
			if shaderIDX > 0 do
				while (n += 1) <= list[shaderIDX].subTypes.count do
					if (fnUpcase list[shaderIDX].subTypes[n].name) == (fnUpcase subShader) do (
						ret = n
						exit
					)
		)
		return ret
	),
	fn fnGetShaderData shader = (
		local idx = fnGetShaderIDX shader
		local ret =	if idx > 0 then list[idx].subTypes else undefined
		return ret
	),
	fn fnGetSubShaderData shader subShader = (
		local shData = fnGetShaderData shader
		local idx = fnGetSubShaderIDX shader subShader
		local ret = if idx > 0 then shData[idx] else undefined
		return ret
	),
	fn fnUpdate = (
		list = fnGetShaders()
		names = #()
		for l in list do (
			append names l.name
		)
		return ok
	)
)
global pteroShaderList = _shaderList()

---------------------------------------------------------------
-- fnReturnShaderNames()
---------------------------------------------------------------
fn fnReturnShaderNames n:0 = ()

---------------------------------------------------------------
-- fnReturnColMats()
---------------------------------------------------------------
fn fnReturnColMats type:#txt = (
	local _iniSect	 = "General"
	local enginePath = fnLoadINI "EnginePath" (fnReturnFilename #ini) _iniSect
	local ret 		 = #("- NONE -")
	local files		 = sort (getFiles (enginePath + "\\ini\\materials\\??." + (type as string)))
	
	if enginePath == "" or files[1] == undefined do return ret
	
	fn fnParseTxt ret files = (
		for fFile in files do
		(
			pushPrompt ("Generating Surface table: " + fFile)
			local matStr = fnUpCase (getFilenameFile fFile)
			if (subString matStr 1 1) != "A" do (
				local f = openFile fFile mode:"rt"
				local done = false
				
				if matStr.count == 1 do matStr += "-"
				
				while not done do (
					local fLine = readLine f
					local n = 0
					
					while ((n += 1) + 1) <= fLine.count do
						if (fnUpCase (subString fLine n 2)) == "ID" do (
							matStr += ", " + (fnDnCase (subString fLine (n + 3) (fLine.count - n - 2)))
							done = true
							n = fLine.count
						)
						
					if (eof f) do done = true
				)
				
				close f
				
				ret += #(matStr)
			)
			popPrompt()
		)
		return ret
	)
	
	fn fnParseIni ret files = (
		for fFile in files do
		(
			pushPrompt ("Generating Surface table: " + fFile)
			local matStr = fnUpCase (getFilenameFile fFile)
			if (subString matStr 1 1) != "A" do
			(
				local tmpStr = fnLoadINI "Name" fFile "General"

				if matStr.count == 1 do matStr += "-"
				matStr += ", " + (fnDnCase tmpStr)

				ret += #(matStr)
			)
			popPrompt()
		)
		return ret
	)
	
	case type of (
		#txt : ret = fnParseTxt ret files
		#ini : ret = fnParseIni ret files
	)
	
	return ret
)

-----------------------------------------------
-- fnFindNodeItem()
-----------------------------------------------
fn fnFindNodeItem array node =
(
	local ret = 0
	while (ret += 1) <= array.count do
		if array[ret].name == node.name do return ret
	return 0
)
---------------------------------------------------------------
-- fnFillNodesByMat()
---------------------------------------------------------------
fn fnFillNodesByMat mat list =
(
	for obj in geometry do (
		if not obj.material == undefined do
		(
			if (classof obj.material) == Multimaterial then
			(
				for smat in obj.material do
					if (fnFindNodeItem list obj) == 0 do
						append list obj
			)
			else if obj.material == mat then
			(
				if (fnFindNodeItem list obj) == 0 do
					append list obj
			)
		)
	)
	
	return list
)

-----------------------------------------------
-- fnFindNoCollisionMaterial()
-----------------------------------------------
fn fnFindNoCollisionMaterial matList list =
(
--	local list = _noColMatList()
	local sceneMats = #()
	
	if (classof matList) == Multimaterial then
		for mat in matList do append sceneMats mat
	else
		sceneMats = matList

	for mat in sceneMats do
	(
		if (classof mat) == Multimaterial then
		(
			list = fnFindNoCollisionMaterial mat list
		)
		else if (classof mat) == pteroMaterial then
		(
			if mat.PRM_COLLISION_TYPE == "- " do
			(
				local idx = finditem list.name mat.name
				
				if idx > 0 and not list.material[idx] == mat do idx = 0
				
				if idx == 0 then
				(
					append list.material mat
					append list.name mat.name
					append list.models (fnFillNodesByMat mat #())
					if (classof matList) == Multimaterial then
						append list.multimats #(matList)
					else
						append list.multimats #()
				)
				else
				(
					if (classof matList) == Multimaterial do
					(
						list.models[idx] = (fnFillNodesByMat mat list.models[idx])
						append list.multimats[idx] matList
					)
				)
			)
		)
	)
	return list
)

---------------------------------------------------------------
-- fnScaleBitmap()
---------------------------------------------------------------
fn fnScaleBitmap m:undefined w:50 h:50 = (--try (
	local p, newBitmap

	if m != undefined do (
		p = ( m.width as float / m.height as float ) as float
	
		if m.width <= 4 do m.width = 8
		
		if w < m.width or h < m.height do (
			if m.width > m.height then h = w / p else w = h * p
	
			if w < 1 do w = 1
			if h < 1 do h = 1
			
			newBitmap = bitmap w h color:(color 0 0 0)
			copy m newBitmap
	
			return newBitmap
		)
	)
	
	return m
)-- catch ( format "Error: PteroLib - fnScaleBitmap()\n"; return undefined )

---------------------------------------------------------------
-- fnCreateTypes()
---------------------------------------------------------------
fn fnCreateTypes fTypes = (--try (
	local fType = typeA = typeB = ""

	for i in fTypes	do (
		typeA += ";*" + i
		typeB += "|*" + i + "|*" + i
	)
	fType = "All supported types|" + typeA + typeB

	return fType
)-- catch ( format "Error: PteroLib - fnCreateTypes()\n"; return false )

---------------------------------------------------------------
-- fnFindMatIni()
---------------------------------------------------------------
fn fnFindMatIni f:false = (--try (
	local tempName
	local iniPath		= fnReturnPath #ini
--		local _iniFile		= iniPath + "\\pteroCollette.ini"
	local _matFile		= "pteroColMat.ini"
	local _iniSect		= "MaterialLib"
	local _key			= "Path"
	local q				= false

	if (tempName = getINISetting (fnReturnFilename #ini) _iniSect _key) == "" do q = true
	if q do q = if (tempName = (fnFindFile (iniPath + "\\" + _matFile) #(".ini"))) == undefined then true else false
	if q or f do
		if ( tempName = getOpenFileName caption:"Browse for Material Library" filename:_matFile types:(fnCreateTypes #( ".ini" ))) == undefined then (
			return ""
		) else (
			fnSaveINI _key tempName (fnReturnFilename #ini) _iniSect
		)

	return tempName
)-- catch ( format "Error: PteroLib - fnFindMatIni()\n"; return "" )

---------------------------------------------------------------
-- fnLoadMats()
---------------------------------------------------------------
fn fnLoadMats = (--try (
	local tempName, matFile, textLine
	local _mats	= #("- NONE -")

	if ( tempName = fnFindMatIni() ) == "" do return _mats
	matFile = openFile tempName mode:"r"

	while not ( eof matFile ) do (
		textLine = readLine matFile
		if ( substring textLine 1 2 ) == "**" do exit
		if not textLine == "" do append _mats textLine

	)

	close matFile

	return sort _mats
)-- catch ( format "Error: PteroLib - fnLoadMats()\n"; return _mats )

---------------------------------------------------------------
-- fnAddMap() - common functions
---------------------------------------------------------------
-- Find Bitmap in tArray
fn fnFindBitmapItem tArray map = (
	local ret = 0
	for n = 1 to tArray.count do (
		local m = tArray[n]
		if (classof m) == BitMap do
			if (fnUpCase m.filename) == (fnUpCase map.filename) do (
				ret = n
				exit
			)
	)
	return ret
)
-- Add TextureMap to tArray
fn fnAddMap map tArray x:true = (
	local m = classof map
	if m == Bitmaptexture or m == BitMap do
		if x then
			case m of
			(
				Bitmaptexture: if (findItem tArray map) == 0 do append tArray map
				BitMap: if (fnFindBitmapItem tArray map) == 0 do append tArray map
			)
		else
			append tArray map
	return tArray
)
/*
-- find TextureMap in StadardMaterial
fn fnFM mat tArray x:true = (
	local m, cMat
	if mat != undefined do
	(
--		m = mat.classid	
--		if m[1] == 2 and m[2] == 0 or m[1] == 1699607506 and m[2] == 1692035545 do
		cMat = classof mat
			
		if cMat == pteroMaterial or cMat == Standardmaterial do
			for map in mat.maps do
				if map != undefined do
					tArray = fnAddMap map tArray x:x
	)
	return tArray
)

-- Find StandardMaterial in MultiMaterial
fn fnMM mat tArray x:true = (		
	for submat in mat.materiallist do
		tArray = fnFM submat tArray x:x
	return tArray
)
*/
---------------------------------------------------------------
-- fnFillMapArray()
---------------------------------------------------------------
fn fnFillMapArray mat tArray x:true = (
	local map, m, cMat, ciMat

	if mat == undefined then ( format "ERROR: fnFillMapArray() - mat:%\n" mat; return tArray )
	if tArray == undefined then ( format "ERROR: fnFillMapArray() - tArray:%\n" tArray; return tArray )

	-- get class of material
	cMat = classof mat
	ciMat = mat.classid

	-- material switch
	if cMat == pteroMaterial then
	(	-- pteroMat
--		tArray = fnFM mat tArray x:x
		for map in mat.maps do
		(
			if map != undefined do
				tArray = fnAddMap map tArray x:x
		)
	)
	else if (cMat == pteroLayer) or (ciMat[1] == 1222670497 and ciMat[2] == 782138873) then
	(	-- pteroLayer
		if bitmapTable != undefined do
			for f in mat.layerOrder do
			(
				if mat.layerFilename[f] != undefined do --and (bitmapTable) do--(doesFileExist f) do
				(
--					map = openBitmap f
					map = bitmapTable.getTexture mat.layerFilename[f]
					if map != undefined do
						tArray = fnAddMap map.bitmap tArray x:x
				)
			)
	)
	else if cMat == Multimaterial then
	(	-- Multimat
--		tArray = fnFM submat tArray x:x
		for submat in mat.materiallist do
			tArray = fnFillMapArray submat tArray x:x 
	)
	else if cMat == Standardmaterial then
	(	-- Standard
--		tArray = fnFM mat tArray x:x
		for map in mat.maps do
			if map != undefined do
				tArray = fnAddMap map tArray x:x
	)
	else if cMat == Bitmaptexture then
	(	-- bitmap texture
		tArray = fnAddMap mat tArray x:x
	)

--	format "%\n" tArray
	return tArray
)

---------------------------------------------------------------
-- fnSelectMapObjects()
---------------------------------------------------------------
fn fnSelectMapObjects m tex = (
	global map = tex
	global mat = m

	if map == undefined then ( format "ERROR: fnFillObjArray() - map:%\n" map; return false )

	rollout dlgProgress "Looking for texture" width:264 height:232
	(
		local oArray	= #()

		label		lbl2	"Progress:"			pos:[8,8]		width:248	height:16
		label		lbl1	""					pos:[8,24]		width:248	height:16
		progressBar	pb1		""					pos:[8,40]		width:248	height:8
		progressBar	pb2		""					pos:[8,48]		width:248	height:8
		listBox		lbx1	"Waifs:"			pos:[8,64]		width:248	height:8
		button		btn2	"Select and Close"	pos:[8,200]		width:148	height:24	enabled:false
		button		btn3	"Cancel"			pos:[164,200]	width:92	height:24	enabled:false

		-- fnCheckFile()
		fn fnCheckFile mat file = (
			local ret = false
			local cID = mat.classid
			for m in (fnFillMapArray mat #()) do (
				if m.filename == file do (
					ret = true
					exit
				)
			)
			return ret
		)

		-- fnCheckMap()
		fn fnCheckMap mat map = (
			local ret = false
			local cID = mat.classid
			for m in (fnFillMapArray mat #()) do
				case (classof map) of (
					Bitmaptexture: 
						if m == map do (
							ret = true
							exit
						)
					String:
						if m.filename == map do (
							ret = true
							exit
						)
				)
			return ret
		)

		-- Select and Close
		on btn2 pressed do (
			clearselection()
			select oArray

			destroyDialog dlgProgress
		)

		-- Cancel
		on btn3 pressed do (
			destroyDialog dlgProgress
		)

		-- Open
		on dlgProgress open do (
			local pArray	= #()
			local oNum		= 1
			local oMax		= geometry.count
			local lProgress	= 0
			local nProgress = 0
			local f			= 1
			local mid, obj, fm, o, oMat

			while oNum <= oMax do (
				lProgress	= 0
				obj			= geometry[oNum]
				msh			= copy obj.mesh
				oMat		= obj.material

				lbl2.text = "Progress: " + oNum as string + " of " + oMax as string
				lbl1.text = obj.name + " - " + msh.numfaces as string + " faces"

				if obj.material != undefined do
					if ( not obj.isHidden ) do (
						o = oMat.classid

						if o[1] == 512 and o[2] == 0 then (
							f = 1
							fm = msh.numFaces

							while f <= fm do (
								mid = getFaceMatID msh f
								nProgress = ( 100.0 * f / fm ) as integer
								if lProgress != nProgress do (
									pb2.value = nProgress as float
									lProgress = nProgress
								)

								if oMat.materialList[mid] == mat do
									if (fnCheckMap oMat.materialList[mid] map) do exit

								f += 1
							)
							if f < fm do (
								append oArray obj
								append pArray obj.name
							)
						) else
							if oMat == mat do
								if (fnCheckMap oMat map) do (
									append oArray obj
									append pArray obj.name
								)
					)

				pb1.value		= 100.0 * oNum / oMax
				pb2.value		= 100.0
				lbx1.items		= pArray
				lbl2.text		= "Progress: Done"
				lbl1.text		= ""
				btn2.enabled	= true

				oNum += 1
			)
			btn3.enabled	= true
		)
	)

	createDialog dlgProgress modal:true --style:#(#style_titlebar, #style_sysmenu)

	destroyDialog dlgProgress

	return true
)

---------------------------------------------------------------
-- fnSelectBitmapDialog()
---------------------------------------------------------------
fn fnSelectBitmapDialog c:true type:#pteroMat = (

	global prmCreate
	local _iniSect			= "PteroLibrary"
	local ret				= #( 0, undefined )

	--	rollout roSelectBitMap
	rollout roSelectBitMap "pteroMap Browser" width:400 height:584
	(
		local _iniSect		= "PteroLibrary"
		local ret			= #( 0, undefined )
		local _MapArray		= #(#(), #(), #(), #(), #())
		local _BmpArray		= #()
		local blankBmp		= bitmap 2 2 color:(color 210 255 255)
		local CurSelect		= getCurrentSelection()
		local lSize			= "Size: "
		local lFile			= "File: "

		activeXControl	axcBmp			"MSComctlLib.ListViewCtrl" pos:[152,30] width:240 height:514  --TreeCtrl
		edittext		edtFind			"" pos:[149,8] width:242 height:16

		button			btnOK			"OK" pos:[232,552] width:70 height:24
		button			btnCancel		"Cancel" pos:[320,552] width:70 height:24
		imgTag			itgBitmap		pos:[8,8] width:136	height:136 style:#bmp_center tooltip:"Show Bitmap" bitmap:blankBmp transparent:(color 210 255 255)

		GroupBox		grp3			"Type:" pos:[8,152] width:136 height:52	enabled:false
		radiobuttons	rdoType			"" pos:[16,168] width:59 height:32 labels:#("Bitmap", "Texture") columns:1 enabled:false

		GroupBox		grp1			"Browse from:" pos:[8,208] width:136 height:100
		radiobuttons	rbtListType		"" pos:[16,225] width:74 height:80 labels:#("Mtl Library", "Mtl Editor", "Active Slot", "Selected", "Scene") columns:1
		GroupBox		grp2			"Bitmap info:" pos:[8,312] width:136 height:234
		label			lblFile			"File:" pos:[16,328] width:125 height:16
		label			lblSize			"Size:" pos:[16,344] width:120 height:16
		listbox			lbxMat			"Used in materials:" pos:[16,360] width:120 height:5 items:#() --#("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o")
		checkbox		chkUsedModels	"Used on models:" pos:[16,454] width:120 height:16 checked:false
		listbox			lbxObj			"" pos:[16,470] width:120 height:5 items:#() --#("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o")
		button			btnView			"View" pos:[8,552] width:70 height:24
		-- Image list controls for holding icons
		activeXControl	ilTv			"{2C247F23-8591-11D1-B16A-00C0F0283628}" height:0 width:0

		-- sortList()
		fn sortList name key =
		(
			setWaitCursor()
			name.sortKey = key
			local order = name.sortOrder
			name.sortOrder = if order == #lvwAscending then #lvwDescending else #lvwAscending
			name.sorted = true  -- sort for now
			name.sorted = false -- disabling auto sorting
			setArrowCursor()
		)
		
		-- fnAddItemsToListView()
		fn fnAddItemsToListView target what = (
			-- clear old table
			target.listItems.clear()
			
			for i=1 to what.count do (
				local c = what[i], item
				
				-- add new item
				item = target.listItems.add()
				item.text = c[1]
				item.tag = c[2]
				item.forecolor = (color 32 32 32)
				item.bold = false
				
				-- set icon and tooltip
				case of (
					(i == 1) : (
						item.smallicon = 1
						item.toolTipText = "Double click to load new Bitmap"
					)
					((getFilenamePath c[2]) == "") : (
						item.smallicon = if c[3] == Bitmaptexture then 3 else 5
						item.toolTipText = if c[3] == Bitmaptexture then "TEXTURE " else "BITMAP "
						item.toolTipText += "NOT FOUND - " + c[2]
					)
					(i != 1) : (
						item.smallicon = if c[3] == Bitmaptexture then 2 else 4
						item.toolTipText = if c[3] == Bitmaptexture then "TEXTURE: " else "BITMAP: "
						item.toolTipText += c[2]
					)
				)
			)
		)

		-- fnInitAX()
		fn fnInitAX name = (
			local iconDir = fnReturnPath #ico
			local LVM_FIRST = 0x1000
			local LVM_SETCOLUMNWIDTH = (LVM_FIRST + 30)

			-- define List View Control
			enableAccelerators = false
			name.gridLines = false
			name.borderStyle = #ccFixedSingle
			name.view = #lvwReport
			name.fullRowSelect = true
			name.multiSelect = false
			name.labelEdit = #lvwManual
			name.hideSelection = false
			name.sortOrder = #lvwAscending		
			name.hideColumnHeaders = true--false --true
			name.allowColumnReorder = false
			name.appearance = #cc3D
			
			-- define temp bitmap control
			ilTv.imageheight = 14
			ilTv.imagewidth = 14
			ilTv.maskColor = color 212 212 212
			ilTv.useMaskColor = true
			-- add small icons
			ilTv.listImages.add 1 #new (loadPicture (iconDir + "\\bitmap_new.bmp"))
			ilTv.listImages.add 2 #texture (loadPicture (iconDir + "\\texture_loaded.bmp"))
			ilTv.listImages.add 3 #textureNotFound (loadPicture (iconDir + "\\texture_notfound.bmp"))
			ilTv.listImages.add 4 #bitmap (loadPicture (iconDir + "\\bitmap_loaded.bmp"))
			ilTv.listImages.add 5 #bitmapNotFound (loadPicture (iconDir + "\\bitmap_notfound.bmp"))
			name.smallIcons = ilTv
			
			-- create column
			hName = name.columnHeaders.add()
			hName.text = "Name"
			windows.sendMessage name.hwnd LVM_SETCOLUMNWIDTH  0 220

--			showProperties name
		)
		
		-- fnSortMat()
		fn fnSortMat m1 m2 = (
			local ret = 0
			if (classof m1) == Bitmaptexture then m1 = fnDnCase m1.name else m1 = fnDnCase (getFilenameFile m1.filename)
			if (classof m2) == Bitmaptexture then m2 = fnDnCase m2.name else m2 = fnDnCase (getFilenameFile m2.filename)
			case of (
				( m1 > m2 ): ret = 1
				( m1 < m2 ): ret = -1
			)
			return ret
		)

		-- fnFillObjArray()
		fn fnFillObjArray = (
			local oArray	= #()
			local state		= rbtListType.state
			local i			= axcBmp.selectedItem.index - 1
			local map		= _MapArray[state][i]
			local cMap		= classof map 

			if chkUsedModels.checked == false do return #()
			if map == undefined then ( format "ERROR: fnFillObjArray() - map:%\n" map; return #() )
			
			for obj in geometry do
			(
				if obj.material == undefined do continue
				
				case cMap of
				(
					Bitmaptexture: 
						for m in ( fnFillMapArray obj.material #() ) do
						(
							case (classof m) of
							(
								Bitmaptexture: if map == m do append oArray obj.name
--								BitMap: if map.filename == m.filename do append oArray obj.name
							)
						)
					BitMap:
						for m in ( fnFillMapArray obj.material #() ) do
						(
							case (classof m) of
							(
								Bitmaptexture: if map.filename == m.filename do append oArray obj.name
								BitMap: if map.filename == m.filename do append oArray obj.name
							)
						)
				)
			)

			return ( sort oArray )
		)

		-- fnFillMatArray()
		fn fnFillMatArray = (
			local mArray	= #()
			local state		= rbtListType.state
			local i			= axcBmp.selectedItem.index - 1 --lbxBmp.selection - 1
			local map		= _MapArray[state][i]

			if map == undefined then ( format "ERROR: fnFillObjArray() - map:%\n" map; return #() )

			for mat in sceneMaterials do
				for m in ( fnFillMapArray mat #() ) do
					if m == map do
						append mArray mat.name

			for mat in meditMaterials do
				for m in ( fnFillMapArray mat #() ) do
					if m == map do
 						if (findItem mArray mat.name) == 0 do append mArray mat.name

			return ( sort mArray )

		)

		--	fnFindItem()
		fn fnFindItem txt = (
			local ret = axcBmp.selectedItem --"" --lbxBmp.selection

			if txt == undefined then return ret

			for i = 1 to axcBmp.listItems.count do
				if ( matchPattern axcBmp.listItems[i].text pattern:( txt + "*" ) ) do return axcBmp.listItems[i]

			return ret
		)

		--	fnWhatTypeIs()
		fn fnWhatTypeIs w:1 = (
			local state	= rbtListType.state
			local i		= axcBmp.selectedItem.index - 1 --lbxBmp.selection - 1
			local map	= if i > 0 then _MapArray[state][i] else undefined

			rollout roMethod1 "Insert PteroMap" --width:150 --height:90
			(
				group "Method" (
					radiobuttons rbtMethod ""	labels:#("Instance", "Copy")	columns:1	align:#left
				)
				button	btnOK		"OK"		width:60	height:24	align:#left		across:2
				button	btnCancel	"Cancel"	width:60	height:24	align:#right
				on btnOK		pressed	do	destroyDialog roMethod1
				on btnCancel	pressed	do	( rbtMethod.state = 0; destroyDialog roMethod1 )
				on roMethod1	open	do	(
					setfocus btnOK
					destroyDialog roSelectBitMap
					try (rbtMethod.state = (fnLoadINI "AddExisting" (fnReturnFilename #ini) _iniSect) as integer) catch ( rbtMethod.state = 1 )
					if rbtMethod.state == 0 do rbtMethod.state = 1
				)
			)

			rollout roMethod2 "Insert Bitmap" --width:150 --height:90
			(
				group "Method" (
					radiobuttons rbtMethod ""	labels:#("Into existing", "Create new")	columns:1	align:#left
				)
				button	btnOK		"OK"		width:60	height:24	align:#left		across:2
				button	btnCancel	"Cancel"	width:60	height:24	align:#right
				on btnOK		pressed	do	destroyDialog roMethod2
				on btnCancel	pressed	do	( rbtMethod.state = 0; destroyDialog roMethod2 )
				on roMethod2	open	do	(
					setfocus btnOK
					destroyDialog roSelectBitMap
					try (rbtMethod.state = (fnLoadINI "AddNew" (fnReturnFilename #ini) _iniSect) as integer) catch ( rbtMethod.state = 1 )
					if rbtMethod.state == 0 do rbtMethod.state = 1
				)
			)

			case w of (
				1:			(
								createDialog roMethod1 modal:true style:#(#style_toolwindow)
								case roMethod1.rbtMethod.state of (
									1: ( ret[1] = 1; ret[2] = map )
									2: ( ret[1] = 2; ret[2] = map.filename )
									default: ( ret[1] = 0; ret[2] = undefined )
								)
								fnSaveINI "AddExisting" ( roMethod1.rbtMethod.state as string ) (fnReturnFilename #ini) _iniSect
							)
				2:			(
								createDialog roMethod2 modal:true style:#(#style_toolwindow)
								case roMethod2.rbtMethod.state of (
									1: ( ret[1] = 3 )
									2: ( ret[1] = 2 )
									default: ( ret[1] = 0; ret[2] = undefined )
								)
								fnSaveINI "AddNew" ( roMethod2.rbtMethod.state as string ) (fnReturnFilename #ini) _iniSect
							)
				default: 	( ret[1] = 0; ret[2] = undefined )
			)
		)

		--	fnUtilizeItem()
		fn fnUtilizeItem type = (
			local bmpData, workMap, workBitmap
			local bitmapTypes	= #( ".dds", ".bmp", ".tga", ".ifl" )
			local i				= axcBmp.selectedItem.index --lbxBmp.selection
			local fileTxt		= lFile
			local sizeTxt		= lSize
			local msgTxt		= "You can choose only:\n"
			local bmpFile		= ""
 			local state			= rbtListType.state

			for i in bitmapTypes do msgTxt = msgTxt + "*" + i + ", "
			case (subString axcBmp.selectedItem.text 1 2) of (
				"- " : case type of (
						#axcBmp :	  (
										setWaitCursor()
										btnView.enabled		= false
										itgBitmap.enabled	= false
										itgBitmap.bitmap	= blankBmp
										itgBitmap.tooltip	= ""
										lbxMat.items		= #()
										lbxObj.enabled		= chkUsedModels.checked
										lbxObj.items		= #()
										enableAccelerators = false
										setArrowCursor()
									  )
						#btnView :	  ()
						#btnOK : 	  (
										while true do (
											selName = getBitmapOpenFileName caption:"Select bitmap" filename:""
											if selName == undefined do exit
											if ( findItem bitmapTypes ( fnDncase ( getFilenameType selName ) ) ) > 0 do exit
											messageBox msgtxt title:"Wrong File Type"
										)
										if selName == undefined do return false
										ret[1] = 2
										ret[2] = selName
										if prmCreate == #create or prmCreate == #pteroLayer then
											destroyDialog roSelectBitMap
										else
											fnWhatTypeIs w:ret[1]
					 				  )
						#btnCancel : (
										ret[1] = 0
										destroyDialog roSelectBitMap
									  )
					)
				default : case type of (
						#axcBmp : 	if (getfiles _MapArray[state][i-1].filename).count == 1 do
									(
										setWaitCursor()
										-- do utilize item in list
										workMap		= _MapArray[state][i-1]
										workBitmap	= if (classof workMap) == Bitmaptexture then workMap.bitmap else workMap
										itgBitmap.bitmap	= fnScaleBitmap m:workBitmap w:136 h:136
										btnView.enabled		= true
										itgBitmap.enabled	= true

										sizeTxt		= fnCutString s:(sizeTxt + (workBitmap.width as string) + " x " + (workBitmap.height as string)) c:25
										fileTxt		= fnCutString s:(fileTxt + ( fnDncase (filenamefrompath workMap.filename))) c:25
										itgBitmap.tooltip	= workmap.filename
										lbxMat.items		= fnFillMatArray()
										lbxObj.enabled		= chkUsedModels.checked
										lbxObj.items		= fnFillObjArray()
										enableAccelerators = false
										setArrowCursor()
									)
						#btnView :	if (
										getfiles _MapArray[state][i-1].filename).count == 1 do (
	 									workMap = _MapArray[state][i-1]
										workBitmap	= if (classof workMap) == Bitmaptexture then workMap.bitmap else workMap
										display workBitmap
									)
						#btnOK : 	(
										local i		= axcBmp.selectedItem.index - 1 --lbxBmp.selection - 1
										local map	= if i > 0 then _MapArray[state][i] else undefined
										
										case (classof map) of (
											Bitmaptexture: (
												ret[1] = 1
											)
											BitMap: (
												ret[1] = 2
												ret[2] = map.filename
											)
										)
										
										if prmCreate == #create and ret[1] == 2 or prmCreate == #pteroLayer then (
											ret[2] = map.filename
											destroyDialog roSelectBitMap
										) else
											fnWhatTypeIs w:ret[1]
									  )
						#btnCancel : (
										ret[1] = 0
										destroyDialog roSelectBitMap
									  )
					)
			)

			lblSize.text	= sizeTxt
			lblFile.text	= fileTxt

			-- garbage collect
			gc light:true
		)

		-- fnUtilizeKey
		fn fnUtilizeKey keyCode Shift = case keyCode of
		(
			-- enter
			13: fnUtilizeItem #btnOK
			-- esc
			27: fnUtilizeItem #btnCancel
			-- up
			38: fnUtilizeItem #axcBmp
			-- down
			40: fnUtilizeItem #axcBmp
		)
		
		-- fnListBitmap()
		fn fnListBitmap state =
		(
			local mat, obj
			
			setWaitCursor()
			if _MapArray[state][1] == undefined do
				case state of (
					1 :	for mat in currentMaterialLibrary do _MapArray[state] = fnFillMapArray mat _MapArray[state]
					2 :	for mat in meditMaterials do _MapArray[state] = fnFillMapArray mat _MapArray[state]
					3 :	fnFillMapArray (getMeditMaterial activeMeditSlot) _MapArray[state]
					4 :	for obj in curSelect do (o = obj.classid; if o[1] == 16 and o[2] == 0 do _MapArray[state] = fnFillMapArray (mat = obj.material) _MapArray[state])
					5 :	for mat in sceneMaterials do _MapArray[state] = fnFillMapArray mat _MapArray[state]
				)

			_BmpArray			= #(#("- load new - ","", undefined))

			qsort _MapArray[state] fnSortMat
			for i in _MapArray[state] do 
				case (classof i) of (
					Bitmaptexture: append _BmpArray #((fnDncase (filenamefrompath i.name)), i.filename, (classof i))-- + " [" + (filenamefrompath i.filename) + "]")
					BitMap: append _BmpArray #((getFilenameFile i.filename), i.filename, (classof i))
				)
			
			fnAddItemsToListView axcBmp _BmpArray
			fnUtilizeItem #axcBmp
			setArrowCursor()
		)

		--	fnDoResize()
		fn fnDoResize val = (
			local yPos
			
			roSelectBitMap.width = 400
			if val.y < 584 then roSelectBitMap.height = 584
			yPos = roSelectBitMap.height - (584 - 552)
			
			btnOK.pos.y = yPos
			btnCancel.pos.y = yPos
			btnView.pos.y = yPos
			axcBmp.size.y = roSelectBitMap.height - 70
		)
		
		--	event handles
		on rbtListType	changed state		do fnListBitmap state
		on chkUsedModels changed state		do fnUtilizeItem #axcBmp
		on edtFind		changed txt			do (axcBmp.selectedItem = (fnFindItem txt); fnUtilizeItem #axcBmp)
		on axcBmp		click				do fnUtilizeItem #axcBmp
		on axcBmp		dblclick			do fnUtilizeItem #btnOK
		on axcBmp		keyup keyCode Shift	do fnUtilizeKey keyCode Shift
		on axcBmp		columnClick clm		do if (clm.index - 1) == 0 do sortList axcBmp 0
		on btnView		pressed				do fnUtilizeItem #btnView
		on itgBitmap	click				do fnUtilizeItem #btnView
		on btnOK		pressed				do fnUtilizeItem #btnOK
		on btnCancel	pressed				do fnUtilizeItem #btnCancel
		-- roSelectBitMap resize
		on roSelectBitMap resized val do fnDoResize val
		-- roSelectBitMap open
		on roSelectBitMap open do
		(
			fnDoResize [400, roSelectBitMap.height]
			try (rbtListType.state = (fnLoadINI "ListType" (fnReturnFilename #ini) _iniSect) as integer) catch ( rbtListType.state = 2 )
			if rbtListType.state == 0 do rbtListType.state = 2
			local tmp = fnLoadINIexec "ShowUsedModels" (fnReturnFilename #ini) _iniSect
			if tmp == ok or tmp == undefined then chkUsedModels.checked = false else chkUsedModels.checked = tmp
			lbxObj.enabled = chkUsedModels.checked
			
			fnInitAX axcBmp
			fnListBitmap rbtListType.state
		)
		-- roSelectBitMap open
		on roSelectBitMap close do (
			fnSaveINI "ListType" ( rbtListType.state as string ) (fnReturnFilename #ini) _iniSect
			fnSaveINI "DialogPosition"	((getDialogpos roSelectBitMap) as string) (fnReturnFilename #ini) _iniSect
			fnSaveINI "DialogSize"	("[400," + roSelectBitMap.height as string + "]") (fnReturnFilename #ini) _iniSect
			fnSaveINI "ShowUsedModels"	(chkUsedModels.checked as string) (fnReturnFilename #ini) _iniSect

			_MapArray = undefined
			_BmpArray = undefined
			CurSelect = undefined
 		)
	)

	case type of (
		#pteroMat: prmCreate = if c then #create else #insert
		#pteroLayer: prmCreate = #pteroLayer
	)

	-----------------------------------------------
	if (p = fnLoadINIexec "DialogPosition" (fnReturnFilename #ini) _iniSect) == ok do
		p = [100,100]
	if (s = fnLoadINIexec "DialogSize" (fnReturnFilename #ini) _iniSect) == ok then
		s = [400,584]
	else (
		s.x = 400
		if s.y < 584 do s.y = 584
	)
	-----------------------------------------------

	fn fnSelectByMaxBrowser ret =
	(
		local map = materialBrowseDlg #maps #incNone #instanceOnly
		if (classof map) == Bitmaptexture do
		(
			ret[1] = 2
			ret[2] = map.filename
		)
		
		return ret
	)

	if (_activeXDoesntWork_ == false) then
	(
		createDialog roSelectBitMap modal:true style:#(#style_sysmenu, #style_toolwindow, #style_resizing) width:s.x height:s.y pos:p lockWidth:true
		ret = roSelectBitMap.ret
	)
	else
	(
		ret = fnSelectByMaxBrowser ret
	)

	-- garbage collect
	gc light:true

	return ret
)

---------------------------------------------------------------
-- fnIncludePlugin()
---------------------------------------------------------------
fn fnIncludePlugin e e2 width:"16" height:"16" chars:0 columns:0 doAppend:false = (
	local scriptPath	= fnReturnPath #ms --fnReturnFilename #scriptPath
	local _plugFiles	= sort (getFiles ( scriptPath + "\\_*" + e))
	local _tmpFile		= #( scriptPath + "\\plug_tmp_btn" + e2, scriptPath + "\\plug_tmp_inc" + e2, scriptPath + "\\plug_tmp_ini" + e2 )
	local bLeft			= true
	local colCount		= 1
	local fFile, fLine, fWords
	local rName, rLabel, rID, rLabel2, rLabel3
	local pDone

	for n = 1 to _tmpFile.count do (	-- Clear _tmpFiles
		if (fnFindFile _tmpFile[n] #("")) == undefined then
			fFile = createFile _tmpFile[n]
		else
			fFile = openFile _tmpFile[n] mode:"wt"
		close fFile
	)

	for k = 1 to _plugFiles.count do (
		-- Read Plug-in
		fFile = openFile _plugFiles[k] mode:"rt"
		pDone = false

--		if _DEBUG_ do format "\nfFile: %\n" fFile

		do (
			fLine = readLine fFile
			fWords = filterString fLine "	 \""

--			if _DEBUG_ do format "%\n" fWords

			for n = 1 to fWords.count do
				if (fnDncase fWords[n]) == "rollout" and fWords[n+1] != undefined and fWords[n+2] != undefined do (
					rName	= fWords[n+1]
					rLabel2 = fWords[n+2]
					rID		= (random 1 9999 + random 1 9999) as string
					rLabel	= fWords[n+2]
					for i = 3 to (fWords.count-3) do if (fnDncase fWords[n+i]) != "rolledup" and fWords[n+i] != "(" do
						rLabel += " " + fWords[n+i]
					pDone = true
--					if _DEBUG_ do format "rName: %\trLabel: %\n" rName rLabel

					exit
				)
		) while ( not (eof fFile) ) and ( not pDone )

		rLabel3 = fnReplaceChars rLabel "!@#$%^&*(){}[];':\"\\|,./<>?`~-=+_ 	" ""

		-- Close Plug-in
		close fFile

		-- Fill _tmpFiles
		if columns == 0 do columns = _plugFiles.count
		for n = 1 to _tmpFile.count do (
			fFile = openFile _tmpFile[n] mode:"at"	-- Open _tmpFile

			case n of (
				1	: (	-- create plug_tmp_btn
						str =	"checkbutton	btnRo" + rLabel3 + rID + "	\"" + (if chars > 0 then substring rLabel 1 chars else (fnCutString s:rLabel length:65)) + "\""
						str +=	"	width:" + width + "	height:" + height
						str +=	"	align:" + (if columns == 2 and not bLeft then "#right" else "#left")
						str +=	"	tooltip:\"Open " + rLabel + " rollout\""
/*							str +=	if colCount == 1 and k < (_plugFiles.count) do --columns == 2 and bLeft and k < (_plugFiles.count) or
								"	across:"-- + columns as string
*/						if colCount == 1 and k < (_plugFiles.count) do str +=	"	across:" + columns as string
						str +=	"\n"
						str +=	"on btnRo" + rLabel3 + rID + " changed state do fnShowRollout \"" + rLabel3 + "\" type:(if state then #add else #remove)\n"
						bLeft = not bLeft
					  )
				2	: ( -- create plug_tmp_inc
						str = "include \"" + _plugFiles[k] + "\"\n"
					  )
				3	: ( -- create plug_tmp_ini
						str = rName + ".fnInitRollOut()\n"
						if doAppend do
							str += "fnAppendRollOut " + rName + " \"" + rLabel2 + "\"\n"--rName + ".fnInitRollOut()\n"
					  )
			)

			format str to:fFile	-- Write to _tmpFile
			close fFile			-- Close _tmpFile
		)

--			format "k: %\tcolCount: %\n" k colCount
		if (colCount += 1) > columns do colCount = 1
	)

	return true
)
--fnIncludePlugin ".msp" ".ppb" width:"(_mainWidth / 2.7)" height:"18" columns:2
--fnIncludePlugin ".msm" chars:1 doAppend:true

---------------------------------------------------------------
--	fnCreateRollouts()
---------------------------------------------------------------
--struct _roListInfo	(name, label, tex_id)
fn fnCreateRollouts file:true = (
	-- structs def
--	struct _rolloutData (name, label, texID)
	struct _controlData	(type, name, label, event_type, params)

	-- locals def

	local scriptPath	= fnReturnPath #ms --fnReturnFilename #scriptPath
	local _tmpFile		= #(scriptPath + "\\pteroLayer.ros", scriptPath + "\\pteroLayer.roa")
	local fFile			= #()
	local roc
	local str = "fn fnUpdateUI type = ("
	str += "\n		if (fnIsRolloutActive (fnLabel())) then ("
--	str += "\n			if type == #all do _name.open = true" --fnIsLayerEnabled _texID --layerEnabled[_texID]"
	str += "\n			for n = 1 to _name.controls.count do ("
--	str += "\n				if	(_name.controls[n].name != @chkEnabled@) and"
--	str += "\n					(_name.controls[n].name != @btnFilename@) and"
--	str += "\n					(substring _name.controls[n].name 1 3 != @lbl@) do"
--	str += "\n						_name.controls[n].enabled = layerEnabled[_texID]"
--	str += "\n				if layerFilename[_texID] != @ @ do btnFilename.enabled = layerEnabled[_texID]"
	str += "\n				fnUtilizeTexture _texID (_name.controls[n].name as name) read:true"
	str += "\n			)"
	str += "\n			if layerFilename[_texID] == \"\" then"
	str += "\n				layerChannel[_texID] = _texID"
--	str += "\n			layerEnabled[_texID] = true"
	str += "\n		) else ("
	str += "\n			if type == #all do _name.open = false"
	str += "\n			removeRollout (fnName())"
--	str += "\n			layerEnabled[_texID] = false"
	str += "\n		)"
--	str += "\n		print _texID; print type"
	str += "\n	)"

	-- rollouts def
/*	local rolloutsDef	= #(\
		_rolloutData	#TEX_DIFFUSE			"Diffuse"			(fnReturnTexID #TEX_DIFFUSE),
		_rolloutData	#TEX_STRUCTURE			"Structure"			(fnReturnTexID #TEX_STRUCTURE),
		_rolloutData	#TEX_OVERLAY			"Overlay"			(fnReturnTexID #TEX_OVERLAY),
		_rolloutData	#TEX_OVERLAY_CHANNEL	"Overlay Channel"	(fnReturnTexID #TEX_OVERLAY_CHANNEL),
		_rolloutData	#TEX_ENVIRONMENT		"Environment"		(fnReturnTexID #TEX_ENVIRONMENT),
		_rolloutData	#TEX_NMAP				"Normal Map"		(fnReturnTexID #TEX_NMAP),
		_rolloutData	#TEX_BUMP				"Bump"				(fnReturnTexID #TEX_BUMP),
		_rolloutData	#TEX_LM					"Light Map"			(fnReturnTexID #TEX_LM),
		_rolloutData	#TEX_UNI				"Universal"			(fnReturnTexID #TEX_UNI)
	)
*/
	-- rollout controls def
	local rolloutControlsDef = #(\
--		_controlData	#checkbutton	#chkEnabled		"E"			#changed	"pos:[8,8]		width:72	height:16	toolTip:\"Enable layer\"	highlightColor:(color 255 255 132)",
		_controlData	#ImgTag			#itgBitmap		""			#click		"pos:[8,8]		width:72	height:72	toolTip:\"Pic\"	style:#bmp_center	bitmap:(bitmap 72 72 color:(color ((colorman.getColor #background).x*255) ((colorman.getColor #background).y*255) ((colorman.getColor #background).z*255)))	transparent:(color ((colorman.getColor #background).x*255) ((colorman.getColor #background).y*255) ((colorman.getColor #background).z*255))",
		_controlData	#checkbutton	#btnMipmap		"M"			#changed	"pos:[88,8]		width:16	height:16	images:(fnReturnFilename  #plMip)	toolTip:\"Mipmap bitmap\"",
		_controlData	#checkbutton	#btnTexMove		"T"			#changed	"pos:[104,8]	width:16	height:16	images:(fnReturnFilename  #plMove)	toolTip:\"Use TexMove\"",
		_controlData	#checkbutton	#btn3			""			#changed	"pos:[120,8]	width:16	height:16	toolTip:\"\"",
		_controlData	#checkbutton	#btn4			""			#changed	"pos:[136,8]	width:16	height:16	toolTip:\"\"",
		_controlData	#checkbutton	#btn5			""			#changed	"pos:[152,8]	width:16	height:16	toolTip:\"\"",
		_controlData	#checkbutton	#btnOverlay		"O"			#changed	"pos:[88,24]	width:16	height:16	images:(fnReturnFilename  #plOver)	toolTip:\"Overlay Multitexture\"",
		_controlData	#checkbutton	#btnApplyLight	"L"			#changed	"pos:[104,24]	width:16	height:16	images:(fnReturnFilename  #plLight)	toolTip:\"Apply engine lights\"",
		_controlData	#checkbutton	#btnEnvType		"T"			#changed	"pos:[120,24]	width:16	height:16	images:(fnReturnFilename  #plEnvT)	toolTip:\"Change type of environment map\"",
		_controlData	#checkbutton	#btn9			""			#changed	"pos:[136,24]	width:16	height:16	toolTip:\"\"",
		_controlData	#checkbutton	#btn10			""			#changed	"pos:[152,24]	width:16	height:16	toolTip:\"\"",
		_controlData	#checkbutton	#btnTileU		"U"			#changed	"pos:[184,8]	width:16	height:16	toolTip:\"Enabled U tile\"",
		_controlData	#spinner		#spnTilingU		""			#changed	"pos:[200,8]	width:56	height:16	range:[-99999,99999,1]	type:#float	scale:0.01",
		_controlData	#checkbutton	#btnTileV		"V"			#changed	"pos:[184,24]	width:16	height:16	toolTip:\"Enabled V tile\"",
		_controlData	#spinner		#spnTilingV		""			#changed	"pos:[200,24]	width:56	height:16	range:[-99999,99999,1]	type:#float	scale:0.01",
		_controlData	#spinner		#spnChannel		"Ch:"		#changed	"pos:[280,8]	width:40	height:16	range:[1,99,1]	type:#integer",
		_controlData	#button			#btnExtend		"e"			#pressed	"pos:[88,48]	width:16	height:16	images:(fnReturnFilename  #plSet)	toolTip:\"Exteded properties\" aligh:#right",
--		_controlData	#button			#btnUnique		"i"			#pressed	"pos:[88,48]	width:16	height:16	toolTip:\"Make Unique\" aligh:#right",
		_controlData	#button			#btnFilename	"- none -"	#pressed	"pos:[104,48]	width:200	height:16	toolTip:\"Layer bitmap list\"",
		_controlData	#button			#btnFindObject	"f"			#pressed	"pos:[304,48]	width:16	height:16	images:(fnReturnFilename  #plFind)	toolTip:\"Find objects width this texture\" aligh:#right",
		_controlData	#button			#BtnUndefine	"u"			#pressed	"pos:[88,64]	width:16	height:16	images:(fnReturnFilename  #plDel)	toolTip:\"Undefine bitmap\"",
		_controlData	#button			#btnReload		"r"			#pressed	"pos:[104,64]	width:16	height:16	images:(fnReturnFilename  #plReload)	toolTip:\"Reload bitmap\"",
		_controlData	#checkbutton	#btnShowBitmap	"s"			#changed	"pos:[272,64]	width:16	height:16	images:(fnReturnFilename  #plShow1)	toolTip:\"Show bitmap in viewport\"",
		_controlData	#checkbutton	#btnShowAlpha	"a"			#changed	"pos:[288,64]	width:16	height:16	images:(fnReturnFilename  #plShow2)	toolTip:\"Show alpha channel in viewport\"",
		_controlData	#checkbutton	#btnShowTransp	"t"			#changed	"pos:[304,64]	width:16	height:16	images:(fnReturnFilename  #plShow3)	toolTip:\"Show transparent bitmap in viewport\"",
		_controlData	#label			#lbl2			"Size:"		#none		"pos:[128,66]	width:24	height:16	enabled:false",
		_controlData	#label			#lblSize		""			#none		"pos:[152,66]	width:120	height:16	enabled:false",
--		_controlData	#label			#lbl3			"Path:"		#none		"pos:[88,82]	width:32	height:16	enabled:false",
--		_controlData	#label			#lblPath		""			#none		"pos:[120,82]	width:200	height:16	enabled:false"
		-- DTA_WATER, DTA_GLASS
		_controlData	#groupBox		#grp1			"Waves Shifting"	#none			"pos:[8,8]		width:152	height:56",
		_controlData	#spinner		#spnShiftX		"X:"				#changed		"pos:[24,24]	width:56	height:16	range:[-99999,99999,1] type:#float scale:0.01",
		_controlData	#spinner		#spnShiftY		"Y:"				#changed		"pos:[24,40]	width:56	height:16	range:[-99999,99999,1] type:#float scale:0.01",
		_controlData	#spinner		#spnShiftU		"U:"				#changed		"pos:[96,24]	width:56	height:16	range:[-99999,99999,1] type:#float scale:0.01",
		_controlData	#spinner		#spnShiftV		"V:"				#changed		"pos:[96,40]	width:56	height:16	range:[-99999,99999,1] type:#float scale:0.01",
		_controlData	#groupBox		#grp2			"Diffuse / Environment"	#none		"pos:[168,88]	width:152	height:40",
		_controlData	#spinner		#spnBlend		"Blend coefficient:"	#changed	"pos:[224,104]	width:88	height:16	range:[-1,1,0.6] type:#float scale:0.01",
		_controlData	#groupBox		#grp3			"Sharpness"			#none			"pos:[168,8]	width:152	height:72",
		_controlData	#spinner		#spnDiff1		"Diffuse 1:"		#changed		"pos:[224,24]	width:88	height:16	range:[0,999,0.6] type:#float scale:0.01",
		_controlData	#spinner		#spnDiff2		"Diffuse 2:"		#changed		"pos:[224,40]	width:88	height:16	range:[0,999,0.6] type:#float scale:0.01",
		_controlData	#spinner		#spnEnv			"Environment:"		#changed		"pos:[217,56]	width:95	height:16	range:[0,999,0.6] type:#float scale:0.01",
		_controlData	#groupBox		#grp4			"Alpha factor"		#none			"pos:[8,88]		width:152	height:40",
		_controlData	#spinner		#spnAngle		"Angle:"			#changed		"pos:[80,104]	width:72	height:16	range:[-1,1,0.3] type:#float scale:0.01"
	)

	-- create or open file
	if file do 
		for n = 1 to _tmpFile.count do
			if (fnFindFile _tmpFile[n] #("")) == undefined then
				fFile[n] = createFile _tmpFile[n]
			else
				fFile[n] = openFile _tmpFile[n] mode:"wt"

	-- create rollout
	for r = 1 to pteroLayerDefinition.count do (
		roc = rolloutCreator pteroLayerDefinition[r].name pteroLayerDefinition[r].label

		roc.begin()
		roc.addLocal "_name"
		roc.addLocal "_label"
		roc.addLocal "_texID"
		for c = 1 to rolloutControlsDef.count do
			if (findItem pteroLayerDefinition[r].items rolloutControlsDef[c].name) > 0 do (
				roc.addControl	rolloutControlsDef[c].type rolloutControlsDef[c].name rolloutControlsDef[c].label \
								paramStr:rolloutControlsDef[c].params
				if rolloutControlsDef[c].event_type != #none do
					roc.addHandler	rolloutControlsDef[c].name rolloutControlsDef[c].event_type \
									paramStr:(if rolloutControlsDef[c].event_type == #pressed or rolloutControlsDef[c].event_type == #click then "" else "val") \
									codeStr:("fnUtilizeTexture _texID #" + rolloutControlsDef[c].name + (if rolloutControlsDef[c].event_type == #pressed or rolloutControlsDef[c].event_type == #click then "" else " state:val"))
			)
		roc.addText ("fn fnName = " + pteroLayerDefinition[r].name as string)
		roc.addText	("fn fnLabel = @" + pteroLayerDefinition[r].label + "@") filter:true
		roc.addText ("fn fnTexID = " + pteroLayerDefinition[r].texID as string) --rolloutsDef[r].texID as string)
		roc.addText	str
		roc.addHandler	pteroLayerDefinition[r].name #open codeStr:"_name = fnName()\n_label = fnLabel()\n_texID = fnTexID()\nfnUpdateUI #all\nfnOpenRollOut _name" --\nfnUpdateUI()"
		roc.addHandler	pteroLayerDefinition[r].name #close codeStr:"fnCloseRollOut _name"
		roc.end()

		-- insert "rolledup" tag
		for n = 1 to roc.str.count do
			if roc.str[n] == "\n" do (
				roc.str = replace roc.str n 1 " rolledUp:true\n"
				exit
			)
			
		-- save source of rollout to file
		if file do (
			format (roc.str + "\n") to:fFile[1]
			format ("fnAppendRollOut " + roc.name as string + " \"" + roc.caption + "\"\n\n") to:fFile[2]
		)

--		append _PteroLayerRollouts (_roListInfo	roc.def roc.caption r) --(name, label, tex_id)
	)

	-- close file
	if file do (
		close fFile[1]
		close fFile[2]
	)
	
	return true
)
-- Cretate Rollouts
fnCreateRollouts()

---------------------------------------------------------------
--	fnDrawBitmapLine()
---------------------------------------------------------------
fn fnDrawBitmapLine bmp lineStart lineEnd color = (
-- stick the colour into an array
local ary = #(color)

-- assign originals
local Xb = lineStart.x as integer
local Yb = lineStart.y as integer

-- build the line deltas
local dX = lineEnd.x-lineStart.x as float
local dY = lineEnd.y-lineStart.y as float

-- straight horiz 
if dy == 0.0f do (
	local xsign = 1
	if xb > lineEnd.x then xsign = 1 as integer
	if lineEnd.x < xb then xsign = -1 as integer
	
			setPixels bmp [xb,yb] ary
			while xb != lineEnd.x do
				(
					xb += xsign 
					setPixels bmp [xb,yb] ary
				)
				return true
)
-- straight vertical 
if dx == 0.0f do (
	local ysign = 1
	if yb > lineEnd.y then ysign = 1 as integer
	if lineEnd.y < yb then ysign = -1 as integer
	
			setPixels bmp [xb,yb] ary
			while yb != lineEnd.y do
				(
					yb += ysign 
					setPixels bmp [xb,yb] ary
				)
				return true

)

-- no straights, go for bresenham line slide

-- set up the movements
	local xsign = 1
	if xb > lineEnd.x then xsign = 1 as integer
	if lineEnd.x < xb then xsign = -1 as integer
	local ysign = 1
	if yb > lineEnd.y then ysign = 1 as integer
	if lineEnd.y < yb then ysign = -1 as integer
	dx = abs(dx)
	dy = abs(dy)
	setPixels bmp [xb,yb] ary
	
-- line more vertical than horizontal
	if dx < dy then
	(
		p = 2 * dx - dy
		const1 = 2 * dx
		const2 = 2 * (dx - dy)
		while yb != lineEnd.y do
		(
			yb += ysign
			if p < 0 then ( p = p + const1 )
			else
			(	
				p += const2
				xb += xsign
			)
			setPixels bmp [xb,yb] ary
		)
	)
	
--	line more horizontal than vertical
	else
	(
		p = 2 * dy - dx
		const2 = 2 * (dy - dx)
		const1 = 2 * dy
		while xb != lineEnd.x do
		(
			xb = xb + xsign
			if  p < 0 then ( p = p + const1 )
			else
			(	p = p + const2
				yb = yb + ysign
			)
			setPixels bmp [xb,yb] ary
		)
	)
)

---------------------------------------------------------------
-- mtMeasureDistance
---------------------------------------------------------------
global isMeasureActive = false
tool mtMeasureDistance
( 
	local clr = (color 255 234 0)
	local dist = 0
	local begin, end, rope
	
	-- on screen distance info
	fn fnDoStr = (
		local strPos = [5, ((getViewSize()).y - 65), 0]
		local str = "Distance = " + dist as string
		local rect = gw.getTextExtent str
		local updateRect = box2 (strPos.x) (strPos.y-rect.y) (rect.x+1) (rect.y+1)
		gw.clearscreen updateRect useBkg:true
		gw.wText strPos str color:clr
		gw.enlargeUpdateRect updateRect
		gw.updateScreen() 
	)
	on mousePoint click do 
		if click == 1 then (
			local hSize = 4 * (getMaxWindowSize()).x / (getViewSize()).x
			-- create begin, rope and end
			begin	= point pos:worldPoint size:hSize box:true cross:false wireColor:clr constantScreenSize:true --drawOnTop:true
			end		= point pos:worldPoint size:hSize box:true cross:false wireColor:clr constantScreenSize:true --drawOnTop:true
			rope	= line numSplines:1 wireColor:clr
			addNewSpline rope
			addKnot rope 1 #corner #line worldPoint
			addKnot rope 1 #corner #line worldPoint
			upDateShape rope
			-- register on screen distance info
			registerRedrawViewsCallback fnDoStr
		) else #stop
	on mouseMove click do
		if click == 2 then (
			-- compute distance
			dist = ((distance begin.pos end.pos) * 100 ) as integer / 100.0
			if oldDist != dist do (
				-- set end pos
				end.pos = worldPoint
				-- set end pos for rope
				setKnotPoint rope 1 2 worldPoint
				upDateShape rope

				oldDist = dist
			)
		) else #stop
	on mouseAbort val do dist = 0
	on stop do (
		-- delete helpers
		try (delete #(begin, end, rope)) catch ()
		-- unregister on screen distance info
		unregisterRedrawViewsCallback fnDoStr
		completeRedraw()
		return dist
	)
)

---------------------------------------------------------------
-- mtMeasureDistance
---------------------------------------------------------------
struct _CSVData (names = (), ids = (), count = 9999)
fn fnParseCSV file =
(
	local f = openFile file mode:"rt"
	local CSVData = _CSVData #() #()
	local fLine = ""
	local arrayCount = 1
	
	-- if file exists continue
	if f != undefined then
	(		
		-- parse file
		while (not (eof f)) and (arrayCount < 3) do
		(
			fLine = readLine f
		
			for n = 1 to fLine.count do
				case arrayCount of
				(
					1: -- parse Names	- line 1
					(
						if fLine[n] == ";" then
							CSVData.names[CSVData.names.count + 1] = ""
						else
							CSVData.names[CSVData.names.count] += fLine[n] 
					)
					2: -- parse IDs		- line 2
					(
						if fLine[n] == ";" then
						(
							if CSVData.ids.count > 0 do
								CSVData.ids[CSVData.ids.count] = CSVData.ids[CSVData.ids.count] as integer
							CSVData.ids[CSVData.ids.count + 1] = ""
						)
						else
							CSVData.ids[CSVData.ids.count] += fLine[n] 
					)
				)
			arrayCount += 1
		)
	)
	else
		messageBox ("Can't locate file:\n" + file) title:"pteroTools: CSV parser"
	
	-- get lowest count
	CSVData.count = if CSVData.ids.count > CSVData.names.count then CSVData.names.count else CSVData.ids.count

	return CSVData
)

---------------------------------------------------------------
-- fnUpdateMenu
---------------------------------------------------------------
fn fnUpdateMenu PTMenuTitle menuItems = (
	local mainMenuBar = menuMan.getMainMenuBar()
	local PTSeparator = menuMan.createSeparatorItem() 
	local PTSubMenu
	local PTItem

	if menuMan.registerMenuContext 0x6e66d2fe then
	(	-- install pteroTools Menu
		local PTMenu = menuMan.createMenu PTMenuTitle
		-- add menu items
		for i in menuItems do
		(
			if i == "-" then
				PTMEnu.addItem PTSeparator -1
			else
			(
				PTItem = menuMan.createActionItem i PTMenuTitle
				PTMenu.addItem PTItem -1
			)
		)
		-- add menu do Main menu		
		PTSubMenu = menuMan.createSubMenuItem PTMenuTitle PTMenu
		mainMenuBar.addItem PTSubMenu (mainMenuBar.numItems()-1)
	)
	else
	(	-- update pteroTools menu
		local PTMenu = mainMenuBar
		local doMenu = false
		
		-- find menu
		for n = 1 to menuMan.numMenus() do
			if ((menuMan.getMenu n).getTitle()) == PTMenuTitle do
			(
				PTMenu = menuMan.getMenu n
				exit
			)
		-- compare menu items
		if menuItems.count == PTMenu.numItems() then
		(
			for n = 1 to menuItems.count do
			(
				local PTMenuItem = (PTMenu.getItem n).getTitle()
				
				PTItem = menuMan.createActionItem menuItems[n] PTMenuTitle
				if PTItem == undefined then PTItem = "" else PTItem = PTItem.getTitle()
				
				if PtMenuItem != PTItem do
				(
					doMenu = true
					exit
				)
			)
		)
		else
		(
			doMenu = true
		)

		if doMenu do
		(
			-- remove old menu items
			while 1 <= PTMenu.numItems() do
				PTMenu.removeItemByPosition 1
			-- add menu items
			for i in menuItems do
				if i == "-" then
					PTMEnu.addItem PTSeparator -1
				else
				(
					PTItem = menuMan.createActionItem i PTMenuTitle
					PTMenu.addItem PTItem -1
				)
		)
	)

	menuMan.updateMenuBar()
)

---------------------------------------------------------------
-- fnReplaceFuckedMaterial
---------------------------------------------------------------
fn fnReplaceFuckedMaterial oldMat =
(
	local newName = if (findString oldMat.name " - fixed") == undefined then (oldMat.name + " - fixed") else oldMat.name
	local newMat = pteroMaterial name:newName

	-- standard
	newMat.spinnerOpacity = oldMat.spinnerOpacity
	newMat.pickerMAXcolor = oldMat.pickerMAXcolor
	newMat.checkFaceted = oldMat.checkFaceted
	
	-- single
	newMat.PRM_COLLISION_TYPE = oldMat.PRM_COLLISION_TYPE
	newMat.PRM_TRANSPARENT_TYPE = oldMat.PRM_TRANSPARENT_TYPE
	newMat.PRM_GROW_TYPE = oldMat.PRM_GROW_TYPE
	newMat.PRM_GRASS_TYPE = oldMat.PRM_GRASS_TYPE
	newMat.PRM_ENVIRONMENT_TYPE = oldMat.PRM_ENVIRONMENT_TYPE
	newMat.PRM_DIFF2_TILE = oldMat.PRM_DIFF2_TILE
	newMat.PRM_LIGHT = oldMat.PRM_LIGHT
	newMat.PRM_MIPMAP_OVERLAY = oldMat.PRM_MIPMAP_OVERLAY

	-- array
	for k = 1 to 24 do
	(
		-- main
		newMat.PRM_MIPMAP[k] = oldMat.PRM_MIPMAP[k]
		newMat.maps[k] = oldMat.maps[k]
		newMat.mapIsUsed[k] = oldMat.mapIsUsed[k]
		-- delegate
		if k > 12 do
			newMat.delegate.maps[k] = oldMat.delegate.maps[k]
	)
	
	return newMat
)

---------------------------------------------------------------
-- fnReplaceOneMaterial
---------------------------------------------------------------
fn fnReplaceOneMaterial mat newMat:undefined =
(
	if newMat == undefined do newMat = fnReplaceFuckedMaterial mat
	
	for obj in $* do
	(
		if obj.material != undefined then
		(
			if obj.material.classid[1] == 512 and obj.material.classid[2] == 0 then
				for sm = 1 to obj.material.count do (
					if obj.material[sm] != undefined then
					(
						if obj.material[sm].classid[1] == 0x654df3d2 and obj.material[sm].classid[2] == 0x64da69d9 do
							if obj.material[sm] == mat do
								obj.material[sm] = newMat
					)
					else
					()
				)
			else if obj.material.classid[1] == 0x654df3d2 and obj.material.classid[2] == 0x64da69d9 do
				if obj.material == mat do
					obj.material = newMat
		)
		else continue
	)

	for m = 1 to meditMaterials.count do
		if meditMaterials[m].classid[1] == 512 and meditMaterials[m].classid[2] == 0 then
		(
			-- multiMat
			for sm = 1 to meditMaterials[m].count do
				if meditMaterials[m][sm] != undefined then
				(
					if meditMaterials[m][sm].classid[1] == 0x654df3d2 and meditMaterials[m][sm].classid[2] == 0x64da69d9 do
						-- pteroMat in MultiMat
						if meditMaterials[m][sm] == mat do
							meditMaterials[m][sm] = newMat
				)
				else
				()
		)
		else if meditMaterials[m].classid[1] == 0x654df3d2 and meditMaterials[m].classid[2] == 0x64da69d9 do
			-- pteroMat
			if meditMaterials[m] == mat do
				meditMaterials[m] = newMat
)

---------------------------------------------------------------
-- fnReplaceOneMaterial
---------------------------------------------------------------
fn fnReplaceAllMaterials =
(
	local excludeMats = #()
	
	for obj in $* do
	(
		if obj.material != undefined do
			if obj.material.classid[1] == 512 and obj.material.classid[2] == 0 then
				for sm = 1 to obj.material.count do
					if obj.material[sm] != undefined do
						if obj.material[sm].classid[1] == 0x654df3d2 and obj.material[sm].classid[2] == 0x64da69d9 do
							if (findItem excludeMats obj.material[sm]) == 0 do
							(
								fnReplaceOneMaterial obj.material[sm]
								append excludeMats obj.material[sm]
							)
			else if obj.material.classid[1] == 0x654df3d2 and obj.material.classid[2] == 0x64da69d9 do
						if (findItem excludeMats obj.material) == 0 do
						(
							fnReplaceOneMaterial obj.material
							append excludeMats obj.material
						)
	)
)

---------------------------------------------------------------
-- fnRemoveFuckedMultimat
---------------------------------------------------------------
fn fnRemoveFuckedMultimat =
(
	local newMat = standard()
	local ret = #()
	local txt
	
	assignNewName newMat
	
	ret = #("New material name: '" + newMat.name + "'", "---------------------------------------------------------------------------------")
	
	for obj in $* do
		if obj.material != undefined do
			if obj.material.classid[1] == 512 and obj.material.classid[2] == 0 do
				for sm = 1 to obj.material.numsubs do
					if obj.material.materialList[sm] != undefined do
						if obj.material.materialList[sm].classid[1] == 512 and obj.material.materialList[sm].classid[2] == 0 do
						(
							txt = "Replaced slot ID:  " + (obj.material.materialIDlist[sm] as string) + "   in '" + obj.material.name + "'"
							if (findItem ret txt) == 0 do
								append ret txt
							obj.material.materialList[sm] = newMat
						)

	for m = 1 to meditMaterials.count do
		if meditMaterials[m].classid[1] == 512 and meditMaterials[m].classid[2] == 0 do
			for sm = 1 to meditMaterials[m].numsubs do
				if meditMaterials[m].materialList[sm] != undefined do
					if meditMaterials[m].materialList[sm].classid[1] == 512 and meditMaterials[m].materialList[sm].classid[2] == 0 do
					(
						txt = "Replaced slot ID:  " + (meditMaterials[m].materialIDlist[sm] as string) + "   in '" + meditMaterials[m].name + "'"
						if (findItem ret txt) == 0 do
							append ret txt
						meditMaterials[m].materialList[sm] = newMat
					)
						
	return ret
)

---------------------------------------------------------------
-- fnCompareMaterials
---------------------------------------------------------------
fn fnCompareMaterials mat1 mat2 =
(
	local ret = true
	
	if (mat1 == undefined) or (mat2 == undefined) do return false
	
	local ci = mat1.classid
	
	if (classOf mat1) != (classOf mat2) then ret = false
	else if mat1.name != mat2.name then ret = false
	else if (classOf mat1) == pteroMaterial then
	(
		if mat1.PRM_COLLISION_TYPE			!= mat2.PRM_COLLISION_TYPE then ret = false
		else if mat1.PRM_TRANSPARENT_TYPE	!= mat2.PRM_TRANSPARENT_TYPE then ret = false
		else if mat1.PRM_GROW_TYPE			!= mat2.PRM_GROW_TYPE then ret = false
		else if mat1.PRM_GRASS_TYPE			!= mat2.PRM_GRASS_TYPE then ret = false
		else if mat1.PRM_ENVIRONMENT_TYPE	!= mat2.PRM_ENVIRONMENT_TYPE then ret = false
		else if mat1.PRM_DIFF2_TILE			!= mat2.PRM_DIFF2_TILE then ret = false
		else if mat1.PRM_LIGHT				!= mat2.PRM_LIGHT then ret = false
		else if mat1.PRM_MIPMAP_OVERLAY		!= mat2.PRM_MIPMAP_OVERLAY then ret = false
		else for n = 1 to mat1.maps.count do
			if mat1.maps[n] != undefined and mat2.maps[n] != undefined then
			(
				if mat1.PRM_MIPMAP[n] != mat2.PRM_MIPMAP[n] then
				(
					ret = false
					exit
				)
				else if mat1.mapIsUsed[n] != mat2.mapIsUsed[n] then
				(
					ret = false
					exit
				)
				else if (fnDnCase (copy mat1.maps[n].filename)) != (fnDnCase (copy mat2.maps[n].filename)) then
				(
					ret = false
					exit
				)
			) else if mat1.maps[n] != mat2.maps[n] do
				(
					ret = false
					exit
				)
	)
	else if (ci[1] == 1222670497) and (ci[2] == 782138873) then -- pteroLayer
	(
		if mat1.surface					!= mat2.surface then ret = false
		else if mat1.grassType			!= mat2.grassType then ret = false
		else if mat1.growType			!= mat2.growType then ret = false

		else if mat1.shaderType			!= mat2.shaderType then ret = false
		else if mat1.shaderFilename		!= mat2.shaderFilename then ret = false
		else if mat1.subShaderType		!= mat2.subShaderType then ret = false
		else if mat1.transparency		!= mat2.transparency then ret = false
		else if mat1.twoSided			!= mat2.twoSided then ret = false
		else if mat1.faceted			!= mat2.faceted then ret = false

		else if mat1.layerOrder			!= mat2.layerOrder then ret = false
		else if mat1.layerMipmap		!= mat2.layerMipmap then ret = false
		else if mat1.layerTileU			!= mat2.layerTileU then ret = false
		else if mat1.layerTileV			!= mat2.layerTileV then ret = false
		else if mat1.layerTilingU		!= mat2.layerTilingU then ret = false
		else if mat1.layerTilingV		!= mat2.layerTilingV then ret = false
		else if mat1.layerMove			!= mat2.layerMove then ret = false
		else if mat1.layerMoveType		!= mat2.layerMoveType then ret = false
		else if mat1.layerMoveSoft		!= mat2.layerMoveSoft then ret = false
		else if mat1.layerMoving		!= mat2.layerMoving then ret = false
		else if mat1.layerChannel		!= mat2.layerChannel then ret = false
		else if mat1.layerFilename		!= mat2.layerFilename then ret = false

		else if mat1.isWater			!= mat2.isWater then ret = false
		else if mat1.isGlass			!= mat2.isGlass then ret = false
		else if mat1.waterEnvBlend		!= mat2.waterEnvBlend then ret = false
		else if mat1.waterAlphaAngle	!= mat2.waterAlphaAngle then ret = false
		else if mat1.waterSharpness		!= mat2.waterSharpness then ret = false
		else if mat1.waterShiftingXY	!= mat2.waterShiftingXY then ret = false
		else if mat1.waterShiftingUV	!= mat2.waterShiftingUV then ret = false

		else if mat1.OverlayMultitex	!= mat2.OverlayMultitex then ret = false
		else if mat1.LMApplyLight		!= mat2.LMApplyLight then ret = false
		else if mat1.EnvType			!= mat2.EnvType then ret = false

		else if mat1.matDiffuse				!= mat2.matDiffuse then ret = false
		else if mat1.matAmbient			!= mat2.matAmbient then ret = false
		else if mat1.matSpecular		!= mat2.matSpecular then ret = false
		else if mat1.matSelfIllum		!= mat2.matSelfIllum then ret = false
		else if mat1.matOpacity			!= mat2.matOpacity then ret = false
		else if mat1.matOpacityFalloff	!= mat2.matOpacityFalloff then ret = false
		else if mat1.matGlossiness		!= mat2.matGlossiness then ret = false
		else if mat1.matSpecLevel		!= mat2.matSpecLevel then ret = false
	)
	else if mat1 != mat2 then ret = false

	return ret
)

-- EOF
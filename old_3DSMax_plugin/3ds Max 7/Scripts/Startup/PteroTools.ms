
---------------------------------------------------------------
--
-- PteroTools
--
-- by Pan Collette
--
-- Create: 14.05.2003
-- Modified: 06.01.2004
--
-- !!!  PteroLib.mse MUST be incuded FIRST  !!!
--
-- MODIFY THIS AT YOUR OWN RISK 
--
---------------------------------------------------------------

---------------------------------------------------------------
--	Init PteroTools
---------------------------------------------------------------
global _DEBUG_		= false
global _ADMINS_		= #("ZADR") --, "BENY")
global _IS_ADMIN_	= (findItem _ADMINS_ (sysInfo.computername))

(
	local _path  = "$scripts\\pteroTools\\"
	local _del	 = #( "$ui\\MacroScripts\\Macro_PteroProps.mcr", _path + "_aboutRollOut.ms", _path + "_physicsRollOut.msp", _path + "_ladderRollOut.msp" )
	local _inc, c

	if _IS_ADMIN_ != 0 then
	(
		-- main lib
		_inc  = #( _path + "_src\\pteroLib.ms" )
		-- materials
		_inc += #( _path + "_src\\pteroMat.ms" )
		_inc += #( _path + "_src\\pteroMultiLayer.ms", _path + "pteroLayer.ms", _path + "_src\\pteroLight.ms", _path + "_src\\pteroHelpers.ms" )
		-- modifiers
		_inc += #( _path + "_src\\pteroUnwrap.ms" )
		-- tools
		_inc += #( _path + "_src\\pteroProps.ms", _path + "pteroPropsInclude.ms" )
		_inc += #( _path + "_src\\pteroTools.ms" )
		_inc += #( _path + "_src\\pteroSectorChecker.ms" )
		_inc += #( _path + "_src\\checkNodesVertDist.ms" )
		_inc += #( _path + "_src\\pteroMatToPteroLayer.ms" )
		_inc += #( _path + "_src\\ConvertPteroMatToStandard.ms")
		-- gui macro
		_inc += #( "$ui\\MacroScripts\\pteroTools.mcr" )
	)
	else
	(
		-- main lib
		_inc  = #( _path + "_src\\pteroLib.ms" )
		-- materials
		_inc += #( _path + "_src\\pteroMat.ms" )
--		_inc += #( _path + "_src\\pteroMultiLayer.ms")
		_inc += #( _path + "pteroLayer.ms", _path + "_src\\pteroHelpers.ms" )
		-- modifiers
		_inc += #( _path + "_src\\pteroUnwrap.ms" )
		-- tools
		_inc += #( _path + "_src\\pteroProps.ms", _path + "pteroPropsInclude.ms" )
		_inc += #( _path + "_src\\pteroTools.ms" )
		_inc += #( _path + "_src\\pteroSectorChecker.ms" )
		_inc += #( _path + "_src\\checkNodesVertDist.ms" )
		_inc += #( _path + "_src\\pteroMatToPteroLayer.ms" )
		_inc += #( _path + "_src\\ConvertPteroMatToStandard.ms")
		-- gui macro
		_inc += #( "$ui\\MacroScripts\\pteroTools.mcr" )
/*
		_inc  = #( _path + "pteroLib.mse" )
		_inc += #( _path + "pteroMat.mse" )
		_inc += #( _path + "pteroLayer.ms")
		_inc += #( _path + "pteroHelpers.mse" )
		_inc += #( _path + "pteroProps.mse", _path + "pteroPropsInclude.ms")
		_inc += #( _path + "pteroTools.mse", "$ui\\MacroScripts\\pteroTools.mcr" )
*/
	)

	-- increment MAXScript working memory + 5MB
	heapSize += 5000000
	
	-- delete old files
	if _IS_ADMIN_ == 0 do
		for f in _del do
		(
			c = ( getfiles f ).count
			if c == 1 do try
			(
				setFileAttribute f #readOnly false
				deleteFile f
			) catch ()
		)

	-- run scripts
	for f in _inc do
	(
		c = ( getfiles f ).count
		case c of
		(
			1:
			(
				if _IS_ADMIN_ != 0 then
					fileIn f
				else
					try( fileIn f ) catch (format "Error: PteroTools - executing script: %\n" f)
			)
			default:	format "Error: PteroTools - unable to execute script: %\n" f
		)
	)

)

---------------------------------------------------------------
--	fnDoCallback()
---------------------------------------------------------------
fn fnDoCallback type:#all = try (
	local pos = 1
	local mat, open, col, r, g, b
	local menuItems = #("PteroProps", "FindSpikeFaces", "SectorChecker", "UnwantedMoveFinder", "PrintMappingToBitmap", "msHierarchyClipboard", "ExportAdv", "-", "ReplaceSelection", "CreateBBox", "-", "PteroMatToPteroLayer", "PteroMatToStandard", "FindNoCollide", "EnableBitmapsInViewport", "ReplaceMaterial", "ReplaceMultimat", "msOptimizeMultimats", "UnassignMaterial", "-", "MeasureDistance", "ShowLODs", "PteroBesInfo", "PteroColMatList", "-", "PteroToolsSettings")
	local PTMenuTitle = "PteroTools"

	-- install pteroTools Menu
	fnUpdateMenu PTMenuTitle menuItems
	
	-- read Collision materials
	if _IS_ADMIN_ != 0 then
		_colMatTable = fnReturnColMats type:#ini
	else
		_colMatTable = fnReturnColMats()
	if _colMatTable[2] == undefined do _colMatTable = fnLoadMats()

	if type == #all do (
		-- open PteroProps Panel
		if (open = fnLoadINIexec "DialogOpen" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok do
			open = true
		if open do fnCreatePteroProps()

		-- check new scripts
		fnCheckNewScripts()
		
		-- setup shader list
--		if _IS_ADMIN_ != 0 do
		pteroShaderList.fnUpdate()
	)
	updateToolbarButtons()
	
	-- clear unused callbacks
	callbacks.removeScripts id:#postStartupPteroToolsInit
) catch ()

---------------------------------------------------------------
--	fnDoCheckImport()
---------------------------------------------------------------
fn fnDoCheckImport =
(
	for n in $* do
	(
		if (classof n) == pLight then n.type = n.type
	)
)
---------------------------------------------------------------
-- Callbacks definition
---------------------------------------------------------------
callbacks.addScript #postSystemStartup "fnDoCallback()" id:#postStartupPteroToolsInit
callbacks.addScript #filePostOpen "fnDoCallback()" id:#postStartupPteroToolsInit
callbacks.addScript #postImport "fnDoCheckImport()" id:#postImportPteroTools
---------------------------------------------------------------
--
-- PteroPropsInclude
--
-- by Pan Collette
--
-- Create: 13.01.2003
-- Modified: 29.12.2003
--
---------------------------------------------------------------

-----------------------------------------------
-- rollout ShowPropsRollOut
-----------------------------------------------
rollout ShowPropsRollOut "Properties Info" (
	-- init GUI
	edittext	edtProps	pos:[0,4]	width:(_mainRollout.min_width / 1.1)	height:(_mainRollout.min_width * 1.5)

	-- Init RollOut
	fn fnName		= ShowPropsRollOut
	fn fnLabel		= "ShowProps"
 	fn fnKeyNames	= #( fnLabel() )
 	fn fnKeyUI		= #( #() )
 	fn fnKeyDef		= #( #() )
	fn fnInitRollOut = (
		fnAppendRollOut (fnName()) (fnLabel()) order:2
	)

	-- Event Handler
	on edtProps entered val		do fnSetProps (fnName()) edtProps
	on ShowPropsRollOut	open	do (
		fnOpenRollOut (fnName())
		fnGetPropsToShow (fnName()) edtProps
	)
	on ShowPropsRollOut	close	do fnCloseRollOut (fnName())
)

-----------------------------------------------
-- rollout ButtonsRollOut
-----------------------------------------------
rollout ButtonsRollOut "Types" rolledUp:false (
	local _mainWidth = _mainRollout.min_width

	-- init GUI
	include "$scripts\\pteroTools\\plug_tmp_btn.ppb"

	-- Init RollOut
	fn fnName		= ButtonsRollOut
	fn fnLabel		= "Types"
 	fn fnKeyNames	= #( fnLabel() )
 	fn fnKeyUI		= #( #() )
 	fn fnKeyDef		= #( #() )
	fn fnInitRollOut = (
		fnAppendRollOut (fnName()) (fnLabel()) order:1
	)

	-- event handles
	on ButtonsRollOut	open	do (
		--fnOpenRollOut (fnName())
	)
	on ButtonsRollOut	close	do (
		--fnCloseRollOut (fnName())
	)
)

-----------------------------------------------
-- rollout mainRollout
-----------------------------------------------
rollout mainRollout	"PteroProps Panel" rolledUp:false (
	-- include rollouts
	include "$scripts\\pteroTools\\plug_tmp_inc.ppb"
	
	--	mainRollout gui
	subrollout	sroWindow1	pos:[0,_mainRollout.buttons_offset]	width:_mainRollout.min_width
	subrollout	sroWindow2	pos:[_mainRollout.min_width, 0]		width:_mainRollout.min_width
	subrollout	sroWindow3	pos:[2*_mainRollout.min_width, 0]	width:_mainRollout.min_width
	subrollout	sroWindow4	pos:[3*_mainRollout.min_width, 0]	width:_mainRollout.min_width
	label		lbl1			""					pos:[4,6]		width:(_mainRollout.min_width - 12 - 16)
	label		lbl2			""					pos:[4,24]		width:(_mainRollout.min_width - 80 - 16)
	button		btnAbout		"?"					pos:[156,6]		width:16	height:16										toolTip:"About PteroProps Panel"
	checkbutton	btnLock			"L"					pos:[156,24]	width:16	height:16	images:(fnReturnFilename #lck2Icon)	toolTip:"Pin PteroProps Panel"
	checkbutton	chkDockLeft		"<"					pos:[124,24]	width:16	height:16	images:(fnReturnFilename #dckLeft)	toolTip:"Dock Left"
	checkbutton	chkDockRight	">"					pos:[140,24]	width:16	height:16	images:(fnReturnFilename #dckRght)	toolTip:"Dock Right"
--	button		btnSettings		"S"					pos:[124,24]	width:16	height:16	visible:false						toolTip:"PteroTools Settings"
	groupBox	grp1			"Apply All"			pos:[4,40]		width:(_mainRollout.min_width - 12)	height:56
	button		btnSet			"Set"				pos:[14,56]		width:28	height:18	images:(fnReturnFilename #setIcon)	toolTip:"Set All Properties"
	checkbutton	btnAcq			"Acquire"			pos:[44,56]		width:28	height:18	images:(fnReturnFilename #acqIcon)	toolTip:"Acquire All Properties From Node ..."
	button		btnDef			"Template"			pos:[74,56]		width:28	height:18	images:(fnReturnFilename #defIcon)	toolTip:"Use All Templates"
	button		btnSav			"Save Template"		pos:[104,56]	width:28	height:18	images:(fnReturnFilename #savIcon)	toolTip:"Save All Templates"
	button		btnDel			"Delete"			pos:[134,56]	width:28	height:18	images:(fnReturnFilename #delIcon)	toolTip:"Delete All Properties"
	checkbox	chkApplyOpen	"Apply Open Types Only"			pos:[24,76]
	button		btnrefresh		"...:::  REFRESH  :::..."		pos:[4,102]			width:(_mainRollout.min_width - 12)	height:20
	checkbox	chkAuto			"Auto Refresh Types (slow)"		pos:[16,126]

	-- Init RollOut
	fn fnName		= mainRollout
	fn fnLabel		= "PteroProps Panel"

	-- fnPrintLabel()
	fn fnPrintLabel = (
		local i = 0
		local nameStr = ""
		local faceStr = ""
		case selection.count of (
			0 : (
					nameStr += "None Selected"
					faceStr += "0"
				)
			1 : (
					nameStr += $.name
					faceStr += try ( ( $.mesh.numfaces ) as string ) catch ( "0" )
				)
			default : (
					for n in selection do i += try ( n.mesh.numfaces ) catch ( 0 )
					nameStr += selection.count as string + " Selected"
					faceStr += i as string
				)
		)
		faceStr += " Faces"

		fnSetControlValue (fnName()) lbl1 (fnCutString s:nameStr length:(_mainRollout.min_width - 12))
		fnSetControlValue (fnName()) lbl2 (fnCutString s:faceStr length:(_mainRollout.min_width - 80))
		return true
	)

	--	fnUtilize()
	fn fnUtilize name info:false type:#none = (
		local ro = fnFindRollOut ShowPropsRollOut

--		if selection.count == 0 do return 0
		
		-- fnUtilizeApply()
		fn fnUtilizeApply type = (
			-- fnDoApply()
			fn fnDoApply ro type =
			(
				for n = 1 to ro.count_keys do
					ro.name.fnUpdate keyIDX:n type:type inner:false
			)

			-- compare props in multisel
			if selection.count > 1 and type == #read then
			(
				local goForIt = true
				local n = 1

				while n < selection.count and goForIt do
				(
					local buff1 = getUserPropBuffer selection[n]
					local buff2 = getUserPropBuffer selection[n+1]
					local t = 1
					
					if buff1.count != buff2.count then
					(
						goForIt = false
					)
					else while t <= buff1.count and goForIt do
					(
						if buff1[t] != buff2[t] then
						(
							goForIt = false
						)
						t += 1
					)

					n += 1
				)
				
				if goForIt then
					type = #multiSame
				else
					type = #multiDiff
			)
			
			-- do apply props
			for ro in _rolloutsTable do
			(
				if not ro.isMain do
				(
					if _mainRollout.applyOpen do if not ro.isOpen do continue
					fnDoApply ro type
				)
			)
		)

		case type of (
			#acquire:	fnAcquire name
			#none:		()
			default:	(
				fnUtilizeApply type
/*				if type == #load or type == #acquire do
					fnUtilizeApply #write
*/			)
		)

		if type != #save or info do
			fnGetPropsToShow ro.name ro.name.controls[1]
		if type == #read or info do
			fnPrintLabel()
	)

	--	event handles
	on chkAuto			changed state	do _mainRollout.autoRefresh = state
	on chkApplyOpen		changed state	do _mainRollout.applyOpen = state
	on btnLock			changed state	do fnSaveDockStatus (fnName()) lock:true
	on btnAbout			pressed			do (PteroToolsTemp = #("PteroProps Panel", 1.0); fnAboutDialog())
	on btnSettings		pressed			do fnPteroSettings()
	on chkDockLeft		changed state	do fnDockDialog (fnName()) #cui_dock_left
	on chkDockRight		changed state	do fnDockDialog (fnName()) #cui_dock_right
	on btnAcq			changed state	do fnUtilize (fnName()) type:#acquire
	on btnrefresh		pressed			do fnUtilize (fnName()) type:#read
	on btnSet			pressed			do fnUtilize (fnName()) type:#write
	on btnDel			pressed			do fnUtilize (fnName()) type:#delete
	on btnDef			pressed			do fnUtilize (fnName()) type:#load
	on btnSav			pressed			do fnUtilize (fnName()) type:#save

	--	main rollout open handle
	on mainRollout open do	(
		_mainRollout.registered = false
		
		if (s = fnLoadINIexec "DialogSize" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok then
			s = [_mainRollout.width,_mainRollout.height]
		else s.x = _mainRollout.compWidth s.x
		if (d = fnLoadINI "DialogDock" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok do
			d = #cui_dock_left
		if (a = fnLoadINIexec "AutoRefresh" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok do
			a = true
		if (o = fnLoadINIexec "ApplyOpen" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok do
			o = false
		if (l = fnLoadINIexec "DialogOpen" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok do
			l = true
		_mainRollout.autoRefresh = chkAuto.checked = a
		_mainRollout.applyOpen = chkApplyOpen.checked = o
		_mainRollout.name = fnName()
		fnResizeDialog (fnName()) [s.x, s.y]
		if (d as name) != #cui_floatable then
		(
			fnRegisterDialog (fnName())
			fnDockDialog (fnName()) (d as name)
--			cui.dockDialogBar (fnName()) (d as name)
		)
		btnLock.checked = l

		---------------------------------------------------------------
		ShowPropsRollOut.fnInitRollOut()
		ButtonsRollOut.fnInitRollOut()
		include "$scripts\\pteroTools\\plug_tmp_ini.ppb"
		---------------------------------------------------------------
		fnAddMainRollouts (fnName())
		for ro in _rolloutsTable do
			if not ro.isMain do
				fnShowRollout ro.label type:#checkShow

		fnPrintLabel()
		callbacks.addScript #preSystemShutdown "fnSaveDockStatus _mainRollout.name shutDown:true" id:#pteroProps
		callbacks.addScript #selectionSetChanged "fnAutoUpdate()" id:#pteroProps

		_isPteroPropsOpen = true
		updateToolbarButtons()
	)
	on mainRollout resized size do (
		fnResizeDialog (fnName()) size
		fnCheckRolloutsInColumns()
	)
	on mainRollout close do	(
		fnSaveINI "DialogPosition"	((getDialogpos mainRollout) as string) (fnReturnFilename #ini) (fnReturnSection #ini)
		fnSaveINI "AutoRefresh"	((chkAuto.checked) as string) (fnReturnFilename #ini) (fnReturnSection #ini)
		fnSaveINI "ApplyOpen"	((chkApplyOpen.checked) as string) (fnReturnFilename #ini) (fnReturnSection #ini)
		callbacks.removeScripts id:#pteroProps
		_isPteroPropsOpen = false
		updateToolbarButtons()
	)
)

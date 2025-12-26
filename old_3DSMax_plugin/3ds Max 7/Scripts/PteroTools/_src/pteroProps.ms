---------------------------------------------------------------
--
-- PteroProps
--
-- by Pan Collette
--
-- Create: 13.01.2003
-- Modified: 29.12.2003
--
---------------------------------------------------------------

-- TODO: settings - cesta k enginu
-- TODO: nacitani koliznich materialu z enginu

-----------------------------------------------
-- Create Includes
-----------------------------------------------
fnIncludePlugin ".msp" ".ppb" width:"(_mainWidth / 2.7)" height:"18" columns:2


-----------------------------------------------
-- Structures Definition
-----------------------------------------------
struct _propsMainDef (
	columns,
	min_width,
	min_height,
	width,
	height,
	buttons_offset	= 150,
	used_columns	= 1,
	name			= undefined,
	registered		= false,
	autoRefresh		= false,
	applyOpen		= false,
	rolloutOffset	= 0,
	fn compWidth w = (
		for n = 1 to columns do
			if w >= min_width * n do (
				width = min_width * n
				used_columns = n
			)
		return width
	)
)
struct _propsDef (
	name,
	label,
	isOpen,
	isMain,
	count_keys,
	size
)
struct _keyDef (
	keyName,
	oldString,
	values = #()
)
struct _keyTableDef (
	names,
	controls,
	values
)

-----------------------------------------------
-- Global Variables Definition
-----------------------------------------------
global _isPteroPropsOpen
global _mainRollout			= _propsMainDef 4 180 500 180 500
global _rolloutsTable		= #()

global ShowPropsRollOut
global ButtonsRollOut
global mainRollout
-----------------------------------------------
-- fnEnableMainControls()
-----------------------------------------------
fn fnEnableMainControls name enabled = (
/*	for c = 1 to name.controls.count do
		if (classof name.controls[c]) != LabelControl do
			name.controls[c].enabled = enabled
*/	try (name.btnAuto.enabled = enabled) catch ()
	try (name.btnSet.enabled = enabled) catch ()
	try (name.btnAcq.enabled = enabled) catch ()
	try (name.btnDef.enabled = enabled) catch ()
	try (name.btnSav.enabled = enabled) catch ()
	try (name.btnDel.enabled = enabled) catch ()
)

-----------------------------------------------
-- fnEnableAllControls()
-----------------------------------------------
fn fnEnableAllControls name enabled = (
	for c = 1 to name.controls.count do
		if (classof name.controls[c]) != LabelControl do
			name.controls[c].enabled = enabled
)

-----------------------------------------------
-- fnCleanProps()
-----------------------------------------------
fn fnCleanProps obj buffer:"" = (
	local pteroBuffer = if buffer != "" then buffer else getUserPropBuffer obj
	local n = 1

	while n < pteroBuffer.count do (
		case of (
			((n == 1 or (n > 2 and (subString pteroBuffer (n-2) 1) == (bit.intAsChar 13))) and (subString pteroBuffer n 1) == (bit.intAsChar 13)) : pteroBuffer = replace pteroBuffer n 1 ""
			((n == 1 or (n > 2 and (subString pteroBuffer (n-1) 1) == (bit.intAsChar 10))) and (subString pteroBuffer n 1) == (bit.intAsChar 10)) : pteroBuffer = replace pteroBuffer n 1 ""
			((subString pteroBuffer n 2) == (bit.intAsChar 13) + (bit.intAsChar 13)) : pteroBuffer = replace pteroBuffer n 2 (bit.intAsChar 13)
			((subString pteroBuffer n 1) == " ") : pteroBuffer = replace pteroBuffer n 1 ""
			((subString pteroBuffer n 1) == "	") : pteroBuffer = replace pteroBuffer n 1 ""
			default : n += 1
		)
--	format "%\t%\n" (subString pteroBuffer n 1) (bit.charAsInt (subString pteroBuffer n 1))
	)
	if n > 1 and (subString pteroBuffer (pteroBuffer.count - 1) 1) != (bit.intAsChar 13) do pteroBuffer += (bit.intAsChar 13) + (bit.intAsChar 10)
--	if (subString pteroBuffer n 1) == " " then (pteroBuffer = (replace pteroBuffer n 1 "")) else n += 1

	-- rewrite user properties
	setUserPropBuffer obj pteroBuffer

	return pteroBuffer
)

-----------------------------------------------
-- fnReadProp()
-----------------------------------------------
fn fnReadProp obj key num:1 = (
	local strArray	= _keyDef key key
	local userProps

	fnCleanProps obj
	strArray.oldString += "=" + ( userProps = ( getUserProp obj key ) as string)
	strArray.values = filterString userProps " ,"

	for n = 1 to strArray.values.count do
		if (strArray.values[n] as float) != undefined do
			strArray.values[n] = strArray.values[n] as float

--	format "%\n" strArray

	return strArray
)

-----------------------------------------------
-- fnWriteProp()
-----------------------------------------------
fn fnWriteProp obj strArray = (
	local pteroBuffer	= fnCleanProps obj
	local oldKey		= fnReadProp obj strArray.keyName
	local keyStart		= findString pteroBuffer oldKey.oldString
	local keyLength		= oldKey.oldString.count
	local valString		= ""

/*	-- try olden entry
	if keyStart == undefined do (
		keyStart  = findString pteroBuffer strArray.oldString
		keyLength = oldKey.oldString.count
	)
*/
	-- create new value
	for n = 1 to strArray.values.count do
		valString +=	if n == 1 then  strArray.values[n]
						else "," + strArray.values[n]
	-- create new entry
	valString = (bit.intAsChar 13) + (bit.intAsChar 10) + strArray.keyName + "=" + valString + (bit.intAsChar 13) + (bit.intAsChar 10)

--	format "%\n%\n\n" oldKey strArray

	-- write new user properties
	if keyStart == undefined then
		pteroBuffer += valString
	else
		pteroBuffer = replace pteroBuffer keyStart keyLength valString

	fnCleanProps obj buffer:pteroBuffer

	return true
)

-----------------------------------------------
-- fnReadPropEnhanced()
-----------------------------------------------
fn fnReadPropEnhanced obj key type:#default = (
--	format "READ\n\tobj: %\n\tkey: %\n\ttype: %\n" obj key type

	local pteroBuffer	= fnCleanProps obj
	local strArray		= _keyDef key #()
	local n				= 0

	while (n += 1) <= pteroBuffer.count do (
		-- find keyword
		if	(fnUpcase (subString pteroBuffer n key.count)) == (fnUpcase key) do
		(
			if (n + key.count) <= pteroBuffer.count do if (subString pteroBuffer (n + key.count) 1) != "=" do continue
			if n >= 3 then if ((subString pteroBuffer (n - 2) 2) != ((bit.intAsChar 13) + (bit.intAsChar 10))) do continue
			else if n != 1 do continue
			
			-- find end of line
			for i = 1 to pteroBuffer.count do
			(
				if (subString pteroBuffer (n + key.count + i) 2) == ((bit.intAsChar 13) + (bit.intAsChar 10)) do (
					-- get value
					local str = subString pteroBuffer (n + key.count + 1) (i - 1)

					pteroBuffer = replace pteroBuffer n (key.count + i) (key + "=" + (str as string))
					append strArray.oldString (subString pteroBuffer n (key.count + i))
					n += (key.count + i - 1)

					case type of (
						#LOD : (		-- read special - LOD distance
							append strArray.values str
						)
						default : (		-- read normal
							strArray.values = filterString (str as string) " ,"
						)
					)

--					format "strArray.values.count: %\n" strArray.values.count
					
					for k = 1 to strArray.values.count do
					(
--						format "(classof (strArray.values[%])): %\n" k (classof (strArray.values[k] as float))
						if (classof (strArray.values[k] as float)) == Float then (
							-- convert to integer if not float
							str = strArray.values[k] as float
							if (floor str) == str do str = str as integer
							
							-- replace by correct entry
/*							
							case str of (
								(-1): ()
								default: str = abs str
							)
*/							
							strArray.values[k] = str
							
--							format "str: %\tstrArray.values[%]: %\n" str strArray.values[k] k
						)
					)

					exit
				)
			)
		)
	)

	-- fix LOD distance data
	if type == #LOD do (
		strArray.values = sort strArray.values

		if strArray.values[1] == -1 do (
			deleteItem strArray.values 1
			append strArray.values -1
		)
	)
	
--	format "\t%\n" strArray

	-- rewrite user properties
	fnCleanProps obj buffer:pteroBuffer

	return strArray
)

-----------------------------------------------
-- fnWritePropEnhanced()
-----------------------------------------------
fn fnWritePropEnhanced obj strArray delete:false type:#default = (
--	format "WRITE\n\tobj: %\n\tdelete: %\n\ttype: %\n" obj delete type
--	format "\t%\n" strArray

	local pteroBuffer	= fnCleanProps obj
	local n				= 0
	local str			= ""

	while (n += 1) <= pteroBuffer.count do (
		-- find keyword
		if	(fnUpcase (subString pteroBuffer n strArray.keyName.count)) == (fnUpcase strArray.keyName) do
		(
			if (n + strArray.keyName.count) <= pteroBuffer.count do if (subString pteroBuffer (n + strArray.keyName.count) 1) != "=" do continue
			if n >= 3 then if ((subString pteroBuffer (n - 2) 2) != ((bit.intAsChar 13) + (bit.intAsChar 10))) do continue
			else if n != 1 do continue

			for i = 1 to pteroBuffer.count do
				if (subString pteroBuffer (n + strArray.keyName.count + i) 2) == ((bit.intAsChar 13) + (bit.intAsChar 10)) do (
					-- delete old values
					pteroBuffer = replace pteroBuffer n (strArray.keyName.count + i + 2) ""
					
--					format "\t2: %\n" pteroBuffer
					
					n -= 1
					exit
				)
		)
	)

	if not delete do
	(
			case type of (
				#LOD : (		-- write special - LOD distances
					if strArray.values.count == 1 and strArray.values[1] == -1 then (
					) else for n = 1 to strArray.values.count do
						str += strArray.keyName + "=" + (strArray.values[n] as string) + ((bit.intAsChar 13) + (bit.intAsChar 10))
				)
				default : (		-- write normal
					for n = 1 to strArray.values.count do
						str +=	if n == 1 then  strArray.values[n]
										else "," + strArray.values[n]
					str = strArray.keyName + "=" + str + (bit.intAsChar 13) + (bit.intAsChar 10)
				)
			)

--			format "str: %\n" str
			pteroBuffer = str + pteroBuffer
	)

--	format "\t3: %\n" pteroBuffer

	-- rewrite user properties
	if pteroBuffer == "" do pteroBuffer += ((bit.intAsChar 13) + (bit.intAsChar 10))
	fnCleanProps obj buffer:pteroBuffer
	
	return true
)

-----------------------------------------------
-- fnDeleteProp()
-----------------------------------------------
fn fnDeleteProp obj key = (
	local strArray		= fnReadProp obj key
	local pteroBuffer	= getUserPropBuffer obj
	local keyStart		= findString pteroBuffer strArray.oldString
	local keyLength		= strArray.oldString.count

	if strArray.values[1] as string == "undefined" do return false
	if (substring pteroBuffer (keyStart + keyLength) 1) == (bit.intAsChar 13) do keyLength += 2

	pteroBuffer = replace pteroBuffer keyStart keyLength ""
	setUserPropBuffer obj pteroBuffer

	return true
)

-----------------------------------------------
-- fnReturnSection()
-----------------------------------------------
fn fnReturnSection type = (
	local ret = case type of (
		#ini :	ret = "PteroProps"
		#def :	ret = "PteroPropsDefs"
		default : undefined
	)
	return ret
)

-----------------------------------------------
-- fnAppendRollOut()
-----------------------------------------------
fn fnAppendRollOut name label order:0 = (
	local isMain	= false
	local tmp, size

	case order of (
		0 : order = _rolloutsTable.count + 1
		1 : isMain = true
		default: (
			order -= 1
			isMain = true
		)
	)

	-- calculate size of rollout
	addSubRollout _mainRollout.name.controls[1] name
	size = [name.width, name.height]
	removeSubRollout _mainRollout.name.controls[1] name

	-- create rollout signature
	tmp = _propsDef name label false isMain (name.fnKeyNames()).count size

	-- insert rollout to table
	insertItem tmp _rolloutsTable order
--	append _rolloutsTable tmp

	return true
)

-----------------------------------------------
-- fnFindRollOut()
-----------------------------------------------
fn fnFindRollOut name = (
	for ro in _rolloutsTable do
		if ro.name == name do return ro

	return undefined
)

-----------------------------------------------
-- fnCloseRollOut()
-----------------------------------------------
fn fnCloseRollOut name = (
	local ro		= fnFindRollOut name
	local tmpChars	= "!@#$%^&*(){}[];':\"|,./<>?`~-=+_ 	"
	local label

	if ro == undefined do return false

	label = fnReplaceChars ro.label tmpChars ""
	ro.isOpen = false

	fnSaveINI (label + "Open") (name.open as string) (fnReturnFilename #ini) (fnReturnSection #ini)
	try (fnSaveINI (label + "Auto") (name.btnAuto.checked as string) (fnReturnFilename #ini) (fnReturnSection #ini)) catch ()

	return true
)

-----------------------------------------------

-- fnOpenRollOut()
-----------------------------------------------
fn fnOpenRollOut name = (
	local ro = fnFindRollOut name
	local tmpChars	= "!@#$%^&*(){}[];':\"|,./<>?`~-=+_ 	"
	local label

	if ro == undefined then
		label = name.fnLabel()
	else (
		label = fnReplaceChars ro.label tmpChars ""
		ro.isOpen = true
	)

	try (
		name.btnAuto.checked = fnLoadINIexec (label + "Auto" ) (fnReturnFilename #ini) (fnReturnSection #ini)

		for idx = 1 to ro.count_keys do name.fnUpdate keyIDX:idx type:#read inner:false
	) catch ()

	name.open = fnLoadINIexec (label + "Open") (fnReturnFilename #ini) (fnReturnSection #ini)
)

-----------------------------------------------
-- fnSetDefs()
-----------------------------------------------
fn fnSetDefs key val = (
	setINISetting  (fnReturnFilename #def) (fnReturnSection #def) key val
	return true
)

-----------------------------------------------
-- fnGetDefs()
-----------------------------------------------
fn fnGetDefs key = (
	local val
	try (
		if (val = ( execute ( getINISetting (fnReturnFilename #def) (fnReturnSection #def) key ) )) == OK do val = #(-100)
		return val
	) catch (
		return #(-100)
	)
)

-----------------------------------------------
-- fnRegisterDialog()
-----------------------------------------------
fn fnRegisterDialog name = (
	cui.RegisterDialogBar name \
		style:#(#cui_dock_vert) \ --#cui_floatable) \
		minSize:[_mainRollout.min_width, _mainRollout.min_height] \
		maxSize:[_mainRollout.columns * _mainRollout.min_width, -1]
	_mainRollout.registered = true
)

-----------------------------------------------
-- fnUnRegisterDialog()
-----------------------------------------------
fn fnUnRegisterDialog name = (
	cui.floatDialogBar name
	cui.UnRegisterDialogBar name
	_mainRollout.registered = false
)

-----------------------------------------------
-- fnDockDialog()
-----------------------------------------------
fn fnDockDialog name type = 
(
	local docks = #(#cui_dock_left, #cui_dock_right)
	local btns = #(#chkDockLeft, #chkDockRight)
	local enbl = true
	local idx
	
--	format "type: %\n" type
	
	if _mainRollout.registered then
	(
		if type != (cui.getDockState name) then
		(
			cui.floatDialogBar name
			cui.dockDialogBar name type
		)
		else
		(
			cui.floatDialogBar name
			fnUnRegisterDialog name
			enbl = false
		)
	)
	else
	(
		fnRegisterDialog name
		cui.dockDialogBar name type
	)

	for n = 1 to docks.count do
	(
		idx = fnFindControl name.controls btns[n]
		name.controls[idx].checked = if type == docks[n] then enbl else false
	)
)

-----------------------------------------------
-- fnSaveDockStatus()
-----------------------------------------------
fn fnSaveDockStatus name shutDown:false lock:false = (
	local idx = fnFindControl name.controls #btnLock
	
	if shutDown do
		if _mainRollout.registered then
			fnSaveINI "DialogDock"	((cui.getDockState name) as string) (fnReturnFilename #ini) (fnReturnSection #ini)
		else
			fnSaveINI "DialogDock" "cui_floatable" (fnReturnFilename #ini) (fnReturnSection #ini)
	if lock do fnSaveINI "DialogOpen" ((name.controls[idx].checked) as string) (fnReturnFilename #ini) (fnReturnSection #ini)
	if shutDown do _mainRollout.registered = false
)

-----------------------------------------------
-- fnResizeDialog()
-----------------------------------------------
fn fnResizeDialog name size = --if _mainRollout.registered then (
(
--	format "_mainRollout.registered: %\n" _mainRollout.registered
	if _mainRollout.registered then
	(
		if (cui.getDockState name) == #cui_floatable do
		(
			fnUnRegisterDialog name
			_mainRollout.compWidth size.x
			name.width = _mainRollout.width
			fnRegisterDialog name
		)
	)
	else try
	(
		_mainRollout.compWidth size.x
		name.width = _mainRollout.width
	) catch ()

	for c = 1 to _mainRollout.columns do (
		name.controls[c].height = if c == 1 then name.height - _mainRollout.buttons_offset else name.height
		name.controls[c].visible = if c <= _mainRollout.used_columns then true else false
	)

	fnSaveDockStatus name

	fnSaveINI "DialogSize"	("[" + name.width as string + "," + name.height as string + "]") (fnReturnFilename #ini) (fnReturnSection #ini)

)

-----------------------------------------------
-- fnAddMainRollouts()
-----------------------------------------------
fn fnAddMainRollouts name = (
	for ro in _rolloutsTable do
		if ro.isMain do
			addSubRollout name.controls[1] ro.name
)

-----------------------------------------------
-- fnSetControlValue()
-----------------------------------------------
fn fnSetControlValue name control value type:#none = (
	if (local idx = findItem name.controls control) == 0 do return false

	fn fnDoBoolean value:value = case of (
		( ( classof value ) == booleanClass ):		value
		( ( value as integer ) == 1 ):				true
		( fnDncase ( value as string ) == "true" ):	true
		default:									false
	)
	fn fnDoListBox name:name idx:idx value:value type:type = case type of (
		#items:		name.controls[idx].items			= if classof value == array then value else ( print "Error: fnSetControlValue() - no Array Value"; return false )
		#selected:	name.controls[idx].selected			= value as string
		default:	try ( name.controls[idx].selection	= value as integer ) catch ( print "Error: fnSetControlValue() - no Integer Value"; return false )
	)

	case ( classof control ) of (
		CheckBoxControl: 	name.controls[idx].state		= fnDoBoolean()
		CheckButtonControl: name.controls[idx].state		= fnDoBoolean()
		RadioControl:		name.controls[idx].state		= fnDoBoolean()
		ComboBoxControl:	fnDoListBox()
		ListBoxControl:		fnDoListBox()
		EditTextControl:	name.controls[idx].text			= value as string
		LabelControl:		name.controls[idx].text			= value as string
		SpinnerControl: 	try ( name.controls[idx].value	= value as float ) catch ( print "Error: fnSetControlValue() - no Float Value"; return false )
		ColorPickerControl:	try ( name.controls[idx].color	= value as color ) catch ( print "Error: fnSetControlValue() - no Color Value"; return false )
		default:			return false
	)

	return true
)

-----------------------------------------------
-- fnGetControlValue()
-----------------------------------------------
fn fnGetControlValue name control type:#none = (
	if (local idx = findItem name.controls control) == 0 do return undefined

	fn fnDoBoolean name:name idx:idx =
		if name.controls[idx].state then 1 else 0
	fn fnDoListBox name:name idx:idx type:type = case type of (
		#items:		name.controls[idx].items
		#selected:	name.controls[idx].selected
		default:	name.controls[idx].selection
	)

	return case (classof control) of (
		CheckBoxControl: 		fnDoBoolean()
		CheckButtonControl: 	fnDoBoolean()
		RadioControl:			fnDoBoolean()
		ComboBoxControl:		fnDoListBox()
		ListBoxControl:			fnDoListBox()
		EditTextControl:		name.controls[idx].text
		LabelControl:			name.controls[idx].text
		SpinnerControl: 		name.controls[idx].value
		ColorPickerControl:		name.controls[idx].color
		default:				undefined
	)
)

-----------------------------------------------
-- fnAutoUpdate()
-----------------------------------------------
fn fnAutoUpdate = (
	_mainRollout.name.fnUtilize _mainRollout.name info:true type:(if _mainRollout.autoRefresh then #read else #none)
)

-----------------------------------------------
-- fnGetPropsToShow()
-----------------------------------------------
fn fnGetPropsToShow name control = (

	local pteroBuffer

	case selection.count of (
		1 :	(
			pteroBuffer = getUserPropBuffer $
		)
		0 : (
			pteroBuffer = ""
		)
		default : (
			pteroBuffer = getUserPropBuffer selection[1]
			for o in selection do
				if (getUserPropBuffer o) != pteroBuffer do (
					pteroBuffer = ""
					exit
				)
		)
	)

	fnSetControlValue name control pteroBuffer
	return true
)

-----------------------------------------------
-- fnSetProps()
-----------------------------------------------

fn fnSetProps name control = (
	local pteroBuffer = fnGetControlValue name control


	case selection.count of (
		1 : fnCleanProps $ buffer:pteroBuffer
		default : for n = 1 to selection.count do fnCleanProps selection[n] buffer:pteroBuffer
	)

	fnAutoUpdate()

	return true
)

-----------------------------------------------
-- fnColor()
-----------------------------------------------
fn fnColor name val:0 type:true keyIDX:1 = (
	if type then (
		name.spnClrR.value	= val.r as integer
		name.spnClrG.value	= val.g as integer
		name.spnClrB.value	= val.b as integer
	) else
		name.clrLight.color	= [ name.spnClrR.value, name.spnClrG.value, name.spnClrB.value ] as color

	return true
)

-----------------------------------------------
-- fnAcquire()
-----------------------------------------------
fn fnAcquire name keys:1 = (
	fn fnDoApply ro acqObj = (
		for n = 1 to ro.count_keys do
			ro.name.fnUpdate keyIDX:n type:#acquire acqObj:acqObj inner:false
	)

	if name.btnAcq.checked do (
		fnEnableMainControls _mainRollout.name false
		for ro in _rolloutsTable do
			fnEnableMainControls ro.name false
		local acqObj = pickObject()
		
		-- if something is selected do
		if acqObj != undefined and acqObj != #escape do
			if name == _mainRollout.name then

				for ro in _rolloutsTable do
					if not ro.isMain do (
						if _mainRollout.applyOpen do if not ro.isOpen do continue
						fnDoApply ro acqObj
					)
			else
				for n = 1 to keys do
					name.fnUpdate keyIDX:n type:#acquire acqObj:acqObj inner:false

		fnEnableMainControls _mainRollout.name true
		for ro in _rolloutsTable do
			fnEnableMainControls ro.name true
		name.btnAcq.checked = false
	)
	return true
)

-----------------------------------------------
-- fnMeasureDistance()
-----------------------------------------------
fn fnMeasureDistance name chkBoxName keyIDX:undefined subKeyIDX:1 = (
	local idx = fnFindControl name.controls chkBoxName
	local dist
	
--	if keyIDX == undefined do return false
	if idx == 0 do return false

	-- disable all controls
	fnEnableAllControls _mainRollout.name false
	for ro in _rolloutsTable do
		fnEnableAllControls ro.name false

	-- do measure
	dist = startTool mtMeasureDistance

	-- enable all controls and update all rollouts
	fnEnableAllControls _mainRollout.name true
	for ro in _rolloutsTable do
		fnEnableAllControls ro.name true

	-- set distance to control
	if keyIDX != undefined do
		if dist > 0 do (
			(name.fnKeyUI())[keyIDX][subKeyIDX].value = dist
			name.fnUpdate keyIDX:keyIDX
		)

	name.controls[idx].checked = false
	
	return dist
)

--------------------------------------------------------
--	fnCheckRolloutsInColumns()
--------------------------------------------------------
fn fnCheckRolloutsInColumns = (
	local whichColumn	= 0
	local columnsTable	= #()

	-- Prepare column array
	for n = 1 to _mainRollout.columns do
		insertItem #() columnsTable n

	-- Append all rollouts to last column array
	for n = 1 to _mainRollout.columns do
		for r in _mainRollout.name.controls[n].rollouts do
			append columnsTable[_mainRollout.used_columns] r

	-- Move rollouts between column arrays
	while (whichColumn += 1) < _mainRollout.used_columns do (
		local height = 0



		columnsTable[whichColumn] = #()

		while height <= _mainRollout.name.controls[whichColumn].height + _mainRollout.rolloutOffset do (
			if columnsTable[_mainRollout.used_columns][1] == undefined do exit

			height += if columnsTable[_mainRollout.used_columns][1].open then
				columnsTable[_mainRollout.used_columns][1].height else 15

			if	not (fnFindRollOut columnsTable[_mainRollout.used_columns][1]).isMain and
				height > _mainRollout.name.controls[whichColumn].height + _mainRollout.rolloutOffset do exit

			append columnsTable[whichColumn] columnsTable[_mainRollout.used_columns][1]
			deleteItem columnsTable[_mainRollout.used_columns] 1
		)
	)

	-- Remove all rollouts from all columns
	for n = 1 to _mainRollout.columns do
		for k = 1 to _mainRollout.name.controls[n].rollouts.count do
			if	_mainRollout.name.controls[n].rollouts[k] != undefined and
				columnsTable[n][k] != _mainRollout.name.controls[n].rollouts[k] do
				removeSubRollout _mainRollout.name.controls[n] _mainRollout.name.controls[n].rollouts[k]

	-- Add rollouts to columns
	for n = 1 to columnsTable.count do
		for k = 1 to columnsTable[n].count do
			if columnsTable[n][k] != undefined and (findItem _mainRollout.name.controls[n].rollouts columnsTable[n][k]) == 0 do
				addSubRollout _mainRollout.name.controls[n] columnsTable[n][k]
)

--------------------------------------------------------
--	fnShowRollout()
--------------------------------------------------------
fn fnShowRollout label type:#none = (
	local whichColumn	= 0
	local btn_names		= #()
	local ro			= undefined
	local btn_ro		= fnFindRollOut _mainRollout.name.controls[1].rollouts[1] -- ButtonsRollOut
	local tmpChars		= "!@#$%^&*(){}[];':\"|,./<>?`~-=+_ 	"

	-- Remove wrong chars from label
	label = fnReplaceChars label tmpChars ""


	-- Find rollout by label
	for r in _rolloutsTable do (
		local rl = fnReplaceChars r.label tmpChars ""
		if rl == label do (
			ro = r
			exit
		)
	)

	if ro != undefined do (
		-- Read settings from ini file
		if type == #checkShow do (
			if (tmp = fnLoadINIexec (label as string + "Show" ) (fnReturnFilename #ini) (fnReturnSection #ini)) == OK do tmp = true
			type = if tmp then #add else #remove
		)

		-- Add or Remove rollout to/from the column
		case type of (
			#add : (
				addSubRollout _mainRollout.name.controls[_mainRollout.used_columns] ro.name
			)
			#remove : (
				while (whichColumn += 1) < _mainRollout.used_columns do
					if (findItem _mainRollout.name.controls[whichColumn].rollouts ro.name) > 0 do exit
			 	removeSubRollout _mainRollout.name.controls[whichColumn] ro.name
			)
		)

		-- Move rollouts between columns
		fnCheckRolloutsInColumns()

		-- Save settings to ini file
		for btn in btn_ro.name.controls do
			if btn.text == ro.label do (
				btn.checked = if type == #add then true else false
				fnSaveINI ((label as string) + "Show") ((btn.checked) as string) (fnReturnFilename #ini) (fnReturnSection #ini)
			)
	)
)

-----------------------------------------------
-- fnCreatePteroProps()
-----------------------------------------------
fn fnCreatePteroProps = (
	if _isPteroPropsOpen == undefined do _isPteroPropsOpen = false
	if not _isPteroPropsOpen then (
		_rolloutsTable = #()
		-----------------------------------------------
		if (p = fnLoadINIexec "DialogPosition" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok do
			p = [50,50]
		if (s = fnLoadINIexec "DialogSize" (fnReturnFilename #ini) (fnReturnSection #ini)) == ok then
			s = [_mainRollout.min_width,_mainRollout.height]
		else (
			s.x = _mainRollout.compWidth s.x
			if s.y < _mainRollout.height then s.y = _mainRollout.height else _mainRollout.height = s.y
		)
		-----------------------------------------------
		createDialog mainRollout style:#(#style_toolwindow, #style_sysmenu, #style_resizing) width:s.x height:s.y pos:p
	) else (
		fnSaveDockStatus mainRollout shutDown:true
		try (cui.UnRegisterDialogBar mainRollout) catch()
		destroyDialog mainRollout
		_isPteroPropsOpen = false
	)
)

-- EOF
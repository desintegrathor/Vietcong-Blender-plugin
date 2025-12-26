---------------------------------------------------------------
--
-- PteroMultiShader
--
-- by Pan Collette
--
-- Create:		12.12.2003
-- Modified:	15.12.2003
--
---------------------------------------------------------------

plugin material PteroMultiLayer
name:"PteroMultiLayer"
classID:#(0x31066f65, 0x57b02c4e)
extends:standard replaceUI:true
--extends:multimaterial replaceUI:true
(
	---------------------------------------------------------------
	-- plugin locals
	-------------------------------------------------------------
	local Layer = #()

	---------------------------------------------------------------
	-- plugin parameters
	-------------------------------------------------------------
	parameters paramMain rollout:roMatList (
		show			type:#integer	default:0
		Layer1			type:#material	ui:btnMaterial1
		Layer2			type:#material	ui:btnMaterial2
		Layer3			type:#material	ui:btnMaterial3
		Layer4			type:#material	ui:btnMaterial4
		Layer5			type:#material	ui:btnMaterial5
		Layer6			type:#material	ui:btnMaterial6
		Layer7			type:#material	ui:btnMaterial7
		Layer8			type:#material	ui:btnMaterial8
		Layer9			type:#material	ui:btnMaterial9
		Layer10			type:#material	ui:btnMaterial10
		LayerEnabled	type:#boolTab
						tabSizeVariable:false
						tabSize:10
						default:false
						ui:(chkUsed1, chkUsed2, chkUsed3, chkUsed4, chkUsed5, chkUsed6, chkUsed7, chkUsed8, chkUsed9, chkUsed10)
		LayerColor		type:#colorTab
						tabSizeVariable:false
						tabSize:10
						default:(color 150 150 150)
						ui:(clrColor1, clrColor2, clrColor3, clrColor4, clrColor5, clrColor6, clrColor7, clrColor8, clrColor9, clrColor10)

		on show set val do try (
			if val != 0 do
				if Layer[val] == undefined do
					for n = 1 to Layer.count do
						if Layer[n] != undefined do (
							val = n
							show = val
							exit
						)
			local col = if val == 0 then (color 150 150 150) else layer[val].matColor
			delegate.Diffuse_Color = col
			delegate.Ambient_Color = col / 2.5
			delegate.Specular_Color = (color 229 229 229)
		) catch ()

		on Layer1 set val do (
			local n = 1
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 2
		)
		on Layer2 set val do (
			local n = 2
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer3 set val do (
			local n = 3
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer4 set val do (
			local n = 4
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer5 set val do (
			local n = 5
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer6 set val do (
			local n = 6
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer7 set val do (
			local n = 7
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer8 set val do (
			local n = 8
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer9 set val do (
			local n = 9
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
		on Layer10 set val do (
			local n = 10
			Layer[n] = val
			LayerColor[n] = if val == undefined then (color 150 150 150) else copy layer[n].matColor
			LayerEnabled[n] = if val == undefined then false else true
			if show == n do show = 1
		)
	)

	---------------------------------------------------------------
	--	rollout roMultiMat
	---------------------------------------------------------------
	rollout roMatList "Material List" (
		ImgTag itgRender1 "" pos:[2, 4] width:19 height:19
		checkbutton chkUsed1 "U" pos:[23, 4] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow1 "S" pos:[41, 4] width:16 height:16
		materialButton btnMaterial1 "" pos:[59, 4] width:100 height:16
		colorPicker clrColor1 "" pos:[161, 4] width:19 height:16
		label lblShader1 "" pos:[182, 5] width:140 height:16
		ImgTag itgRender2 "" pos:[2, 27] width:19 height:19
		checkbutton chkUsed2 "U" pos:[23, 27] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow2 "S" pos:[41, 27] width:16 height:16
		materialButton btnMaterial2 "" pos:[59, 27] width:100 height:16
		colorPicker clrColor2 "" pos:[161, 27] width:19 height:16
		label lblShader2 "" pos:[182, 28] width:140 height:16
		ImgTag itgRender3 "" pos:[2, 50] width:19 height:19
		checkbutton chkUsed3 "U" pos:[23, 50] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow3 "S" pos:[41, 50] width:16 height:16
		materialButton btnMaterial3 "" pos:[59, 50] width:100 height:16
		colorPicker clrColor3 "" pos:[161, 50] width:19 height:16
		label lblShader3 "" pos:[182, 51] width:140 height:16
		ImgTag itgRender4 "" pos:[2, 73] width:19 height:19
		checkbutton chkUsed4 "U" pos:[23, 73] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow4 "S" pos:[41, 73] width:16 height:16
		materialButton btnMaterial4 "" pos:[59, 73] width:100 height:16
		colorPicker clrColor4 "" pos:[161, 73] width:19 height:16
		label lblShader4 "" pos:[182, 74] width:140 height:16
		ImgTag itgRender5 "" pos:[2, 96] width:19 height:19
		checkbutton chkUsed5 "U" pos:[23, 96] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow5 "S" pos:[41, 96] width:16 height:16
		materialButton btnMaterial5 "" pos:[59, 96] width:100 height:16
		colorPicker clrColor5 "" pos:[161, 96] width:19 height:16
		label lblShader5 "" pos:[182, 97] width:140 height:16
		ImgTag itgRender6 "" pos:[2, 119] width:19 height:19
		checkbutton chkUsed6 "U" pos:[23, 119] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow6 "S" pos:[41, 119] width:16 height:16
		materialButton btnMaterial6 "" pos:[59, 119] width:100 height:16
		colorPicker clrColor6 "" pos:[161, 119] width:19 height:16
		label lblShader6 "" pos:[182, 120] width:140 height:16
		ImgTag itgRender7 "" pos:[2, 142] width:19 height:19
		checkbutton chkUsed7 "U" pos:[23, 142] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow7 "S" pos:[41, 142] width:16 height:16
		materialButton btnMaterial7 "" pos:[59, 142] width:100 height:16
		colorPicker clrColor7 "" pos:[161, 142] width:19 height:16
		label lblShader7 "" pos:[182, 143] width:140 height:16
		ImgTag itgRender8 "" pos:[2, 165] width:19 height:19
		checkbutton chkUsed8 "U" pos:[23, 165] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow8 "S" pos:[41, 165] width:16 height:16
		materialButton btnMaterial8 "" pos:[59, 165] width:100 height:16
		colorPicker clrColor8 "" pos:[161, 165] width:19 height:16
		label lblShader8 "" pos:[182, 166] width:140 height:16
		ImgTag itgRender9 "" pos:[2, 188] width:19 height:19
		checkbutton chkUsed9 "U" pos:[23, 188] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow9 "S" pos:[41, 188] width:16 height:16
		materialButton btnMaterial9 "" pos:[59, 188] width:100 height:16
		colorPicker clrColor9 "" pos:[161, 188] width:19 height:16
		label lblShader9 "" pos:[182, 189] width:140 height:16
		ImgTag itgRender10 "" pos:[2, 211] width:19 height:19
		checkbutton chkUsed10 "U" pos:[23, 211] width:16 height:16 highlightColor:(color 255 255 132)
		checkbutton chkShow10 "S" pos:[41, 211] width:16 height:16
		materialButton btnMaterial10 "" pos:[59, 211] width:100 height:16
		colorPicker clrColor10 "" pos:[161, 211] width:19 height:16
		label lblShader10 "" pos:[182, 212] width:140 height:16
		button btnAbout "?" pos:[300,234] width:16 height:16 toolTip:"About PteroMultiLayer"

		-- fnFindControl()
		fn fnFindControl controls name = (
			local ret = 0

			for n = 1 to controls.count do
				if controls[n].name == name do ret = n

			return ret
		)

		-- fnUpdateUI()
		fn fnUpdateUI type:#none = (
			local names = #(#clrColor, #btnMaterial, #chkShow, #lblShader)

			fn fnCase type n names = (
				fn fnclrColor idx n =
					LayerColor[n] = try (copy layer[n].matColor) catch ((color 150 150 150))
--					roMatList.controls[idx].color = try (copy layer[n].matColor) catch ((color 150 150 150))

				fn fnbtnMaterial idx n =
					if (classof layer[n] != PteroLayer) and (layer[n] != undefined) do
						roMatList.controls[idx].material = undefined

				fn fnchkShow idx n =
					roMatList.controls[idx].checked = if show == n then true else false

				fn fnlblShader idx n = if layer[n] != undefined do --print (fnReturnShaderName n:layer[n].shader)--
					roMatList.controls[idx].text = " " + fnReturnShaderName n:layer[n].shader

				local name	= type as string + n as string
				local idx	= fnFindControl roMatList.controls name

				case type of (
					#clrColor:		fnclrColor idx n
					#btnMaterial:	fnbtnMaterial idx n
					#chkShow:		fnchkShow idx n
					#lblShader:		fnlblShader idx n
				)
			)

			for n = 1 to Layer.count do
				if type == #none then (
					for k = 1 to names.count do
						fnCase names[k] n names
				) else
					fnCase type n names
		)

		-- fnChangeMatColor()
		fn fnChangeMatColor n val = try (
			layer[n].matColor = copy val
			fnUpdateUI type:#clrColor
			show = show
		) catch ()

		-- fnSetShow()
		fn fnSetShow n state = (
			if layer[n] != undefined do
				if n == show and state == false then
					show = 0
				else
					show = n
			fnUpdateUI type:#chkShow
		)

		-- fnSetEnable()
		fn fnSetEnable n val = (
			if layer[n] != undefined then
				LayerEnabled[n] = val
			else
				LayerEnabled[n] = false
		)

		-- event handler
		on btnAbout		pressed		do (PteroToolsTemp = #("PteroMultiLayer Material", 0.7); fnAboutDialog())
		on clrColor1	changed val do fnChangeMatColor 1	val
		on clrColor2	changed val do fnChangeMatColor 2	val
		on clrColor3	changed val do fnChangeMatColor 3	val
		on clrColor4	changed val do fnChangeMatColor 4	val
		on clrColor5	changed val do fnChangeMatColor 5	val
		on clrColor6	changed val do fnChangeMatColor 6	val
		on clrColor7	changed val do fnChangeMatColor 7	val
		on clrColor8	changed val do fnChangeMatColor 8	val
		on clrColor9	changed val do fnChangeMatColor 9	val
		on clrColor10	changed val do fnChangeMatColor 10	val

		on chkShow1		changed state do fnSetShow 1	state
		on chkShow2		changed state do fnSetShow 2	state
		on chkShow3		changed state do fnSetShow 3	state
		on chkShow4		changed state do fnSetShow 4	state
		on chkShow5		changed state do fnSetShow 5	state
		on chkShow6		changed state do fnSetShow 6	state
		on chkShow7		changed state do fnSetShow 7	state
		on chkShow8		changed state do fnSetShow 8	state
		on chkShow9		changed state do fnSetShow 9	state
		on chkShow10	changed state do fnSetShow 10	state

		on chkUsed1		changed state do fnSetEnable 1	state
		on chkUsed2		changed state do fnSetEnable 2	state
		on chkUsed3		changed state do fnSetEnable 3	state
		on chkUsed4		changed state do fnSetEnable 4	state
		on chkUsed5		changed state do fnSetEnable 5	state
		on chkUsed6		changed state do fnSetEnable 6	state
		on chkUsed7		changed state do fnSetEnable 7	state
		on chkUsed8		changed state do fnSetEnable 8	state
		on chkUsed9		changed state do fnSetEnable 9	state
		on chkUsed10	changed state do fnSetEnable 10	state

		on roMatList open do (
			fnUpdateUI()
			show = show
/*			print (medit.getTopMtlSlot activeMeditSlot) --updateMtlEditorBrackets()
			print (medit.getCurMtl())
*/		)
	)

	--------------------------------------------------------
	--	plugin create handle
	--------------------------------------------------------
	on create do (
		local tmp = getMeditMaterial activeMeditSlot
		if (classof tmp) == PteroLayer do
			Layer1 = tmp
	)
)

-- EOF
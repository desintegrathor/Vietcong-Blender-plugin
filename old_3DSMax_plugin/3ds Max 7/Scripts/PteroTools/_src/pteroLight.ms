------------------------------------------------------------
-- Main pteroLight
------------------------------------------------------------
plugin light pLight
name:"pLight"
classID:#(0x88e23f36, 0xda077e98)
extends:omniLight
replaceUI:true
invisible:true
( 
--	local handleTarget, handleLight
	
	fn fnSetType val =
	(
		case val of (
			2: delegate.type = #freeSpot
			3: delegate.type = #targetSpot
			4: delegate.type = #freeDirect
			5: delegate.type = #targetDirect
			default: (
				delegate.type = #omni
				val = 1
			)
		)
		return val
	)
	
	parameters main rollout:params (
		enabled			type:#boolean	default:true				ui:chkOn
		type			type:#index		default:1					ui:ddlType
		rgb				type:#color		default:(color 255 252 229)	ui:cpColor
		r				type:#integer	default:255					ui:spnR
		g				type:#integer	default:252					ui:spnG
		b				type:#integer	default:229					ui:spnB
		farAttenEnd		type:#float		default:10					ui:spnRadius
		multiplier		type:#float		default:1					ui:spnAtten
		showFarAtten	type:#boolean	default:true				ui:chkRadius
		hotspot			type:#float		default:45					ui:spnInner
		falloff			type:#float		default:60					ui:spnOuter
		castShadows		type:#boolean	default:true				ui:chkShadows
		castSHMShadows	type:#boolean	default:false				ui:chkSHMShadows
		
		on enabled set val do delegate.enabled = val
		on type set val do type = fnSetType val
		on rgb set val do
		(
			delegate.rgb = val
			r = rgb.r
			g = rgb.g
			b = rgb.b
		)
		on farAttenEnd set val do
		(
			delegate.farAttenEnd = val
			if (classof delegate) != Omnilight do (
				try (delegate.targetDistance = val) catch ()
				try ($.targetDistance = val) catch ()
			)
		)
		on multiplier set val do delegate.multiplier = val
		on showFarAtten set val do
		(
			delegate.showFarAtten = val
			try (delegate.showCone = val) catch ()
		)
		on falloff set val do try
		(
			delegate.falloff = val
			if falloff < hotspot do hotspot = falloff
		) catch ()
		on hotspot set val do try
		(
			delegate.hotspot = val
			if hotspot > falloff do falloff = hotspot
		) catch ()
		on castShadows set val do delegate.castShadows = val

	)




	rollout params "Light Parameters"
	(
		checkbox		chkOn "On" pos:[4,11] width:40 height:16
		dropDownList	ddlType "" pos:[44,8] width:112 height:21 items:#("omni", "free spot", "target spot", "free direct", "target direct")
		GroupBox		grp3 "Color" pos:[4,48] width:152 height:72
			colorPicker		cpColor "" pos:[12,64] width:56 height:48
			label			lbl4 "R:" pos:[84,64] width:16 height:16
			spinner			spnR "" pos:[100,64] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl5 "G:" pos:[84,80] width:16 height:16
			spinner			spnG "" pos:[100,80] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl6 "B:" pos:[84,96] width:16 height:16
			spinner			spnB "" pos:[100,96] width:45 height:16 range:[0,255,0] type:#integer scale:1
		GroupBox		grp2 "Light luminance" pos:[4,128] width:152 height:76
			label			lbl2 "Radius/Distance:" pos:[12,144] width:100 height:16
			spinner			spnRadius "" pos:[96,144] width:53 height:16 range:[0.001,1e+032,10] type:#float scale:0.01
			label			lbl3 "Linear Attenuat.:" pos:[18,160] width:100 height:16
			spinner			spnAtten "" pos:[96,160] width:53 height:16 range:[0,1e+032,1] type:#float scale:0.01
			checkbox		chkRadius "Show Radius" pos:[12,181] width:128 height:16
		GroupBox		grp4 "Spot/Direct properties" pos:[4,212] width:152 height:56
			label			lbl7 "Inner Ang./Rad.:" pos:[14,230] width:83 height:16
			spinner			spnInner "" pos:[96,230] width:53 height:16 range:[0,180,0] type:#float scale:0.5
			label			lbl8 "Outer Ang./Rad.:" pos:[12,246] width:85 height:16
			spinner			spnOuter "" pos:[96,246] width:53 height:16 range:[0,180,0] type:#float scale:0.5
		GroupBox		grp1 "LM properties" pos:[4,276] width:152 height:56
			checkbox		chkShadows "Shadows" pos:[12,294] width:128 height:16
			checkbox		chkSHMShadows "SHM Shadows" pos:[12,310] width:128 height:16
		
		fn fnUpdateUI =
		(
			local tmp
			ddlType.selection = fnSetType ddlType.selection
			tmp = if ddlType.selection == 1 then false else true
			lbl7.enabled = tmp
			lbl8.enabled = tmp
			spnInner.enabled = tmp
			spnOuter.enabled = tmp
		)
		
		on ddlType selected val do fnUpdateUI()
		on spnR changed val do cpColor.color.r = val
		on spnG changed val do cpColor.color.g = val
		on spnB changed val do cpColor.color.b = val
		on params open do
		(
			try
			(
				if $.target != undefined do
					farAttenEnd = $.targetDistance
			) catch ()
			fnUpdateUI()
		)
	)
	
	on create do
	(
		delegate.enabled = true
		delegate.useNearAtten = false
		delegate.farAttenStart = 0
		delegate.useFarAtten = true
--		tmp = omnilight()
--		delete tmp
	)
	on load do
	(
	)
)

------------------------------------------------------------
-- Target Spot Light
------------------------------------------------------------
plugin light ptsLight
name:"pTargetSpot"
category:"pteroLights"
(
	local master
	
	parameters main rollout:params (
		enabled			type:#boolean	default:true				ui:chkOn
		rgb				type:#color		default:(color 255 252 229)	ui:cpColor
		r				type:#integer	default:255					ui:spnR
		g				type:#integer	default:252					ui:spnG
		b				type:#integer	default:229					ui:spnB
		farAttenEnd		type:#float		default:10					ui:spnRadius
		multiplier		type:#float		default:1					ui:spnAtten
		showFarAtten	type:#boolean	default:true				ui:chkRadius
		hotspot			type:#float		default:45					ui:spnInner
		falloff			type:#float		default:60					ui:spnOuter
		castShadows		type:#boolean	default:true				ui:chkShadows
		castSHMShadows	type:#boolean	default:false				ui:chkSHMShadows

		on enabled set val do
			if selection.count == 1 and (selection[1]) == master do
				master.enabled = val
		on rgb set val do (
			if selection.count == 1 and (selection[1]) == master do
				master.rgb = val
			r = rgb.r
			g = rgb.g
			b = rgb.b
		)
		on farAttenEnd set val do
			if selection.count == 1 and (selection[1]) == master do
				master.farAttenEnd = val
		on multiplier set val do
			if selection.count == 1 and (selection[1]) == master do
				master.multiplier = val
		on showFarAtten set val do
			if selection.count == 1 and (selection[1]) == master do
				master.showFarAtten = val
		on hotspot set val do
			if selection.count == 1 and (selection[1]) == master do
				master.hotspot = val
		on falloff set val do
			if selection.count == 1 and (selection[1]) == master do
				master.falloff = val
		on castShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castShadows = val
		on castSHMShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castSHMShadows = val
	)
	
	rollout params "Target Spot Parameters"
	(
		checkbox		chkOn "On" pos:[8,8] width:40 height:16
		GroupBox		grp3 "Color" pos:[4,28] width:152 height:72
			colorPicker		cpColor "" pos:[12,44] width:56 height:48
			label			lbl4 "R:" pos:[84,44] width:16 height:16
			spinner			spnR "" pos:[100,44] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl5 "G:" pos:[84,60] width:16 height:16
			spinner			spnG "" pos:[100,60] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl6 "B:" pos:[84,76] width:16 height:16
			spinner			spnB "" pos:[100,76] width:45 height:16 range:[0,255,0] type:#integer scale:1
		GroupBox		grp2 "Light luminance" pos:[4,108] width:152 height:76
			label			lbl2 "Distance:" pos:[49,124] width:50 height:16
			spinner			spnRadius "" pos:[96,124] width:53 height:16 range:[0,1e+032,10] type:#float scale:0.01
			label			lbl3 "Linear Attenuat.:" pos:[16,140] width:100 height:16
			spinner			spnAtten "" pos:[96,140] width:53 height:16 range:[0,1e+032,1] type:#float scale:0.01
			checkbox		chkRadius "Show Radius" pos:[12,161] width:128 height:16
		GroupBox		grp4 "Spot/Direct properties" pos:[4,192] width:152 height:56
			label			lbl7 "Inner Angle:" pos:[38,210] width:100 height:16
			spinner			spnInner "" pos:[96,210] width:53 height:16 range:[0,180,0] type:#float scale:0.5
			label			lbl8 "Outer Angle:" pos:[36,226] width:100 height:16
			spinner			spnOuter "" pos:[96,226] width:53 height:16 range:[0,180,0] type:#float scale:0.5
		GroupBox		grp1 "LM properties" pos:[4,256] width:152 height:56
			checkbox		chkShadows "Shadows" pos:[12,274] width:128 height:16
			checkbox		chkSHMShadows "SHM Shadows" pos:[12,290] width:128 height:16

		on spnR changed val do cpColor.color.r = val
		on spnG changed val do cpColor.color.g = val
		on spnB changed val do cpColor.color.b = val
	)
	
	tool create 
	( 
		on start do (
			for n = 1 to selection.count do
				if (classof selection[n]) == pLight do (
					enabled = selection[n].enabled
					farAttenEnd = selection[n].farAttenEnd
					rgb = selection[n].rgb
					multiplier = selection[n].multiplier
					showFarAtten = selection[n].showFarAtten
					hotspot = selection[n].hotspot
					falloff = selection[n].falloff
					castShadows = selection[n].castShadows
					castSHMShadows = selection[n].castSHMShadows
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pLight pos:worldPoint --gridPoint
				master.type = 3
				master.enabled = enabled
				master.farAttenEnd = farAttenEnd
				master.rgb = rgb
				master.multiplier = multiplier
				master.showFarAtten = showFarAtten
				master.hotspot = hotspot
				master.falloff = falloff
				master.castShadows = castShadows
				master.castSHMShadows = castSHMShadows
				select master
				$.target.pos = gridPoint
			) else #stop
		on mouseMove click do 
			if click == 2 then (
				$.target.pos = worldPoint
				farAttenEnd = distance $.pos $.target.pos
			) else #stop
	)
)

------------------------------------------------------------
-- Free Spot Light
------------------------------------------------------------
plugin light pfsLight
name:"pFreeSpot"
category:"pteroLights"
(
	local master
	
	parameters main rollout:params (
		enabled			type:#boolean	default:true				ui:chkOn
		rgb				type:#color		default:(color 255 252 229)	ui:cpColor
		r				type:#integer	default:255					ui:spnR
		g				type:#integer	default:252					ui:spnG
		b				type:#integer	default:229					ui:spnB
		farAttenEnd		type:#float		default:10					ui:spnRadius
		multiplier		type:#float		default:1					ui:spnAtten
		showFarAtten	type:#boolean	default:true				ui:chkRadius
		hotspot			type:#float		default:45					ui:spnInner
		falloff			type:#float		default:60					ui:spnOuter
		castShadows		type:#boolean	default:true				ui:chkShadows
		castSHMShadows	type:#boolean	default:false				ui:chkSHMShadows

		on enabled set val do
			if selection.count == 1 and (selection[1]) == master do
				master.enabled = val
		on rgb set val do (
			if selection.count == 1 and (selection[1]) == master do
				master.rgb = val
			r = rgb.r
			g = rgb.g
			b = rgb.b
		)
		on farAttenEnd set val do
			if selection.count == 1 and (selection[1]) == master do
				master.farAttenEnd = val
		on multiplier set val do
			if selection.count == 1 and (selection[1]) == master do
				master.multiplier = val
		on showFarAtten set val do
			if selection.count == 1 and (selection[1]) == master do
				master.showFarAtten = val
		on hotspot set val do
			if selection.count == 1 and (selection[1]) == master do
				master.hotspot = val
		on falloff set val do
			if selection.count == 1 and (selection[1]) == master do
				master.falloff = val
		on castShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castShadows = val
		on castSHMShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castSHMShadows = val
	)
	
	rollout params "Free Spot Parameters"
	(
		checkbox		chkOn "On" pos:[8,8] width:40 height:16
		GroupBox		grp3 "Color" pos:[4,28] width:152 height:72
			colorPicker		cpColor "" pos:[12,44] width:56 height:48
			label			lbl4 "R:" pos:[84,44] width:16 height:16
			spinner			spnR "" pos:[100,44] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl5 "G:" pos:[84,60] width:16 height:16
			spinner			spnG "" pos:[100,60] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl6 "B:" pos:[84,76] width:16 height:16
			spinner			spnB "" pos:[100,76] width:45 height:16 range:[0,255,0] type:#integer scale:1
		GroupBox		grp2 "Light luminance" pos:[4,108] width:152 height:76
			label			lbl2 "Distance:" pos:[49,124] width:50 height:16
			spinner			spnRadius "" pos:[96,124] width:53 height:16 range:[0,1e+032,10] type:#float scale:0.01
			label			lbl3 "Linear Attenuat.:" pos:[16,140] width:100 height:16
			spinner			spnAtten "" pos:[96,140] width:53 height:16 range:[0,1e+032,1] type:#float scale:0.01
			checkbox		chkRadius "Show Radius" pos:[12,161] width:128 height:16
		GroupBox		grp4 "Spot/Direct properties" pos:[4,192] width:152 height:56
			label			lbl7 "Inner Angle:" pos:[38,210] width:100 height:16
			spinner			spnInner "" pos:[96,210] width:53 height:16 range:[0,180,0] type:#float scale:0.5
			label			lbl8 "Outer Angle:" pos:[36,226] width:100 height:16
			spinner			spnOuter "" pos:[96,226] width:53 height:16 range:[0,180,0] type:#float scale:0.5
		GroupBox		grp1 "LM properties" pos:[4,256] width:152 height:56
			checkbox		chkShadows "Shadows" pos:[12,274] width:128 height:16
			checkbox		chkSHMShadows "SHM Shadows" pos:[12,290] width:128 height:16

		on spnR changed val do cpColor.color.r = val
		on spnG changed val do cpColor.color.g = val
		on spnB changed val do cpColor.color.b = val
	)
	
	tool create 
	( 
		on start do (
			for n = 1 to selection.count do
				if (classof selection[n]) == pLight do (
					enabled = selection[n].enabled
					farAttenEnd = selection[n].farAttenEnd
					rgb = selection[n].rgb
					multiplier = selection[n].multiplier
					showFarAtten = selection[n].showFarAtten
					hotspot = selection[n].hotspot
					falloff = selection[n].falloff
					castShadows = selection[n].castShadows
					castSHMShadows = selection[n].castSHMShadows
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pLight pos:worldPoint --gridPoint
				master.type = 2
				master.enabled = enabled
				master.farAttenEnd = farAttenEnd
				master.rgb = rgb
				master.multiplier = multiplier
				master.showFarAtten = showFarAtten
				master.hotspot = hotspot
				master.falloff = falloff
				master.castShadows = castShadows
				master.castSHMShadows = castSHMShadows
				select master
			) else #stop
		on mouseMove click do 
			if click == 2 then $.pos = worldPoint
			else #stop
	)
)

------------------------------------------------------------
-- Target Spot Light
------------------------------------------------------------
plugin light ptdLight
name:"pTargetDirect"
category:"pteroLights"
(
	local master
	
	parameters main rollout:params (
		enabled			type:#boolean	default:true				ui:chkOn
		rgb				type:#color		default:(color 255 252 229)	ui:cpColor
		r				type:#integer	default:255					ui:spnR
		g				type:#integer	default:252					ui:spnG
		b				type:#integer	default:229					ui:spnB
		farAttenEnd		type:#float		default:10					ui:spnRadius
		multiplier		type:#float		default:1					ui:spnAtten
		showFarAtten	type:#boolean	default:true				ui:chkRadius
		hotspot			type:#float		default:4.5					ui:spnInner
		falloff			type:#float		default:6.0					ui:spnOuter
		castShadows		type:#boolean	default:true				ui:chkShadows
		castSHMShadows	type:#boolean	default:false				ui:chkSHMShadows

		on enabled set val do
			if selection.count == 1 and (selection[1]) == master do
				master.enabled = val
		on rgb set val do (
			if selection.count == 1 and (selection[1]) == master do
				master.rgb = val
			r = rgb.r
			g = rgb.g
			b = rgb.b
		)
		on farAttenEnd set val do
			if selection.count == 1 and (selection[1]) == master do
				master.farAttenEnd = val
		on multiplier set val do
			if selection.count == 1 and (selection[1]) == master do
				master.multiplier = val
		on showFarAtten set val do
			if selection.count == 1 and (selection[1]) == master do
				master.showFarAtten = val
		on hotspot set val do
			if selection.count == 1 and (selection[1]) == master do
				master.hotspot = val
		on falloff set val do
			if selection.count == 1 and (selection[1]) == master do
				master.falloff = val
		on castShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castShadows = val
		on castSHMShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castSHMShadows = val
	)
	
	rollout params "Target Direct Parameters"
	(
		checkbox		chkOn "On" pos:[8,8] width:40 height:16
		GroupBox		grp3 "Color" pos:[4,28] width:152 height:72
			colorPicker		cpColor "" pos:[12,44] width:56 height:48
			label			lbl4 "R:" pos:[84,44] width:16 height:16
			spinner			spnR "" pos:[100,44] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl5 "G:" pos:[84,60] width:16 height:16
			spinner			spnG "" pos:[100,60] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl6 "B:" pos:[84,76] width:16 height:16
			spinner			spnB "" pos:[100,76] width:45 height:16 range:[0,255,0] type:#integer scale:1
		GroupBox		grp2 "Light luminance" pos:[4,108] width:152 height:76
			label			lbl2 "Distance:" pos:[49,124] width:50 height:16
			spinner			spnRadius "" pos:[96,124] width:53 height:16 range:[0,1e+032,10] type:#float scale:0.01
			label			lbl3 "Linear Attenuat.:" pos:[16,140] width:100 height:16
			spinner			spnAtten "" pos:[96,140] width:53 height:16 range:[0,1e+032,1] type:#float scale:0.01
			checkbox		chkRadius "Show Radius" pos:[12,161] width:128 height:16
		GroupBox		grp4 "Spot/Direct properties" pos:[4,192] width:152 height:56
			label			lbl7 "Inner Radius:" pos:[32,210] width:100 height:16
			spinner			spnInner "" pos:[96,210] width:53 height:16 range:[0,180,0] type:#float scale:0.5
			label			lbl8 "Outer Radius:" pos:[30,226] width:100 height:16
			spinner			spnOuter "" pos:[96,226] width:53 height:16 range:[0,180,0] type:#float scale:0.5
		GroupBox		grp1 "LM properties" pos:[4,256] width:152 height:56
			checkbox		chkShadows "Shadows" pos:[12,274] width:128 height:16
			checkbox		chkSHMShadows "SHM Shadows" pos:[12,290] width:128 height:16

		on spnR changed val do cpColor.color.r = val
		on spnG changed val do cpColor.color.g = val
		on spnB changed val do cpColor.color.b = val
	)
	
	tool create 
	( 
		on start do (
			for n = 1 to selection.count do
				if (classof selection[n]) == pLight do (
					enabled = selection[n].enabled
					farAttenEnd = selection[n].farAttenEnd
					rgb = selection[n].rgb
					multiplier = selection[n].multiplier
					showFarAtten = selection[n].showFarAtten
					hotspot = selection[n].hotspot
					falloff = selection[n].falloff
					castShadows = selection[n].castShadows
					castSHMShadows = selection[n].castSHMShadows
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pLight pos:worldPoint --gridPoint
				master.type = 5
				master.enabled = enabled
				master.farAttenEnd = farAttenEnd
				master.rgb = rgb
				master.multiplier = multiplier
				master.showFarAtten = showFarAtten
				master.hotspot = hotspot
				master.falloff = falloff
				master.castShadows = castShadows
				master.castSHMShadows = castSHMShadows
				select master
				$.target.pos = gridPoint
			) else #stop
		on mouseMove click do 
			if click == 2 then (
				$.target.pos = worldPoint
				farAttenEnd = distance $.pos $.target.pos
			) else #stop
	)
)

------------------------------------------------------------
-- Free Direct Light
------------------------------------------------------------
plugin light pfdLight
name:"pFreeDirect"
category:"pteroLights"
(
	local master
	
	parameters main rollout:params (
		enabled			type:#boolean	default:true				ui:chkOn
		rgb				type:#color		default:(color 255 252 229)	ui:cpColor
		r				type:#integer	default:255					ui:spnR
		g				type:#integer	default:252					ui:spnG
		b				type:#integer	default:229					ui:spnB
		farAttenEnd		type:#float		default:10					ui:spnRadius
		multiplier		type:#float		default:1					ui:spnAtten
		showFarAtten	type:#boolean	default:true				ui:chkRadius
		hotspot			type:#float		default:4.5					ui:spnInner
		falloff			type:#float		default:6.0					ui:spnOuter
		castShadows		type:#boolean	default:true				ui:chkShadows
		castSHMShadows	type:#boolean	default:false				ui:chkSHMShadows

		on enabled set val do
			if selection.count == 1 and (selection[1]) == master do
				master.enabled = val
		on rgb set val do (
			if selection.count == 1 and (selection[1]) == master do
				master.rgb = val
			r = rgb.r
			g = rgb.g
			b = rgb.b
		)
		on farAttenEnd set val do
			if selection.count == 1 and (selection[1]) == master do
				master.farAttenEnd = val
		on multiplier set val do
			if selection.count == 1 and (selection[1]) == master do
				master.multiplier = val
		on showFarAtten set val do
			if selection.count == 1 and (selection[1]) == master do
				master.showFarAtten = val
		on hotspot set val do
			if selection.count == 1 and (selection[1]) == master do
				master.hotspot = val
		on falloff set val do
			if selection.count == 1 and (selection[1]) == master do
				master.falloff = val
		on castShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castShadows = val
		on castSHMShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castSHMShadows = val
	)
	
	rollout params "Free Direct Parameters"
	(
		checkbox		chkOn "On" pos:[8,8] width:40 height:16
		GroupBox		grp3 "Color" pos:[4,28] width:152 height:72
			colorPicker		cpColor "" pos:[12,44] width:56 height:48
			label			lbl4 "R:" pos:[84,44] width:16 height:16
			spinner			spnR "" pos:[100,44] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl5 "G:" pos:[84,60] width:16 height:16
			spinner			spnG "" pos:[100,60] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl6 "B:" pos:[84,76] width:16 height:16
			spinner			spnB "" pos:[100,76] width:45 height:16 range:[0,255,0] type:#integer scale:1
		GroupBox		grp2 "Light luminance" pos:[4,108] width:152 height:76
			label			lbl2 "Distance:" pos:[49,124] width:50 height:16
			spinner			spnRadius "" pos:[96,124] width:53 height:16 range:[0,1e+032,10] type:#float scale:0.01
			label			lbl3 "Linear Attenuat.:" pos:[16,140] width:100 height:16
			spinner			spnAtten "" pos:[96,140] width:53 height:16 range:[0,1e+032,1] type:#float scale:0.01
			checkbox		chkRadius "Show Radius" pos:[12,161] width:128 height:16
		GroupBox		grp4 "Spot/Direct properties" pos:[4,192] width:152 height:56
			label			lbl7 "Inner Radius:" pos:[32,210] width:100 height:16
			spinner			spnInner "" pos:[96,210] width:53 height:16 range:[0,180,0] type:#float scale:0.5
			label			lbl8 "Outer Radius:" pos:[30,226] width:100 height:16
			spinner			spnOuter "" pos:[96,226] width:53 height:16 range:[0,180,0] type:#float scale:0.5
		GroupBox		grp1 "LM properties" pos:[4,256] width:152 height:56
			checkbox		chkShadows "Shadows" pos:[12,274] width:128 height:16
			checkbox		chkSHMShadows "SHM Shadows" pos:[12,290] width:128 height:16

		on spnR changed val do cpColor.color.r = val
		on spnG changed val do cpColor.color.g = val
		on spnB changed val do cpColor.color.b = val
	)
	
	tool create 
	( 
		on start do (
			for n = 1 to selection.count do
				if (classof selection[n]) == pLight do (
					enabled = selection[n].enabled
					farAttenEnd = selection[n].farAttenEnd
					rgb = selection[n].rgb
					multiplier = selection[n].multiplier
					showFarAtten = selection[n].showFarAtten
					hotspot = selection[n].hotspot
					falloff = selection[n].falloff
					castShadows = selection[n].castShadows
					castSHMShadows = selection[n].castSHMShadows
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pLight pos:worldPoint --gridPoint
				master.type = 4
				master.enabled = enabled
				master.farAttenEnd = farAttenEnd
				master.rgb = rgb
				master.multiplier = multiplier
				master.showFarAtten = showFarAtten
				master.hotspot = hotspot
				master.falloff = falloff
				master.castShadows = castShadows
				master.castSHMShadows = castSHMShadows
				select master
			) else #stop
		on mouseMove click do 
			if click == 2 then $.pos = worldPoint
			else #stop
	)
)

------------------------------------------------------------
-- Omni Light
------------------------------------------------------------
plugin light poLight
name:"pOmni"
category:"pteroLights"
(
	local master
	
	parameters main rollout:params (
		enabled			type:#boolean	default:true				ui:chkOn
		rgb				type:#color		default:(color 255 252 229)	ui:cpColor
		r				type:#integer	default:255					ui:spnR
		g				type:#integer	default:252					ui:spnG
		b				type:#integer	default:229					ui:spnB
		farAttenEnd		type:#float		default:10					ui:spnRadius
		multiplier		type:#float		default:1					ui:spnAtten
		showFarAtten	type:#boolean	default:true				ui:chkRadius
		castShadows		type:#boolean	default:true				ui:chkShadows
		castSHMShadows	type:#boolean	default:false				ui:chkSHMShadows

		on enabled set val do
			if selection.count == 1 and (selection[1]) == master do
				master.enabled = val
		on rgb set val do (
			if selection.count == 1 and (selection[1]) == master do
				master.rgb = val
			r = rgb.r
			g = rgb.g
			b = rgb.b
		)
		on farAttenEnd set val do
			if selection.count == 1 and (selection[1]) == master do
				master.farAttenEnd = val
		on multiplier set val do
			if selection.count == 1 and (selection[1]) == master do
				master.multiplier = val
		on showFarAtten set val do
			if selection.count == 1 and (selection[1]) == master do
				master.showFarAtten = val
		on castShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castShadows = val
		on castSHMShadows set val do
			if selection.count == 1 and (selection[1]) == master do
				master.castSHMShadows = val
	)
	
	rollout params "Omni Parameters"
	(
		checkbox		chkOn "On" pos:[8,8] width:40 height:16
		GroupBox		grp3 "Color" pos:[4,28] width:152 height:72
			colorPicker		cpColor "" pos:[12,44] width:56 height:48
			label			lbl4 "R:" pos:[84,44] width:16 height:16
			spinner			spnR "" pos:[100,44] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl5 "G:" pos:[84,60] width:16 height:16
			spinner			spnG "" pos:[100,60] width:45 height:16 range:[0,255,0] type:#integer scale:1
			label			lbl6 "B:" pos:[84,76] width:16 height:16
			spinner			spnB "" pos:[100,76] width:45 height:16 range:[0,255,0] type:#integer scale:1
		GroupBox		grp2 "Light luminance" pos:[4,108] width:152 height:76
			label			lbl2 "Radius:" pos:[58,124] width:36 height:16
			spinner			spnRadius "" pos:[96,124] width:53 height:16 range:[0,1e+032,10] type:#float scale:0.01
			label			lbl3 "Linear Attenuat.:" pos:[16,140] width:100 height:16
			spinner			spnAtten "" pos:[96,140] width:53 height:16 range:[0,1e+032,1] type:#float scale:0.01
			checkbox		chkRadius "Show Radius" pos:[12,161] width:128 height:16
		GroupBox		grp1 "LM properties" pos:[4,192] width:152 height:56
			checkbox		chkShadows "Shadows" pos:[12,210] width:128 height:16
			checkbox		chkSHMShadows "SHM Shadows" pos:[12,226] width:128 height:16

		on spnR changed val do cpColor.color.r = val
		on spnG changed val do cpColor.color.g = val
		on spnB changed val do cpColor.color.b = val
	)
	
	tool create 
	( 
		on start do (
			for n = 1 to selection.count do
				if (classof selection[n]) == pLight do (
					enabled = selection[n].enabled
					farAttenEnd = selection[n].farAttenEnd
					rgb = selection[n].rgb
					multiplier = selection[n].multiplier
					showFarAtten = selection[n].showFarAtten
					castShadows = selection[n].castShadows
					castSHMShadows = selection[n].castSHMShadows
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pLight pos:worldPoint --gridPoint
				master.type = 1
				master.enabled = enabled
				master.farAttenEnd = farAttenEnd
				master.rgb = rgb
				master.multiplier = multiplier
				master.showFarAtten = showFarAtten
				master.castShadows = castShadows
				master.castSHMShadows = castSHMShadows
				select master

--				$.delegate.transform = (matrix3 [0,0,0] [0,0,0] [0,0,0] gridPoint)
/*				invalidateTM $
				nodeInvalRect $
				invalidateWS $
				invalidateTreeTM $
				redrawViews()
*/			) else #stop
		on mouseMove click do 
			if click == 2 then $.pos = worldPoint
			else #stop
	)
)

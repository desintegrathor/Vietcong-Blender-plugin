------------------------------------------------------------
-- pIKJoint Helper
------------------------------------------------------------
plugin simpleObject ConeExt
name:"ConeExt" 
classID:#(0x149da08e, 0x1e5583fe)
category:"Scripted Primitives"
invisible:true
( 
	parameters main rollout:params 
	( 
		radius		type:#worldunits	default:1		ui:radius
		height		type:#worldunits	default:1		ui:height
		sides		type:#integer		default:24		ui:sides
		slice		type:#boolean		default:false	ui:slice
		sliceFrom	type:#integer		default:0		ui:sliceFrom
		sliceTo		type:#integer		default:360		ui:SliceTo
		flipNormals	type:#boolean		default:true	ui:flipNormals
	) 
	rollout params "Two Faces Parameters" 
	( 
		spinner		radius		"Radius [m]:"	type:#worldunits	range:[-99999,99999,1]
		spinner		height		"Height [m]:"	type:#worldunits	range:[-99999,99999,1]
		spinner		sides		"Sides:"		type:#integer		range:[3,500,4]
		checkbox	slice		"Slice"
		spinner		sliceFrom	"From [deg]:"	type:#integer		range:[0,360,0]
		spinner		sliceTo		"To [deg]:"		type:#integer		range:[0,360,360]
		checkbox	flipNormals	"FlipNormals"
	) 
	on buildMesh do 
	( 
		local verts = #([0,0,0])
		local faces = #()
		local vert
		local angle, halfAngle
		local s = sides
		local flip = false
		
		if slice then
		(
			if sliceFrom == 360 do sliceFrom = 0

			halfAngle = abs ((sliceFrom - sliceTo) as float / sides as float)
			
			if abs sliceFrom < abs sliceTo then flip = true
			if flip then
				angle = sliceFrom
			else
				angle = sliceTo
			s += 1
		)
		else
		(
			halfAngle = 360.0 / sides as float
			angle = 0
		)
		
		for n = 1 to s do
		(
			vert = [radius * cos angle, radius * sin angle, height]
			if slice and abs sliceFrom < abs sliceTo then
				angle -= halfAngle
			else
				angle += halfAngle
			append verts vert
			if n > 1 then
				if flipNormals then
				(
					if flip then
						append faces [1, n, n + 1]
					else
						append faces [1, n + 1, n]
				)
				else
				(
					if flip then
						append faces [1, n + 1, n]
					else
						append faces [1, n, n + 1]
				)
		)
		
		if flipNormals then
		(
			if slice then
			(
				append verts [vert.x,vert.y,0]
				append verts [verts[2].x,verts[2].y,0]
				if flip then
				(
					append faces [1, verts.count - 2, verts.count - 1]
					append faces [1, verts.count, 2]
				)
				esle
				(
					append faces [1, verts.count - 1, verts.count - 2]
					append faces [1, 2, verts.count]
				)
			)
			else
				append faces [1, 2, verts.count]
		)
		else
		(
			if slice then
			(
				append verts [0,0,height]
				append faces [1, verts.count - 1, verts.count]
			)
			append faces [1, verts.count, 2]
		)
		
		setMesh mesh verts:verts faces:faces
	) 
	tool create 
	( 
		on mousePoint click do 
		case click of 
		( 
			1: nodeTM.translation = gridPoint 
			3: #stop 
		) 
		on mouseMove click do 
		case click of 
		( 
			2: radius = gridDist.x
			3: height = gridDist.z 
		) 
	) 
) 

plugin helper pIKJoint
name:"pIK Joint"
category:"pteroHelpers"
classID:#(0xb4fcced, 0x68a7d400)
extends:point
replaceUI:true
initialRollupState:0xf7
(
	local helpSphere
	local spinMin, spinMax, swingCone
	local planeZXA, planeZXAm, planeZXB, planeZYA, planeZYAm, planeZYB, rectZXA, rectZXB, rectZYA, rectZYB
	local pointZXA, pointZXB, pointZYA, pointZYB
	local planeTypes = #(
		#("Plane", "Half-Space - Face In", "Half-Space - Face Out"),
		#("", "Half-Space - Face In", "Half-Space - Face Out")
	)
	local bmpZXA = bitmap 32 16 color:(color 255 0 0)
	local bmpZXB = bitmap 32 16 color:(color 255 128 128)
	local bmpZYA = bitmap 32 16 color:(color 0 255 0)
	local bmpZYB = bitmap 32 16 color:(color 196 255 196)
	
	-----------
--	fn fnPickFilter = roMain.controls[2].text != roMain.controls[4].text
	fn fnSelectBitmap idx =
	(
		case idx of
		(
			1: return openBitmap ("$scripts\pterotools\icon_bw\ikjoint_plane.bmp")
			2: return openBitmap ("$scripts\pterotools\icon_bw\ikjoint_halfspacein.bmp")
			3: return openBitmap ("$scripts\pterotools\icon_bw\ikjoint_halfspaceout.bmp")
			101: return openBitmap "$scripts\pterotools\icon_bw\ikjoint_spin.bmp"
			102: return openBitmap "$scripts\pterotools\icon_bw\ikjoint_cone.bmp"
			default: bitmap 10 10 color:(color 255 255 255)
		)
	)
	fn fnPickNode = 
	(
		return try (pickObject  message:"Select Object" count:1 select:false forceListenerFocus:false) catch (undefined)
	)
	-----------
	parameters prmMain rollout:roMain
	(
		OBJECT_A	type:#node		ui:btnObjA
		OBJECT_B	type:#node		ui:btnObjB
		FRICTION	type:#float		ui:spnFriction
		COLLIDE		type:#boolean	ui:chkCollide		default:false
	)
	parameters prmSpint rollout:roSpin
	(
		SPIN_ON			type:#boolean	ui:chkSpinOn	default:false
		SPIN_MIN_ANGLE	type:#float		ui:spnAngleA	default:-180
		SPIN_MAX_ANGLE	type:#float		ui:spnAngleB	default:180
		
		CONE_ON			type:#boolean	ui:chkConeOn	default:false
		CNE_ANG			type:#float		ui:spnConeAngle	default:45
	)
	parameters prmPlanes rollout:roPlanes
	(
		PLANE_ZX_A_ON		type:#boolean	default:false	ui:chkZX1on		
		PLANE_ZX_A_TYPE		type:#index		default:1		ui:ddlZX1type	
		PLANE_ZX_A_OFFSET	type:#float		default:0		ui:spnZX1offset	
		PLANE_ZX_A_LEAN		type:#float		default:0		ui:spnZX1lean
		PLANE_ZX_A_POINT_X	type:#float		default:0		ui:spnZX1pointX
		PLANE_ZX_A_POINT_Y	type:#float		default:0		ui:spnZX1pointY
		
		PLANE_ZX_B_ON		type:#boolean	default:false	ui:chkZX2on		
		PLANE_ZX_B_AUTO		type:#boolean	default:true	ui:chkZX2auto
		PLANE_ZX_B_TYPE		type:#index		default:1		ui:ddlZX2type
		PLANE_ZX_B_OFFSET	type:#float		default:0		ui:spnZX2offset	
		PLANE_ZX_B_LEAN		type:#float		default:0		ui:spnZX2lean
		PLANE_ZX_B_POINT_X	type:#float		default:0		ui:spnZX2pointX
		PLANE_ZX_B_POINT_Y	type:#float		default:0		ui:spnZX2pointY
		
		PLANE_ZY_A_ON		type:#boolean	default:false	ui:chkZY1on		
		PLANE_ZY_A_TYPE		type:#index		default:1		ui:ddlZY1type	
		PLANE_ZY_A_OFFSET	type:#float		default:0		ui:spnZY1offset	
		PLANE_ZY_A_LEAN		type:#float		default:0		ui:spnZY1lean
		PLANE_ZY_A_POINT_X	type:#float		default:0		ui:spnZY1pointX
		PLANE_ZY_A_POINT_Y	type:#float		default:0		ui:spnZY1pointY

		PLANE_ZY_B_ON		type:#boolean	default:false	ui:chkZY2on		
		PLANE_ZY_B_AUTO		type:#boolean	default:true	ui:chkZY2auto
		PLANE_ZY_B_TYPE		type:#index		default:1		ui:ddlZY2type	
		PLANE_ZY_B_OFFSET	type:#float		default:0		ui:spnZY2offset	
		PLANE_ZY_B_LEAN		type:#float		default:0		ui:spnZY2lean
		PLANE_ZY_B_POINT_X	type:#float		default:0		ui:spnZY2pointX
		PLANE_ZY_B_POINT_Y	type:#float		default:0		ui:spnZY2pointY
	)
	-----------
	fn fnUpdateGizmos = 
	(
		local size = 1.0
/*	
		if size < ((abs PLANE_ZX_A_OFFSET) * 2) do size = (abs PLANE_ZX_A_OFFSET) * 2
		if size < ((abs PLANE_ZX_B_OFFSET) * 2) do size = (abs PLANE_ZX_B_OFFSET) * 2
		if size < ((abs PLANE_ZY_A_OFFSET) * 2) do size = (abs PLANE_ZY_A_OFFSET) * 2
		if size < ((abs PLANE_ZY_B_OFFSET) * 2) do size = (abs PLANE_ZY_B_OFFSET) * 2
*/	
		-- help sphere
		if helpSphere != undefined do
		(
			unhide helpSphere
			helpSphere.transform = $.transform
			helpSphere.radius = size
		)
		-- cone
		if swingCone != undefined do
		(
	--				addmodifier swingCone (normalModifier name:"normal")
			unhide swingCone
			swingCone.transform = $.transform
			swingCone.height = size * 1.5
	
			if CNE_ANG <= 90 then
			(
				swingCone.radius = size * tan CNE_ANG
				swingCone.flipNormals = false
				swingCone.wirecolor = color 255 0 255
			)
			else
			(
				swingCone.radius = size * tan (180 - CNE_ANG)
				swingCone.flipNormals = true
				in coordsys $ rotate swingCone 180 x_axis
				swingCone.wirecolor = color 255 128 255
			)
		)
		-- spin
		if SpinMin != undefined do
		(
			unhide SpinMin
			unhide SpinMax
			SpinMin.transform = $.transform
			in coordsys $ move SpinMin [0,0,1]
	
			SpinMin.sliceFrom = 0.01 + SPIN_MAX_ANGLE
			SpinMin.sliceTo = 0
			SpinMax.sliceFrom = 360
			SpinMax.sliceTo = SPIN_MIN_ANGLE - 0.01
			SpinMax.transform = SpinMin.transform
		)
		-- planes
		if planeZXA != undefined do
		(
			unhide planeZXA
			unhide planeZXAm
			planeZXA.width = planeZXAm.width = rectZXA.width = size * 2
			planeZXA.length = planeZXAm.length = rectZXA.length = size * 3
			planeZXA.transform = planeZXAm.transform = $.transform
			in coordsys $ rotate planeZXA (90 + PLANE_ZX_A_LEAN) x_axis
			in coordsys $ rotate planeZXAm (PLANE_ZX_A_LEAN - 90) x_axis
			if PLANE_ZX_A_OFFSET >= 0 and PLANE_ZX_A_TYPE == 3 or
			   PLANE_ZX_A_OFFSET <= 0 and PLANE_ZX_A_TYPE == 2 then
				in coordsys $ rotate planeZXA 180 x_axis
			else
			if PLANE_ZX_A_OFFSET >= 0 and PLANE_ZX_A_TYPE == 2 or
			   PLANE_ZX_A_OFFSET <= 0 and PLANE_ZX_A_TYPE == 3 do
				in coordsys $ rotate planeZXAm 180 x_axis
			in coordsys $ move planeZXA [0, PLANE_ZX_A_OFFSET, 0]
			in coordsys $ move planeZXAm [0, PLANE_ZX_A_OFFSET, 0]
			rectZXA.transform = planeZXA.transform
		)	
	
		if planeZXB != undefined do
		(
			unhide planeZXB
			planeZXB.width = rectZXB.width = size * 2
			planeZXB.length = rectZXB.length = size * 3
			planeZXB.transform = $.transform
			in coordsys $ rotate planeZXB (PLANE_ZX_B_LEAN - 90) x_axis
			if PLANE_ZX_B_OFFSET >= 0 and PLANE_ZX_B_TYPE == 2 or
			   PLANE_ZX_B_OFFSET <= 0 and PLANE_ZX_B_TYPE == 3 do
				in coordsys $ rotate planeZXB 180 x_axis
			in coordsys $ move planeZXB [0, PLANE_ZX_B_OFFSET, 0]
			rectZXB.transform = planeZXB.transform
		)
	
		if planeZYA != undefined do
		(
			unhide planeZYA
			unhide planeZYAm
			planeZYA.width = planeZYAm.width = rectZYA.width = size * 3
			planeZYA.length = planeZYAm.length = rectZYA.length = size * 2
			planeZYA.transform = planeZYAm.transform = $.transform
			in coordsys $ rotate planeZYA (90 + PLANE_ZY_A_LEAN) y_axis
			in coordsys $ rotate planeZYAm (PLANE_ZY_A_LEAN - 90) y_axis
			if PLANE_ZY_A_OFFSET >= 0 and PLANE_ZY_A_TYPE == 2 or
			   PLANE_ZY_A_OFFSET <= 0 and PLANE_ZY_A_TYPE == 3 then
				in coordsys $ rotate planeZYA 180 y_axis
			else
			if PLANE_ZY_A_OFFSET >= 0 and PLANE_ZY_A_TYPE == 3 or
			   PLANE_ZY_A_OFFSET <= 0 and PLANE_ZY_A_TYPE == 2 do
				in coordsys $ rotate planeZYAm 180 y_axis
			in coordsys $ move planeZYA [PLANE_ZY_A_OFFSET, 0, 0]
			in coordsys $ move planeZYAm [PLANE_ZY_A_OFFSET, 0, 0]
			rectZYA.transform = planeZYA.transform
		)
	
		if planeZYB != undefined do
		(
			unhide planeZYB
			planeZYB.width = rectZYB.width = size * 3
			planeZYB.length = rectZYB.length = size * 2
			planeZYB.transform = $.transform
			in coordsys $ rotate planeZYB (PLANE_ZY_B_LEAN - 90) y_axis
			if PLANE_ZY_B_OFFSET >= 0 and PLANE_ZY_B_TYPE == 3 or
			   PLANE_ZY_B_OFFSET <= 0 and PLANE_ZY_B_TYPE == 2 do
				in coordsys $ rotate planeZYB 180 y_axis
			in coordsys $ move planeZYB [PLANE_ZY_B_OFFSET, 0, 0]
			rectZYB.transform = planeZYB.transform
		)
		if pointZXA != undefined do
		(
			pointZXA.transform = $.transform
			in coordsys $ move pointZXA [PLANE_ZX_A_POINT_X, PLANE_ZX_A_POINT_Y, 1]
		)
		if pointZXB != undefined do
		(
			pointZXB.transform = $.transform
			in coordsys $ move pointZXB [PLANE_ZX_B_POINT_X, PLANE_ZX_B_POINT_Y, 1]
		)
		if pointZYA != undefined do
		(
			pointZYA.transform = $.transform
			in coordsys $ move pointZYA [PLANE_ZY_A_POINT_X, PLANE_ZY_A_POINT_Y, 1]
		)
		if pointZYB != undefined do
		(
			pointZYB.transform = $.transform
			in coordsys $ move pointZYB [PLANE_ZY_B_POINT_X, PLANE_ZY_B_POINT_Y, 1]
		)
	)
	fn fnCreateGizmos =
	(
		if selection.count == 1 do if classof selection[1] == pIKJoint do
		(
			-- help sphere
			if helpSphere == undefined do
			(
				helpSphere = sphere name:"IKJointHelpSphere" radius:1 wirecolor:(color 0 0 255)
				helpSphere.visibility = bezier_float()
				helpSphere.visibility.controller.value = 0.2
				attachObjects $ helpSphere
			)
			-- cone
			if swingCone == undefined and CONE_ON then
			(
				swingCone = ConeExt name:"IKJointConeMin" sides:24 height:1 radius:1
				attachObjects $ swingCone
			)
			-- spin
			if spinMin == undefined and SPIN_ON then
			(
				spinMin = cylinder name:"IKJointSpinMin" radius:1 height:0.01 heightsegs:1
				spinMax = cylinder name:"IKJointSpinMAx" radius:1 height:0.01 heightsegs:1
				SpinMin.wirecolor = color 0 128 255
				SpinMax.wirecolor = color 128 0 255
				SpinMin.visibility = SpinMax.visibility = bezier_float()
				SpinMin.visibility.controller.value = SpinMax.visibility.controller.value = 0.5
				SpinMin.slice = SpinMax.slice = true
				attachObjects $ spinMin
				attachObjects $ spinMax
			)
			-- planes
			if planeZXA == undefined and PLANE_ZX_A_ON do
			(
				planeZXA = plane name:"IKJointPlaneZXA" width:1 length:1 lengthsegs:2 widthsegs:2 wirecolor:(color 255 0 0)
				planeZXAm = plane name:"IKJointPlaneZXAm" width:1 length:1 lengthsegs:2 widthsegs:2 wirecolor:(color 255 0 0)
				rectZXA = rectangle name:"IKJointPlaneZXAr" width:1 length:1 wirecolor:(color 255 0 0)
				planeZXA.allEdges = true
				attachObjects $ planeZXA
				attachObjects $ planeZXAm
				attachObjects $ rectZXA
			)
			
			if planeZXB == undefined and PLANE_ZX_B_ON do
			(
				planeZXB = plane name:"IKJointPlaneZXB" width:1 length:1 lengthsegs:2 widthsegs:2 wirecolor:(color 255 128 128)
				rectZXB = rectangle name:"IKJointPlaneZXBr" width:1 length:1 wirecolor:(color 255 128 128)
				attachObjects $ planeZXB
				attachObjects $ rectZXB
			)
			
			if planeZYA == undefined and PLANE_ZY_A_ON do
			(
				planeZYA = plane name:"IKJointPlaneZYA" width:1 length:1 lengthsegs:2 widthsegs:2 wirecolor:(color 0 255 0)
				planeZYAm = plane name:"IKJointPlaneZYAm" width:1 length:1 lengthsegs:2 widthsegs:2 wirecolor:(color 0 255 0)
				rectZYA = rectangle name:"IKJointPlaneZYAr" width:1 length:1 wirecolor:(color 0 255 0)
				attachObjects $ planeZYA
				attachObjects $ planeZYAm
				attachObjects $ rectZYA
			)
			
			if planeZYB == undefined and PLANE_ZY_B_ON do
			(
				planeZYB = plane name:"IKJointPlaneZYB" width:1 length:1 lengthsegs:2 widthsegs:2 wirecolor:(color 196 255 196)
				rectZYB = rectangle name:"IKJointPlaneZYBr" width:1 length:1 wirecolor:(color 196 255 196)
				attachObjects $ planeZYB
				attachObjects $ rectZYB
			)
			-- point
			if pointZXA == undefined and PLANE_ZX_A_ON and (PLANE_ZX_A_POINT_X != 0 or PLANE_ZX_A_POINT_Y != 0) do
			(
				pointZXA = sphere name:"IKJointHelpPointZXA" radius:0.05 wirecolor:(color 255 0 0)
				attachObjects $ pointZXA
			)
			if pointZXB == undefined and PLANE_ZX_B_ON and (PLANE_ZX_B_POINT_X != 0 or PLANE_ZX_B_POINT_Y != 0) do
			(
				pointZXB = sphere name:"IKJointHelpPointZXB" radius:0.05 wirecolor:(color 255 128 128)
				attachObjects $ pointZXB
			)
			if pointZYA == undefined and PLANE_ZY_A_ON and (PLANE_ZY_A_POINT_X != 0 or PLANE_ZY_A_POINT_Y != 0) do
			(
				pointZYA = sphere name:"IKJointHelpPointZYA" radius:0.05 wirecolor:(color 0 255 0)
				attachObjects $ pointZYA
			)
			if pointZYB == undefined and PLANE_ZY_B_ON and (PLANE_ZY_B_POINT_X != 0 or PLANE_ZY_B_POINT_Y != 0) do
			(
				pointZYB = sphere name:"IKJointHelpPointZYB" radius:0.05 wirecolor:(color 196 255 196)
				attachObjects $ pointZYB
			)
		)
	)
	fn fnDeleteGizmos all:false delCone:false = --cleaning:false = 
	(
	--	if cleaning do all = true
		-- help sphere
		if helpSphere != undefined do if all do
		(
			delete helpSphere
			helpSphere = undefined
		)
		-- cone
		if swingCone != undefined do if all or delCone or not CONE_ON do
		(
			delete swingCone
			swingCone = undefined
		)
		-- spin
		if spinMin != undefined do if all or delCone or not SPIN_ON do
		(
			delete spinMin
			delete spinMax
			spinMin = spinMax = undefined
		)
		-- planes
		if planeZXA != undefined do if all or not PLANE_ZX_A_ON do
		(
			delete planeZXA
			delete planeZXAm
			delete rectZXA
			planeZXA = planeZXAm = rectZXA = undefined
		)
		if planeZXB != undefined do if all or not PLANE_ZX_B_ON do 
		(
			delete planeZXB
			delete rectZXB
			planeZXB = rectZXB = undefined
		)
		if planeZYA != undefined do if all or not PLANE_ZY_A_ON do
		(
			delete planeZYA
			delete planeZYAm
			delete rectZYA
			planeZYA = planeZYAm = rectZYA = undefined
		)
		if planeZYB != undefined do if all or not PLANE_ZY_B_ON do 
		(
			delete planeZYB
			delete rectZYB
			planeZYB = rectZYB = undefined
		)
		-- point
		if pointZXA != undefined do if all or not PLANE_ZX_A_ON or (PLANE_ZX_A_POINT_X == 0 and PLANE_ZX_A_POINT_Y == 0) do
		(
			delete pointZXA
			pointZXA = undefined
		)
		if pointZXB != undefined do if all or not PLANE_ZX_B_ON or (PLANE_ZX_B_POINT_X == 0 and PLANE_ZX_B_POINT_Y == 0) do
		(
			delete pointZXB
			pointZXB = undefined
		)
		if pointZYA != undefined do if all or not PLANE_ZY_A_ON or (PLANE_ZY_A_POINT_X == 0 and PLANE_ZY_A_POINT_Y == 0) do
		(
			delete pointZYA
			pointZYA = undefined
		)
		if pointZYB != undefined do if all or not PLANE_ZY_B_ON or (PLANE_ZY_B_POINT_X == 0 and PLANE_ZY_B_POINT_Y == 0) do
		(
			delete pointZYB
			pointZYB = undefined
		)
	--	if cleaning do callbacks.removeScripts id:#pIKJointGizmos
	)
	-----------
	rollout roMain "IK Joint Parameters" rolledup:false
	(
		group "Nodes"
		(
			label		lbl01 "Node A:" width:140 height:16
			pickbutton	btnObjA "" width:115 height:24 offset:[0, -5] align:#left across:2 message:"Select Object" toolTip:"Click to select Node A" select:false
			button		btnWorld "W" width:24 height:24 offset:[0, -5] align:#right toolTip:"Click to Selct Node to World"
			label		lbl02 "Node B:" width:140 height:16
			pickbutton	btnObjB "" width:140 height:24 offset:[0, -5] message:"Select Object" toolTip:"Click to select Node B" select:false
			checkbox	chkCollide	"Collide together" offset:[0, 10]
		)
		group "Options"
		(
			label		lblFriction "Friction [N]:" width:65 height:16  align:#left across:2
			spinner		spnFriction "" width:70 height:16 align:#right range:[0,99999,0] scale:0.1 type:#float
		)
		
		on btnObjA picked obj do
		(
			if obj == undefined then
			(
				btnObjA.text = "World"
				btnWorld.enabled = false
			)
			else
			(
				btnObjA.text = obj.name
				btnWorld.enabled = true
			)
		)
		on btnObjB picked obj do btnObjB.text = if obj == undefined then "- none -" else obj.name
		on btnWorld pressed do
		(
			OBJECT_A = undefined
			btnObjA.text = "World"
			btnWorld.enabled = false
		)
/*		on btnObjA pressed do 
		(
			OBJECT_A = fnPickNode()
			btnObjA.text = if OBJECT_A == undefined then "- none -" else OBJECT_A.name
		)
		on btnObjB pressed do 
		(
			OBJECT_B = fnPickNode()
			btnObjB.text = if OBJECT_B == undefined then "- none -" else OBJECT_B.name
		)
*/		on roMain open do
		(
			if OBJECT_A == undefined then
			(
				btnObjA.text = "World"
				btnWorld.enabled = false
			)
			else
			(
				btnObjA.text = OBJECT_A.name
				btnWorld.enabled = true
			)
			btnObjB.text = if OBJECT_B == undefined then "- none -" else OBJECT_B.name
			
			if selection.count == 1 do if classof selection[1] == pIKJoint do
				delegate.box = false

			fnCreateGizmos()
			fnUpdateGizmos()

			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
		on roMain close do
		(
			delegate.box = true
			fnDeleteGizmos all:true

			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
	)
	-----------
	rollout roSpin "Spin / Swing Cone"-- rolledup:true
	(
		group "Spin Limits"
		(
			checkbox chkSpinOn "Use" align:#left across:2
			imgtag img01 "" width:32 height:32 align:#right bitmap:(openBitmap "$scripts\pterotools\icon_bw\ikjoint_spin.bmp") transparent:(color 255 255 255)
			label lbl01 "Min. Angle:" width:70 height:16 align:#left across:2
			spinner spnAngleA "" width:70 height:16 align:#right range:[-180,0,-180] scale:0.1 type:#float
			label lbl02 "Max. Angle:" width:65 height:16  align:#left across:2
			spinner spnAngleB "" width:70 height:16 align:#right range:[0,180,180] scale:0.1 type:#float
		)
		
		group "Swing Cone"
		(
			checkbox chkConeOn "Use" align:#left across:2
			imgtag img02 "" width:32 height:32 align:#right bitmap:(openBitmap "$scripts\pterotools\icon_bw\ikjoint_cone.bmp") transparent:(color 255 255 255)
			label lbl1 "Limit Angle:" width:65 height:16 align:#left across:2
			spinner spnConeAngle "" width:70 height:16 align:#right range:[0,180,0] scale:0.1 type:#float
		)

		fn fnUpdateUI bmp:false =
		(
			spnAngleA.enabled = spnAngleB.enabled = chkSpinOn.checked
			spnConeAngle.enabled = chkConeOn.checked
			if bmp then
			(
				img01.bitmap = fnSelectBitmap (if chkSpinOn.checked then 101 else 0)
				img02.bitmap = fnSelectBitmap (if chkConeOn.checked then 102 else 0)
				fnDeleteGizmos all:true
				fnCreateGizmos()
			)
			else
			(
				fnDeleteGizmos delCone:true
				fnCreateGizmos()
			)
			fnUpdateGizmos()
		)

		on chkSpinOn changed state do fnUpdateUI bmp:true
		on chkConeOn changed state do fnUpdateUI bmp:true
		on spnAngleA changed val do fnUpdateUI()
		on spnAngleB changed val do fnUpdateUI()
		on spnConeAngle changed val do fnUpdateUI()
		on roSpin open do
		(
			fnUpdateUI bmp:true
		)
		on roSpin close do ()
	)
	-----------
	rollout roPlanes "Planes"-- rolledup:true
	(
		group "Plane ZX: A"
		(
			checkbox chkZX1on "Use" align:#left across:3
			imgtag imgZXA "" width:32 height:16 align:#left bitmap:bmpZXA
			imgtag img01 "" width:32 height:32 align:#right bitmap:(openBitmap "$scripts\pterotools\icon_bw\ikjoint_plane.bmp") transparent:(color 255 255 255)
			label txt01 "Type:" align:#left offset:[0,-16]
			dropdownList ddlZX1type "" width:140 height:40 items:planeTypes[1]
			label lblZX1offset "Offset [m]:" width:65 height:16 align:#left across:2
			spinner spnZX1offset "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZX1lean "Lean [deg]:" width:65 height:16 align:#left across:2
			spinner spnZX1lean "" width:70 height:16 align:#right range:[-90,90,0] scale:0.1 type:#float
			label lblZX1point "Target point offset:" width:100 height:16 align:#left
			label lblZX1pointX "X [m]:" width:65 height:16 align:#left across:2
			spinner spnZX1pointX "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZX1pointY "Y [m]:" width:65 height:16 align:#left across:2
			spinner spnZX1pointY "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
		)
		group "Plane ZX: B"
		(
			checkbox chkZX2on "Use" align:#left across:3
			imgtag imgZXB "" width:32 height:16 align:#left bitmap:bmpZXB
			imgtag img02 "" width:32 height:32 align:#right bitmap:(openBitmap "$scripts\pterotools\icon_bw\ikjoint_plane.bmp") transparent:(color 255 255 255)
			checkbox chkZX2auto "Auto arrange" offset:[0,-20] align:#left
			label txt02 "Type:" align:#left offset:[0,-2]
--			label lblZX2type "" width:140  height:16
			dropdownList ddlZX2type "" width:140 height:40 items:planeTypes[1] offset:[0,-4]
			label lblZX2offset "Offset [m]:" width:65 height:16 align:#left across:2
			spinner spnZX2offset "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZX2lean "Lean [deg]:" width:65 height:16 align:#left across:2
			spinner spnZX2lean "" width:70 height:16 align:#right range:[-90,90,0] scale:0.1 type:#float
			label lblZX2point "Target point offset:" width:100 height:16 align:#left
			label lblZX2pointX "X [m]:" width:65 height:16 align:#left across:2
			spinner spnZX2pointX "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZX2pointY "Y [m]:" width:65 height:16 align:#left across:2
			spinner spnZX2pointY "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
		)
		group "Plane ZY: A"
		(
			checkbox chkZY1on "Use" align:#left across:3
			imgtag imgZYA "" width:32 height:16 align:#left bitmap:bmpZYA
			imgtag img03 "" width:32 height:32 align:#right bitmap:(openBitmap "$scripts\pterotools\icon_bw\ikjoint_plane.bmp") transparent:(color 255 255 255)
			label txt03 "Type:" align:#left offset:[0,-16]
			dropdownList ddlZY1type "" width:140 height:40 items:planeTypes[1]
			label lblZY1offset "Offset [m]:" width:65 height:16 align:#left across:2
			spinner spnZY1offset "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZY1lean "Lean [deg]:" width:65 height:16 align:#left across:2
			spinner spnZY1lean "" width:70 height:16 align:#right range:[-90,90,0] scale:0.1 type:#float
			label lblZY1point "Target point offset:" width:100 height:16 align:#left
			label lblZY1pointX "X [m]:" width:65 height:16 align:#left across:2
			spinner spnZY1pointX "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZY1pointY "Y [m]:" width:65 height:16 align:#left across:2
			spinner spnZY1pointY "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
		)
		group "Plane ZY: B"
		(
			checkbox chkZY2on "Use" align:#left across:3
			imgtag imgZYB "" width:32 height:16 align:#left bitmap:bmpZYB
			imgtag img04 "" width:32 height:32 align:#right bitmap:(openBitmap "$scripts\pterotools\icon_bw\ikjoint_plane.bmp") transparent:(color 255 255 255)
			checkbox chkZY2auto "Auto arrange" offset:[0,-20] align:#left
			label txt04 "Type:" align:#left height:16 offset:[0,-2]
--			label lblZY2type "" width:140  height:16
			dropdownList ddlZY2type "" width:140 height:40 items:planeTypes[1] offset:[0,-4]
			label lblZY2offset "Offset [m]:" width:65 height:16 align:#left across:2
			spinner spnZY2offset "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZY2lean "Lean [deg]:" width:65 height:16 align:#left across:2
			spinner spnZY2lean "" width:70 height:16 align:#right range:[-90,90,0] scale:0.1 type:#float
			label lblZY2point "Target point offset:" width:100 height:16 align:#left
			label lblZY2pointX "X [m]:" width:65 height:16 align:#left across:2
			spinner spnZY2pointX "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
			label lblZY2pointY "Y [m]:" width:65 height:16 align:#left across:2
			spinner spnZY2pointY "" width:70 height:16 align:#right range:[-1,1,0] scale:0.01 type:#float
		)
		fn fnUpdateUI idx:0 =
		(
			local enabledX = PLANE_ZX_A_ON
			local enabledY = PLANE_ZY_A_ON
			
			if idx == 1 or idx == 3 then
			(	-- plane ZX
				if PLANE_ZX_B_AUTO do
				(
					if PLANE_ZX_A_ON then
					(
						if PLANE_ZX_A_TYPE == 1 then
						(
							PLANE_ZX_B_TYPE = 1
							enabledX = false
						)
						else if PLANE_ZX_A_TYPE == 2 then
						(	-- face in
							if PLANE_ZX_B_OFFSET >= 0 and PLANE_ZX_A_OFFSET >= 0 and PLANE_ZX_B_OFFSET > PLANE_ZX_A_OFFSET or
							   PLANE_ZX_B_OFFSET <= 0 and PLANE_ZX_A_OFFSET <= 0 and PLANE_ZX_B_OFFSET < PLANE_ZX_A_OFFSET then
								PLANE_ZX_B_OFFSET = PLANE_ZX_A_OFFSET
								
							if PLANE_ZX_B_OFFSET >= 0 and PLANE_ZX_B_OFFSET <= PLANE_ZX_A_OFFSET or
							   PLANE_ZX_B_OFFSET <= 0 and PLANE_ZX_B_OFFSET >= PLANE_ZX_A_OFFSET then
							(	-- face out
								if PLANE_ZX_B_TYPE != 3 then
								(
									PLANE_ZX_B_TYPE = 3
									idx = 1
								)
							)
							else 
							(	-- face in
								if PLANE_ZX_B_TYPE != 2 then
								(
									PLANE_ZX_B_TYPE = 2
									idx = 1
								)
							)
						)
						else if PLANE_ZX_A_TYPE == 3 then
						(	-- face out
							if PLANE_ZX_A_OFFSET >= 0 and PLANE_ZX_B_OFFSET < PLANE_ZX_A_OFFSET or
							   PLANE_ZX_A_OFFSET <= 0 and PLANE_ZX_B_OFFSET > PLANE_ZX_A_OFFSET then
								PLANE_ZX_B_OFFSET = PLANE_ZX_A_OFFSET
							
							if PLANE_ZX_B_TYPE != 2 then
							(	-- face in
								PLANE_ZX_B_TYPE = 2
								idx = 1
							)
						)
					)
					else
					(
						PLANE_ZX_B_TYPE = 1
						enabledX = false
						idx = 1
					)
				)

				if chkZX2on.enabled != enabledX then
				(
					chkZX2on.enabled = enabledX
					if not chkZX2on.enabled then PLANE_ZX_B_ON = false
				)
			)
			if idx == 1 or idx == 4 then
			(	-- plane ZY
				if PLANE_ZY_B_AUTO do
				(
					if PLANE_ZY_A_ON then
					(
						if PLANE_ZY_A_TYPE == 1 then
						(
							PLANE_ZY_B_TYPE = 1
							enabledY = false
						)
						else if PLANE_ZY_A_TYPE == 2 then
						(	-- face in
							if PLANE_ZY_B_OFFSET >= 0 and PLANE_ZY_A_OFFSET >= 0 and PLANE_ZY_B_OFFSET > PLANE_ZY_A_OFFSET or
							   PLANE_ZY_B_OFFSET <= 0 and PLANE_ZY_A_OFFSET <= 0 and PLANE_ZY_B_OFFSET < PLANE_ZY_A_OFFSET then
								PLANE_ZY_B_OFFSET = PLANE_ZY_A_OFFSET
								
							if PLANE_ZY_B_OFFSET >= 0 and PLANE_ZY_B_OFFSET <= PLANE_ZY_A_OFFSET or
							   PLANE_ZY_B_OFFSET <= 0 and PLANE_ZY_B_OFFSET >= PLANE_ZY_A_OFFSET then
							(	-- face out
								if PLANE_ZY_B_TYPE != 3 then
								(
									PLANE_ZY_B_TYPE = 3
									idx = 1
								)
							)
							else 
							(	-- face in
								if PLANE_ZY_B_TYPE != 2 then
								(
									PLANE_ZY_B_TYPE = 2
									idx = 1
								)
							)
						)
						else if PLANE_ZY_A_TYPE == 3 then
						(	-- face out
							if PLANE_ZY_A_OFFSET >= 0 and PLANE_ZY_B_OFFSET < PLANE_ZY_A_OFFSET or
							   PLANE_ZY_A_OFFSET <= 0 and PLANE_ZY_B_OFFSET > PLANE_ZY_A_OFFSET then
								PLANE_ZY_B_OFFSET = PLANE_ZY_A_OFFSET
							
							if PLANE_ZY_B_TYPE != 2 then
							(	-- face in
								PLANE_ZY_B_TYPE = 2
								idx = 1
							)
						)
					)
					else
					(	-- simply plane
						PLANE_ZY_B_TYPE = 1
						enabledY = false
						idx = 1
					)
				)
				
				if chkZY2on.enabled != enabledY then
				(
					chkZY2on.enabled = enabledY 
					if not chkZY2on.enabled then PLANE_ZY_B_ON = false
				)
			)

			imgZXA.visible = ddlZX1type.enabled = spnZX1offset.enabled = spnZX1lean.enabled = PLANE_ZX_A_ON
			spnZX1pointX.enabled = spnZX1pointY.enabled = PLANE_ZX_A_ON
			imgZXB.visible = chkZX2auto.enabled = spnZX2offset.enabled = spnZX2lean.enabled = PLANE_ZX_B_ON
			spnZX2pointX.enabled = spnZX2pointY.enabled = PLANE_ZX_B_ON
			ddlZX2type.enabled = if PLANE_ZX_B_ON and not PLANE_ZX_B_AUTO then true else false
			
			imgZYA.visible = ddlZY1type.enabled = spnZY1offset.enabled = spnZY1lean.enabled = PLANE_ZY_A_ON
			spnZY1pointX.enabled = spnZY1pointY.enabled = PLANE_ZY_A_ON
			imgZYB.visible = chkZY2auto.enabled = spnZY2offset.enabled = spnZY2lean.enabled = PLANE_ZY_B_ON
			spnZY2pointX.enabled = spnZY2pointY.enabled = PLANE_ZY_B_ON
			ddlZY2type.enabled = if PLANE_ZY_B_ON and not PLANE_ZY_B_AUTO then true else false

			if idx == 1 then
			(
--				lblZX2type.text = planeTypes[2][PLANE_ZX_B_TYPE]
--				lblZY2type.text = planeTypes[2][PLANE_ZY_B_TYPE]
				img01.bitmap = fnSelectBitmap (if PLANE_ZX_A_ON then PLANE_ZX_A_TYPE else 0)
				img02.bitmap = fnSelectBitmap (if PLANE_ZX_B_ON then PLANE_ZX_B_TYPE else 0)
				img03.bitmap = fnSelectBitmap (if PLANE_ZY_A_ON then PLANE_ZY_A_TYPE else 0)
				img04.bitmap = fnSelectBitmap (if PLANE_ZY_B_ON then PLANE_ZY_B_TYPE else 0)
			)

			fnCreateGizmos()
			fnDeleteGizmos()
			fnUpdateGizmos()
		)

		on ddlZX1type selected idx do fnUpdateUI idx:1
		on ddlZX2type selected idx do fnUpdateUI idx:1
		on ddlZY1type selected idx do fnUpdateUI idx:1
		on ddlZY2type selected idx do fnUpdateUI idx:1
		on spnZX1offset changed val do fnUpdateUI idx:3
		on spnZX1lean	changed val do fnUpdateUI idx:3
		on spnZX2offset changed val do fnUpdateUI idx:3
		on spnZX2lean	changed val do fnUpdateUI idx:3
		on spnZX1pointX changed val do fnUpdateUI idx:3
		on spnZX1pointY changed val do fnUpdateUI idx:3
		on spnZX2pointX changed val do fnUpdateUI idx:3
		on spnZX2pointY changed val do fnUpdateUI idx:3
		on spnZY1offset changed val do fnUpdateUI idx:4
		on spnZY1lean	changed val do fnUpdateUI idx:4
		on spnZY2offset changed val do fnUpdateUI idx:4
		on spnZY2lean	changed val do fnUpdateUI idx:4
		on spnZY1pointX changed val do fnUpdateUI idx:4
		on spnZY1pointY changed val do fnUpdateUI idx:4
		on spnZY2pointX changed val do fnUpdateUI idx:4
		on spnZY2pointY changed val do fnUpdateUI idx:4
		on chkZX1on		changed state do fnUpdateUI idx:1
		on chkZX2on		changed state do fnUpdateUI idx:1
		on chkZX2auto	changed state do fnUpdateUI idx:1
		on chkZY1on		changed state do fnUpdateUI idx:1
		on chkZY2on		changed state do fnUpdateUI idx:1
		on chkZY2auto	changed state do fnUpdateUI idx:1
		on roPlanes open do
		(
			fnUpdateUI idx:1
		)
		on roPlanes close do ()
	)
	-----------
	on create do
	(
		delegate.box = true
		delegate.size = 20
		delegate.centerMarker = false
		delegate.constantScreenSize = true

		delegate.axisTripod = true
		delegate.cross = false
		delegate.drawOnTop = false
	)
)

------------------------------------------------------------
-- Main pteroSoundEvent
------------------------------------------------------------
plugin helper pSoundEvent
name:"pSound"
classID:#(0x9c01d0f9, 0xbbc1806e)
extends:point
replaceUI:true
invisible:true
( 
	parameters main rollout:params (
		soundID			type:#integer	default:0	ui:spnID
		soundGroup		type:#integer	default:-1	ui:ddlGroup
		sound			type:#integer	default:-1	ui:ddlSound
		impulse			type:#integer	default:1	ui:rdoImpulse
		interval		type:#float		default:5	ui:spnInterval
		random			type:#float		default:0	ui:spnRandom
		
		on soundID set val do ()
		on soundGroup set val do ()
		on sound set val do ()
	)
	
	rollout params "Sound Parameters"
	(
		GroupBox		grp1		"Main"		pos:[6,2] width:152 height:136
			label			lbl1		"Sound ID:"			pos:[14,18] width:76 height:16
			spinner			spnID		""					pos:[90,18] width:61 height:16 type:#integer range:[0,999999,0]
			dropDownList	ddlGroup	"Group:"			pos:[14,42] width:136 height:40
			dropDownList	ddlSound	"Sound:"			pos:[14,89] width:136 height:40
		GroupBox		grp2		"Impulse" 	pos:[6,144] width:152 height:104
			radioButtons	rdoImpulse	""					pos:[16,160] width:88 height:48 labels:#("Signal", "Effect interval", "Defined") columns:1
			label			lbl2		"Interval (sec):"	pos:[14,209] width:76 height:16
			spinner			spnInterval	""					pos:[90,208] width:61 height:16 range:[0,999999,5] type:#float scale:0.01
			label			lbl3		"Random (sec):"		pos:[14,225] width:76 height:16
			spinner			spnRandom	""					pos:[90,224] width:61 height:16 range:[0,999999,0] type:#float scale:0.01
		on params open do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
		on params close do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
	)
	
	on create do (
		delegate.box = true
		delegate.size = 20
		delegate.centerMarker = true
		delegate.constantScreenSize = true

		delegate.axisTripod = false
		delegate.cross = false
		delegate.drawOnTop = false
	)
)

------------------------------------------------------------
-- Create pteroSoundEvent
------------------------------------------------------------
plugin helper pSoundCreator
name:"pSound"
category:"pteroHelpers"
(
	local master
	
	parameters main rollout:params (
		soundID			type:#integer	default:0	ui:spnID
		soundGroup		type:#integer	default:-1	ui:ddlGroup
		sound			type:#integer	default:-1	ui:ddlSound
		impulse			type:#integer	default:1	ui:rdoImpulse
		interval		type:#float		default:5	ui:spnInterval
		random			type:#float		default:0	ui:spnRandom
		
		on soundID set val do
			if selection.count == 1 and (selection[1]) == master do master.soundID = val
		on soundGroup set val do
			if selection.count == 1 and (selection[1]) == master do master.soundGroup = val
		on sound set val do
			if selection.count == 1 and (selection[1]) == master do master.sound = val
		on impulse set val do
			if selection.count == 1 and (selection[1]) == master do master.impulse = val
		on interval set val do
			if selection.count == 1 and (selection[1]) == master do master.interval = val
		on random set val do
			if selection.count == 1 and (selection[1]) == master do master.random = val
	)
	
	rollout params "Sound Parameters"
	(
		GroupBox		grp1		"Main"		pos:[6,2] width:152 height:136
			label			lbl1		"Sound ID:"			pos:[14,18] width:76 height:16
			spinner			spnID		""					pos:[90,18] width:61 height:16 type:#integer range:[0,999999,0]
			dropDownList	ddlGroup	"Group:"			pos:[14,42] width:136 height:40
			dropDownList	ddlSound	"Sound:"			pos:[14,89] width:136 height:40
		GroupBox		grp2		"Impulse" 	pos:[6,144] width:152 height:104
			radioButtons	rdoImpulse	""					pos:[16,160] width:88 height:48 labels:#("Signal", "Effect interval", "Defined") columns:1
			label			lbl2		"Interval (sec):"	pos:[14,209] width:76 height:16
			spinner			spnInterval	""					pos:[90,208] width:61 height:16 range:[0,999999,5] type:#float scale:0.01
			label			lbl3		"Random (sec):"		pos:[14,225] width:76 height:16
			spinner			spnRandom	""					pos:[90,224] width:61 height:16 range:[0,999999,0] type:#float scale:0.01
		on params open do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
		on params close do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
	)
	
	tool create 
	( 
		on start do (
			for s in selection do
				if classof s == pSoundEvent do (
					soundID = s.soundID
					soundGroup = s.soundGroup
					sound = s.sound
					impulse = s.impulse
					interval = s.interval
					random = s.random
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pSoundEvent pos:worldPoint --gridPoint
				master.soundID = soundID
				master.soundGroup = soundGroup
				master.sound = sound
				master.impulse = impulse
				master.interval = interval
				master.random = random
				select master
				$.wirecolor = color 154 185 229
			) else #stop
		on mouseMove click do 
			if click == 2 then ()--$.pos = worldPoint
			else #stop
	)
)

------------------------------------------------------------
-- Main pteroParticleEvent
------------------------------------------------------------
plugin helper pParticleEvent
name:"pParticle"
classID:#(0x9dac55da, 0x7879a66b)
extends:point
replaceUI:true
invisible:true
( 
	parameters main rollout:params (
		particleID		type:#integer	default:0	ui:spnID
		particleGroup	type:#integer	default:-1	ui:ddlGroup
		particle		type:#integer	default:-1	ui:ddlParticle
		impulse			type:#integer	default:1	ui:rdoImpulse
		interval		type:#float		default:5	ui:spnInterval
		random			type:#float		default:0	ui:spnRandom
		
		on particleID set val do ()
		on particleGroup set val do ()
		on particle set val do ()
	)
	
	rollout params "Particle Parameters"
	(
		GroupBox		grp1		"Main"		pos:[6,2] width:152 height:136
			label			lbl1		"Particle ID:"		pos:[14,18] width:76 height:16
			spinner			spnID		""					pos:[90,18] width:61 height:16 type:#integer range:[0,999999,0]
			dropDownList	ddlGroup	"Effect:"			pos:[14,42] width:136 height:40
			dropDownList	ddlParticle	"Sub-effect:"		pos:[14,89] width:136 height:40
		GroupBox		grp2		"Impulse" 	pos:[6,144] width:152 height:104
			radioButtons	rdoImpulse	""					pos:[16,160] width:88 height:48 labels:#("Signal", "Effect interval", "Defined") columns:1
			label			lbl2		"Interval (sec):"	pos:[14,209] width:76 height:16
			spinner			spnInterval	""					pos:[90,208] width:61 height:16 range:[0,999999,5] type:#float scale:0.01
			label			lbl3		"Random (sec):"		pos:[14,225] width:76 height:16
			spinner			spnRandom	""					pos:[90,224] width:61 height:16 range:[0,999999,0] type:#float scale:0.01
		on params open do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
		on params close do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
	)
	
	on create do (
		delegate.box = true
		delegate.size = 20
		delegate.centerMarker = true
		delegate.constantScreenSize = true

		delegate.axisTripod = false
		delegate.cross = false
		delegate.drawOnTop = false
	)
)

------------------------------------------------------------
-- Create pteroParticleEvent
------------------------------------------------------------
plugin helper pParticleCreator
name:"pParticle"
category:"pteroHelpers"
(
	local master
	
	parameters main rollout:params (
		particleID		type:#integer	default:0	ui:spnID
		particleGroup	type:#integer	default:-1	ui:ddlGroup
		particle		type:#integer	default:-1	ui:ddlParticle
		impulse			type:#integer	default:1	ui:rdoImpulse
		interval		type:#float		default:5	ui:spnInterval
		random			type:#float		default:0	ui:spnRandom
		
		on particleID set val do
			if selection.count == 1 and (selection[1]) == master do master.particleID = val
		on particleGroup set val do
			if selection.count == 1 and (selection[1]) == master do master.particleGroup = val
		on particle set val do
			if selection.count == 1 and (selection[1]) == master do master.particle = val
		on impulse set val do
			if selection.count == 1 and (selection[1]) == master do master.impulse = val
		on interval set val do
			if selection.count == 1 and (selection[1]) == master do master.interval = val
		on random set val do
			if selection.count == 1 and (selection[1]) == master do master.random = val
	)
	
	rollout params "Particle Parameters"
	(
		GroupBox		grp1		"Main"		pos:[6,2] width:152 height:136
			label			lbl1		"Particle ID:"		pos:[14,18] width:76 height:16
			spinner			spnID		""					pos:[90,18] width:61 height:16 type:#integer range:[0,999999,0]
			dropDownList	ddlGroup	"Effect:"			pos:[14,42] width:136 height:40
			dropDownList	ddlParticle	"Sub-effect:"		pos:[14,89] width:136 height:40
		GroupBox		grp2		"Impulse" 	pos:[6,144] width:152 height:104
			radioButtons	rdoImpulse	""					pos:[16,160] width:88 height:48 labels:#("Signal", "Effect interval", "Defined") columns:1
			label			lbl2		"Interval (sec):"	pos:[14,209] width:76 height:16
			spinner			spnInterval	""					pos:[90,208] width:61 height:16 range:[0,999999,5] type:#float scale:0.01
			label			lbl3		"Random (sec):"		pos:[14,225] width:76 height:16
			spinner			spnRandom	""					pos:[90,224] width:61 height:16 range:[0,999999,0] type:#float scale:0.01
		on params open do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
		on params close do
		(
			actionMan.executeAction 0 "370"  -- Tools: Show Selection Bracket Toggle
		)
	)
	
	tool create 
	( 
		on start do (
			for s in selection do
				if classof s == pParticleEvent do (
					particleID = s.particleID
					particleGroup = s.particleGroup
					particle = s.particle
					impulse = s.impulse
					interval = s.interval
					random = s.random
					exit
				)
		)
		on mousePoint click do 
			if click == 1 then (
				master = pParticleEvent pos:worldPoint --gridPoint
				master.particleID = particleID
				master.particleGroup = particleGroup
				master.particle = particle
				master.impulse = impulse
				master.interval = interval
				master.random = random
				select master
				$.wirecolor = color 177 148 26
			) else #stop
		on mouseMove click do 
			if click == 2 then ()--$.pos = worldPoint
			else #stop
	)
)

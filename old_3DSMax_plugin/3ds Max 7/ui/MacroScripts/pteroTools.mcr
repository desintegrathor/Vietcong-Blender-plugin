---------------------------------------------------------------
--
-- PteroTools
--
-- by Pan Collette
--
-- Create: 13.01.2003
-- Modified: 29.12.2003
--
-- MODIFY THIS AT YOUR OWN RISK 
--
---------------------------------------------------------------

-----------------------------------------------
-- PteroProps MacroScript
-----------------------------------------------
macroScript PteroProps
            category:"PteroTools" 
            tooltip:"Open PteroProps Panel" 
            buttontext:"PteroProps Panel"
			icon:#("pteroTools", 2)
(
	on execute do fnCreatePteroProps()
	on isChecked return _isPteroPropsOpen
)

-----------------------------------------------
-- FindSpikeFaces MacroScript
-----------------------------------------------
macroScript FindSpikeFaces
            category:"PteroTools" 
            tooltip:"Find Spike Faces" 
            buttontext:"Find Spike Faces"
			icon:#("pteroTools", 3)
(
	fnFindSpikeFaces()
)

-----------------------------------------------
-- PteroColMatList MacroScript
-----------------------------------------------
macroScript PteroColMatList
            category:"PteroTools" 
            tooltip:"Show Surface Materials List" 
            buttontext:"Surface Materials List"
			icon:#("pteroTools", 4)
(
	on execute do fnColMatList()
	on isChecked return _isColMatListOpen
)

-----------------------------------------------
-- PteroColMatList MacroScript
-----------------------------------------------
macroScript PteroToolsSettings
            category:"PteroTools" 
            tooltip:"Open PteroTools Settings Dialog" 
            buttontext:"PteroTools Settings"
			icon:#("pteroTools", 5)
(
	fnPteroSettings()
)

-----------------------------------------------
-- PrintMappingToBitmap MacroScript
-----------------------------------------------
macroScript PrintMappingToBitmap
            category:"PteroTools" 
            tooltip:"Print Mapping To Bitmap" 
            buttontext:"Print Mapping"
			icon:#("pteroTools", 6)
(
	on execute do fnPrintMappingToBitmap()
	on isChecked return PrintMappingToBitmap
)

-----------------------------------------------
-- CreateBBox MacroScript
-----------------------------------------------
macroScript CreateBBox
            category:"PteroTools" 
            tooltip:"Create Bounding Box for Selection" 
            buttontext:"Create BBox"
			icon:#("pteroTools", 7)
(
	on execute do fnOpenCreateBBoxDialog()
	on isChecked return createBBoxDialog
)

-----------------------------------------------
-- BES Info MacroScript
-----------------------------------------------
macroScript PteroBesInfo
            category:"PteroTools" 
            tooltip:"BES Info Dialog" 
            buttontext:"BES Info"
			icon:#("pteroTools", 8)
(
	rollout besInfoDialog "BES Info Dialog" width:260 height:500
	(
		editText edt1 "" pos:[0,4] width:254 height:492
		
		on besInfoDialog open do (
			edt1.text = fnCreateBesInfo()
		)
	)
	createDialog besInfoDialog modal:true
)

-----------------------------------------------
-- ShowLODs MacroScript
-----------------------------------------------
macroScript ShowLODs
            category:"PteroTools" 
            tooltip:"Show LODs in Viewport" 
            buttontext:"Show LODs"
			icon:#("pteroTools", 9)
(
	on execute do
		if lodNodesVis == undefined then (
			global lodNodesVis = fnGetNodesVisibility()
			callbacks.addScript #viewportChange "fnDoLod()" id:#pteroChangeLOD
			registerRedrawViewsCallback fnLodText
			completeRedraw()
		) else (
			fnSetNodesVisibility lodNodesVis
			lodNodesVis = undefined
			callbacks.removeScripts id:#pteroChangeLOD
			unregisterRedrawViewsCallback fnLodText
			completeRedraw()
		)
	on isChecked return if lodNodesVis == undefined then false else true
)

-----------------------------------------------
-- MeasureDistance MacroScript
-----------------------------------------------
macroScript MeasureDistance
            category:"PteroTools" 
            tooltip:"Measure Distance" 
            buttontext:"Measure Distance"
			icon:#("pteroTools", 10)
(
	on execute do (
		if isMeasureActive != true then (
			isMeasureActive = true
			pushPrompt ("Distance = " + (startTool mtMeasureDistance) as string)
			isMeasureActive = false
		) else (
			stopTool mtMeasureDistance
			isMeasureActive = false
		)
		updateToolbarButtons()
	)
	on isChecked return isMeasureActive
)

-----------------------------------------------
-- Unassign Material From Selection MacroScript
-----------------------------------------------
macroScript UnassignMaterial
            category:"PteroTools" 
            tooltip:"Unassign Material From Selection" 
            buttontext:"Unassign Material"
			icon:#("pteroTools", 11)
(
	if selection.count > 0 do $.material = undefined
)

-----------------------------------------------
-- MeasureDistance MacroScript
-----------------------------------------------
macroScript ReplaceSelection
            category:"PteroTools" 
            tooltip:"Clone Tool: Replace Selection" 
            buttontext:"Create Clones"
			icon:#("pteroTools", 12)
(
	on execute do fnReplaceSelectionByObject()
	on isChecked return isReplaceSelectionActive
)

-----------------------------------------------
-- ReplaceMaterial MacroScript
-----------------------------------------------
macroScript ReplaceMaterial
            category:"PteroTools" 
            tooltip:"Replace pteroMaterial by new one" 
            buttontext:"Replace pteroMat"
			icon:#("pteroTools", 1)
(
	fnSelectMaterialToReplace()
)

-----------------------------------------------
-- ReplaceMultimat MacroScript
-----------------------------------------------
macroScript ReplaceMultimat
            category:"PteroTools" 
            tooltip:"Remove Multimaterial from Multimaterial" 
            buttontext:"Remove multiMat"
			icon:#("pteroTools", 1)
(
	fnDoRemoveFuckedMultimat()
)

-----------------------------------------------
-- Export advanced
-----------------------------------------------
macroScript ExportAdv
            category:"PteroTools" 
            tooltip:"Reset Xform and Export to BES" 
            buttontext:"Export Advanced"
			icon:#("pteroTools", 1)
(
	createDialog ExportAdvanced modal:true
)

-----------------------------------------------
-- ReplaceMultimat MacroScript
-----------------------------------------------
macroScript msHierarchyClipboard
            category:"PteroTools" 
            tooltip:"Store informations about nodes hierarchy" 
            buttontext:"Hierarchy Clipboard"
			icon:#("pteroTools", 1)
(
	on execute do fnHierarchyClipboard()
	on isChecked return isHierarchyClipboardActive
)

-----------------------------------------------
-- msOptimizeMultimats MacroScript
-----------------------------------------------
macroScript msOptimizeMultimats
            category:"PteroTools" 
            tooltip:"Optimize Multimaterials in scene" 
            buttontext:"Optimize Multimaterials"
			icon:#("pteroTools", 1)
(
	createDialog OptimizeMultimaterialsDialog style:#(#style_toolwindow, #style_sysmenu) modal:true
)

-----------------------------------------------
-- ReplaceMultimat MacroScript
-----------------------------------------------
macroScript FindNoCollide
            category:"PteroTools" 
            tooltip:"Find materials with no collisions" 
            buttontext:"Find No Collide Mats"
			icon:#("pteroTools", 1)
(
	fnFindPteroMatWithoutCollisions()
)

-----------------------------------------------
-- EnableBitmapsInViewport MacroScript
-----------------------------------------------
macroScript EnableBitmapsInViewport
            category:"PteroTools" 
            tooltip:"Show bitmaps in materials on selected nodes in viewport" 
            buttontext:"Show bitmaps in viewports"
			icon:#("pteroTools", 1)
(
	fnEnableBitmapsInViewport()
)

-----------------------------------------------
-- SectorChecker MacroScript
-----------------------------------------------
macroScript SectorChecker
            category:"PteroTools" 
            tooltip:"Check Sectors and Portals in scene" 
            buttontext:"Sector Checker"
			icon:#("pteroTools", 1)
(
	on execute do
	(
		if checkSectorsDialogActive == undefined then
			checkSectorsDialogActive = createDialog checkSectorsDialog style:#(#style_toolwindow, #style_sysmenu)
		else
			destroyDialog checkSectorsDialog
	)
	on isChecked return if checkSectorsDialogActive == undefined then false else true 
)

-----------------------------------------------
-- UnwantedMoveFinder MacroScript
-----------------------------------------------
macroScript UnwantedMoveFinder
            category:"PteroTools" 
            tooltip:"Search for unwanted move between nodes" 
            buttontext:"Unwanted move finder"
			icon:#("pteroTools", 1)
(
	fnUnwantedMoveFinder()
)

-----------------------------------------------
-- PteroMatToPteroLayer MacroScript
-----------------------------------------------
macroScript PteroMatToPteroLayer
            category:"PteroTools" 
            tooltip:"Convert pteroMat to pteroLayer" 
            buttontext:"pteroMat to pteroLayer"
			icon:#("pteroTools", 1)
(
	createDialog dlgPteroMatToPteroLayer modal:true
)

-----------------------------------------------
-- PteroMatToStandard MacroScript
-----------------------------------------------
macroScript PteroMatToStandard
            category:"PteroTools" 
            tooltip:"Convert pteroMats to Standard" 
            buttontext:"pteroMats to Standard"
			icon:#("pteroTools", 1)
(
	fnDoConvert()
)

-----------------------------------------------
-- pUnwrap MacroScript
-----------------------------------------------
macroScript pUnwrap_UVW 
		category:"PteroTools" 
		internalcategory:"Modifiers" 
		tooltip:"pUnwrap UVW Modifier" 
		ButtonText:"pUnwrap UVW"
		Icon:#("Material_Modifiers",6)
(
	on execute do AddMod pUnwrap
	on isEnabled return mcrUtils.ValidMod pUnwrap
)


-- EOF
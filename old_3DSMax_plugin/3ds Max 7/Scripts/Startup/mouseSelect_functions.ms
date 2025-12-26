/*
mouseSelect v. 0.3
by Jon Seagull, (c) 2003
scripts@jonseagull.com
written for 3ds max 5.1, compatibility with older versions unknown

What it does
--------------
This script throws up a menu of the objects under the cursor for selection, 
similar to right-clicking Photoshop's move tool to select a layer.  

Select a single object by picking from the menu.

Select multiple objects by holding down the control key while picking.

Use 'All,' with or without the control key, to add/remove all listed objects from the selection.

This is best bound to a key, as it wouldn't be much use in a quad.

INSTALLATION
-------------
Maxscript menu/Run... the .MZP installer file

OR

put mouseSelect_functions.ms in Scripts/Startup
and
Maxscript menu/Run... mouseSelect.mcr

You'll find it in Customize UI under "selections" as "Select Under Mouse"

Known Issues
--------------
-Due to MaxScript limitations, only objects that can evaluate to a mesh, whose normals are 
facing the viewport can be selected (no splines, NURBS, Lights, Cameras, Warps, etc...). 


Future Plans?:
--------------
-add support for other types of objects, maybe by evaluating bounding boxes

*/


global mouseSelectMenu,mouseSelectMenuPos
global mouseSelectObjects = #()

struct mouseSelect
(
fn initialize = 
	(
	local theRay = mapScreentoWorldRay mouse.pos
	local objArray = #()
	for i in geometry where 
		(
			(i.isHidden == false) and 
			(i.isFrozen == false) and	
			(intersectRay i theRay != undefined)
		) 
		
		do append objArray i.inode.handle
	
	--DEBUG
	--print objArray as string
	
	return objArray
	),

fn buildItemString Idx = 
	(
	--itemString += ("	menuItem item" + (i as string) + " \"" + (maxOps.getNodeByHandle mouseSelectObjects[i]).name + "\"\n" )
	local theString = ""
	local theNode = maxops.getNodeByHandle mouseSelectObjects[Idx] 
	
	if not isGroupMember theNode then --show brackets for group members
		(
		theString = "	menuItem item" + (Idx as string) + " \"" + theNode.name + "\"\n"
		)
	else if isOpenGroupMember theNode then
		(
		theString = "	menuItem item" + (Idx as string) + " \"(" + theNode.name + ")\"\n"
		)
	else
		(
		theString = "	menuItem item" + (Idx as string) + " \"[" + theNode.name + "]\"\n"
		)
	return theString
	),
	
fn buildMenu = 
	(
	local itemString = "rcmenu mouseSelectMenu												\n"+
						"	(																\n"+
						"	fn chk obj = return (maxops.getNodeByHandle obj).isSelected		\n"+
						"	-------------													\n"+
						"	menuItem close \"Close\" 										\n"+
						"	separator closeSep 												\n"+
						"	menuItem selectAll \"All\" 										\n"+
						"	separator selectAllSep 											\n"+
						"	-------------													\n"
					
	local openString = 	"	on mouseSelectMenu open do										\n"+
						"		(															\n"
														
	local eventString = 
					"	on close picked do ()																							\n"+
					"	on selectAll picked do 																							\n"+
					"		(																											\n"+
					"		if keyboard.controlPressed then																				\n"+
					"			(																										\n"+
					"			local selectAll = false																					\n"+
					"			for i in 1 to mouseSelectObjects.count do 																\n"+
					"				(																									\n"+
					"				if (maxops.getNodeByHandle mouseSelectObjects[i]).isSelected then continue else selectAll = true	\n"+
					"				)																									\n"+
					"			if selectAll then for i in 1 to mouseSelectObjects.count do selectMore (maxops.getNodeByHandle mouseSelectObjects[i])	\n"+
					"			else for i in 1 to mouseSelectObjects.count do deselect (maxops.getNodeByHandle mouseSelectObjects[i])	\n"+
					"			mouseSelect.select init:true																			\n"+
					"			)																										\n"+
					"		else																										\n"+
					"			(																										\n"+
					"			clearSelection()																						\n"+
					"			for i in 1 to mouseSelectObjects.count do selectMore (maxops.getNodeByHandle mouseSelectObjects[i])		\n"+
					"			)																										\n"+
					"		)																											\n"
					

	for i in 1 to mouseSelectObjects.count do 
		(
		local nodeHandle = mouseSelectObjects[i] as string
		itemString += mouseSelect.buildItemString i
		openString += ("		item" + (i as string) + ".checked = chk " + nodeHandle + "\n")
		eventString += ("	on item" + (i as string) + " picked do mouseSelect.menuPicked (maxops.getNodeByHandle " + nodeHandle + ")\n")
		)
			
	theString = itemString + openString + "		)\n" + eventString + "	)"
	
	--DEBUG
	--print theString
	
	return theString
	),

fn menuPicked obj = 
	(
	if keyboard.controlPressed then
		(
		if obj.isSelected then deselect obj else selectmore obj
		mouseSelect.select init:true
		)
	else select obj	
	),
	
fn select init:false = 
	(
	if init == false then --
		(
		mouseSelectObjects = mouseSelect.initialize()
		execute (mouseSelect.buildmenu()) 
		registerRightClickMenu mouseSelectMenu
		mouseSelectMenuPos = mouse.screenpos
		)
	
	popUpMenu mouseSelectMenu pos:mouseSelectMenuPos
	)
	
	
)--end struct
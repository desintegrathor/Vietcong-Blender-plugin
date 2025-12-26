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

macroscript mouseSelect category:"Selection" internalCategory:"Selection" toolTip:"Select Under Mouse" 
(
	if js_mouseSelect == undefined do js_mouseSelect = mouseSelect()
	js_mouseSelect.select()
)
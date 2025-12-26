--******************************************
-- Object Renaming Utility
-- 1.29.99 v1.06
-- David Humpherys
-- david@rezn8.com
--******************************************
MacroScript RenameObjects
enabledIn:#("max", "viz") --pfb: 2003.12.12 added product switch
	category:"Tools"
	tooltip:"Rename Objects..." --pfb 24 mai 2003: added "..." after the name
	buttontext:"Rename Objects..."
(	
	global ReNameFloater
	local MyAry = #()
	local PickAry = #()
	local checked = false
	rollout RenameRollout "Rename Objects" width:216 height:312
	(
		radiobuttons objs "" pos:[48,12] width:129 height:16 labels:#("Selected", "Pick") columns:2
		checkbox base "" pos:[8,40] width:16 height:16 checked:false
		edittext base_text "Base Name: " pos:[26,40] width:172 height:16 enabled:true fieldwidth:101 
		checkbox prefix "" pos:[8,73] width:16 height:16
		edittext pre_text "Prefix: " pos:[26,73] width:172 height:16 enabled:true fieldwidth:101 
		spinner delPreSpin "" pos:[96,97] width:45 height:16 range:[0,20,0] type:#integer
		checkbox delPre "Remove First:" pos:[8,97] width:89 height:16 
		checkbox suffix "" pos:[8,130] width:16 height:16
		edittext suf_text "Suffix: " pos:[26,130] width:172 height:16 enabled:true fieldwidth:101 
		spinner delSufSpin "" pos:[96,154] width:45 height:16 range:[0,20,0] type:#integer
		checkbox delSuf "Remove Last:" pos:[8,154] width:90 height:16 
		checkbox suf_num "Numbered" pos:[8,187] width:200 height:16 checked:true
		spinner base_num "Base Number: " pos:[58,207] width:90 height:16 range:[1,9999,1] type:#integer 
		spinner num_step "Step: " pos:[81,228] width:68 height:16 range:[-999,999,1] type:#integer 
		checkbox chk_num "Check unique names" pos:[48,248] width:152 height:16 checked:true
		button do_rename "Rename" pos:[8,272] width:200 height:30

		label lbl16 "Digits" pos:[145,97] width:40 height:16
		label lbl17 "Digits" pos:[145,154] width:40 height:16
		on objs changed state do
		(
			if objs.state==2 then
			(
			-- CAL-06/21/02: use the previously picked object if selectByName is canceled
			MyAry = selectByName title:"Pick Objects to Rename" buttonText:"Use"
			if MyAry == undefined then MyAry = PickAry else PickAry = MyAry
--			print MyAry
			MyAry = MyAry as array
			)
		)
		on base_text changed state do
		(
			base.checked = if state.count > 0 then true else false
		)
		on pre_text changed state do
		(
			prefix.checked = if state.count > 0 then true else false
		)
		on suf_text changed state do
		(
			suffix.checked = if state.count > 0 then true else false
		)
		on delPreSpin changed state do
		(
			delPre.checked = if state > 0 then true else false
		)
		on delSufSpin changed state do
		(
			delSuf.checked = if state > 0 then true else false
		)
		on suf_num changed state do
		(
			chk_num.enabled = state
			chk_num.checked = state
		)
/* CAL-07/16/02: leave them on all the times to be consistent with other checkboxes
		on base changed state do
		(
			if state==on then base_text.enabled=true
			if state==off then base_text.enabled=false
		)
		on prefix changed state do
		(
			if state==on then pre_text.enabled=true
			if state==off then pre_text.enabled=false
		)
		on suffix changed state do
		(
			if state==on then suf_text.enabled=true
			if state==off then suf_text.enabled=false
		)
*/
		on do_rename pressed do with undo on with redraw off
		(	
			if objs.state==1 then MyAry = selection as array
			findErrors=0
			CountNum=1
			for i in MyAry do
			(			
				local newName = ""
				
				if base.state==true then 
					(
					if base_text.text.count==0 then 
						(
						messagebox "Base Name text field empty." Title:"Base Rename Error"
						exit loop
						)
					newName = base_text.text
					)
		
				if delpre.state==true then 
					(	
					if delprespin.value >= newName.count then 
						(
						messagebox "The object being renamed doesn't have enough characters in
its name to remove the requested number. Rename cancelled." Title:"Prefix Rename Error:" 
						FindErrors=1
						exit loop
						)
					newName = (substring newName (delprespin.value+1) newName.count)
					)
					
				if prefix.state==true then 
					(
					if Pre_text.text.count==0 then 
						(
						messagebox "Add Prefix text field empty." Title:"Prefix Rename Error:"
						FindErrors=1
						exit loop
						)
					newName=(pre_text.text + newName)
					)
							
				if delsuf.state==true then 
					(
					if delsufspin.value>=newName.count then 
						(
						messagebox "The object being renamed doesn't have enough characters in
its name to remove the requested number. Rename cancelled." Title:"Suffix Rename Error:"
						FindErrors=1
						exit loop
						)
					newName=(substring newName 1 (newName.count-delsufspin.value))
					)
					
				if suffix.state==true then 
					(
					if suf_text.text.count==0 then 
						(
						messagebox "Add Suffix text field empty." Title:"Suffix Rename Error:"
						FindErrors=1
						exit loop
						)
					newName=(newName + suf_text.text)
					)
		
				local finder = undefined
				local numberedName = newName
				if suf_num.state==true then do
				(
					NumberPad=((base_num.value + ((CountNum-1)*num_step.value)) as string)
					if NumberPad.count == 1 then NumberPad=("0"+NumberPad)
					numberedName = newName + NumberPad
					if chk_num.checked do try
					(
						finder = execute ("$" + numberedName + "*")
						if (finder.count < 2) then
						(
							finder = execute ("$" + numberedName)
							if (findItem MyAry finder) > 0 then finder = undefined
						)
					)
					catch
					(
						finder = numberedName
					)
					CountNum+=1
				)
				while (finder != undefined) and (CountNum < 100000)
				
				i.name = numberedName
			)
			-- Remove the comments from this line to close the rollout each time you rename
			--if findErrors == 0 then (closerolloutfloater ReNameFloater)
			
		)
		
		on renamerollout open do
		(
			setfocus base_text
		)
		
		on renamerollout close do
		(
			checked = false
			updateToolbarButtons()
		)
	)
on execute do	
	(
		createDialog renamerollout 
		checked = true
	)

on closeDialogs do
	(
		destroyDialog renamerollout
	)
on isChecked return (checked)
)





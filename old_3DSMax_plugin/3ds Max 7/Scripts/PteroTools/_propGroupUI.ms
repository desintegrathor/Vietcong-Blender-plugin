group "" (
	checkbutton	btnAuto	"AutoSet"		images:(fnReturnFilename #lckIcon)	width:22	height:18	offset:[0,-6]	across:6	toolTip:"Auto-Set Properties to Node"
	button		btnSet	"Set"			images:(fnReturnFilename #setIcon)	width:22	height:18	offset:[0,-6]				toolTip:"Set Properties to Node"
	checkbutton	btnAcq	"Acquire"		images:(fnReturnFilename #acqIcon)	width:22	height:18	offset:[0,-6]				toolTip:"Acquire Properties from Node ..."
	button		btnDef	"Template"		images:(fnReturnFilename #defIcon)	width:22	height:18	offset:[0,-6]				toolTip:"Use Template"
	button		btnSav	"Save Template"	images:(fnReturnFilename #savIcon)	width:22	height:18	offset:[0,-6]				toolTip:"Save Template"
	button		btnDel	"Delete"		images:(fnReturnFilename #delIcon)	width:22	height:18	offset:[0,-6]				toolTip:"Delete Properties from Node"
)

plugin modifier pUnwrap
name:"pUnwrap"
classID:#(0x2d220693, 0x7ac2d5dc)
extends:UVWunwrap
replaceUI:false
version:1
(
	local lastMap = 0
	
	fn fnAppendPteroLayer matList mat =
	(
		if (classof mat) == Multimaterial do
		(
			for m in mat do
			(
				if m == undefined then
					continue
				else
				if (classof m) == UndefinedClass then
					continue
				else
				if (classof m) == Multimaterial then
					fnAppendPteroLayer matList m
				else
				if (m.classid[1] == 1222670497) and (m.classid[2] == 782138873) then
				(
					if (findItem matList m) == 0 then
						append matList m
				)
			)
		)
		return matList
	)
	
	fn fnGetPteroLayerMaterials =
	(
		local matList = #()
		
		for n in $ do
		(
			matList = fnAppendPteroLayer matList n.material
		)
		
		return matList
	)
	
	fn fnAppendMaps =
	(
		local matList = fnGetPteroLayerMaterials()
		local curMap = this.unwrap_uvw.getCurrentMap()
		
		for m in matList do
		(
			for f in m.layerFilename do
			(
				local map
				local idx = bitmapTable.getIDX f
				if idx == 0 do continue
				map = bitmapTable.getTextureByIDX idx
				this.unwrap_uvw.addMap map
			)
		)
		
		if lastMap == 0 or lastMap > this.unwrap_uvw.numberMaps() then
			this.unwrap_uvw.SetCurrentMap curMap
		else
			this.unwrap_uvw.SetCurrentMap lastMap
	)
	
	rollout roRefresh "pteroLayer bitmap list"
	(
		button btnRefresh "Refresh" width:140 height:30
		
		on btnRefresh pressed do
		(
			fnAppendMaps()
		)
		on roRefresh open do
		(
			local ver = maxVersion()
			if ver[1] < 7000 then
				btnRefresh.enabled = false
		)
		on roRefresh close do
		(
			lastMap = this.unwrap_uvw.getCurrentMap()
		)
	)
	
	on create do
	(
	)
	on load do 
	(
	)
)
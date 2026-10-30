function create()
	cutscene = Video(0, 0, "stressCutscene", true, true)
	cutscene.scrollFactor:set()
	cutscene.cameras = {state.camOther}
	cutscene:play()
	state:add(cutscene)
	cutscene.onComplete = function()
		close()
	end
end

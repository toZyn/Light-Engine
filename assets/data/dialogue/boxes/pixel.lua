local bgFade, music, kindb

function create(_, kind)
	local color = kind == "thorns" and Color.BLACK or Color.convert({179, 223, 216})

	bgFade = Graphic(0, 0, game.width, game.height, color)
	bgFade.alpha = 0
	add(bgFade)

	if kind == "default" then
		music = game.sound.play(paths.getMusic('gameplay/Lunchbox'), 0.8, true, true)
	end

	kindb = kind
end

function resize()
	if bgFade then
		bgFade.width, bgFade.height = game.width, game.height
	end
end

function postCreate()
	local dlg = self
	Timer.wait(kindb == "angry" and 1.5 or 2, function()
		if not dlg or dlg._closed or dlg.allFinished then return end
		for loop = 1, 5 do
			Timer.wait(0.83 * loop, function()
				if not dlg or dlg._closed or dlg.allFinished or not bgFade then return end
				bgFade.alpha = bgFade.alpha + (1 / 5) * 0.7
				if bgFade.alpha > 0.7 then
					bgFade.alpha = 0.7
				end
			end)
		end
		if not dlg.started and startDialogue then
			startDialogue()
		end
	end)
	dlg:startDialogue()
	return Event_Cancel
end

function finishDialogue()
	local dlg = self
	local boxRef, charsRef, fadeRef, musicRef = box, characters, bgFade, music
	util.playSfx(nextSound)
	if musicRef then musicRef:fade(1, 0.8, 0) end
	for loop = 1, 5 do
		Timer.wait(0.2 * loop, function()
			if not dlg or dlg._closed then return end
			if boxRef then
				boxRef.alpha = boxRef.alpha - 1 / 5
				if charsRef then charsRef.alpha = boxRef.alpha end
			end
			if fadeRef then
				fadeRef.alpha = fadeRef.alpha - 1 / 5 * 0.7
			end
		end)
	end
	Timer.wait(1, function()
		if not dlg or dlg._closed then return end
		if musicRef then musicRef:stop() end
		if closeDialogue then closeDialogue() end
	end)

	return Event_Cancel
end

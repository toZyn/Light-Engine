local ChartingState = State:extend("ChartingState")

ChartingState.GRID_SIZE = 40
ChartingState.COLS = 9 -- col 0 = Events, cols 1..4 = Opponent, cols 5..8 = Player
ChartingState.QUANTS = {4, 8, 12, 16, 24, 32, 48, 64}
ChartingState.NOTE_COLORS = {
	{0.76, 0.29, 0.60}, -- Left  (#C24B99)
	{0.00, 1.00, 1.00}, -- Down  (#00FFFF)
	{0.07, 0.98, 0.02}, -- Up    (#12FA05)
	{0.98, 0.22, 0.25}  -- Right (#F9393F)
}
ChartingState.DIR_LABELS = {"<", "v", "^", ">"}
ChartingState.EVENT_PRESETS = {
	"FocusCamera",
	"Add Camera Zoom",
	"ZoomCamera",
	"ScrollSpeed",
	"PlayAnimation",
	"Change Character",
	"Camera Flash",
	"Screen Shake",
	"Hey!"
}
ChartingState.NOTE_TYPES = {
	"Normal",
	"Alt Anim",
	"GF Sing",
	"Hurt Note"
}

-- Lightweight viewport-culled timeline renderer (zero per-note Sprite allocations)
local TimelineCanvas = Object:extend("TimelineCanvas")

function TimelineCanvas:new(editor, x, y)
	TimelineCanvas.super.new(self, x, y)
	self.editor = editor
	self.width = ChartingState.COLS * ChartingState.GRID_SIZE
	self.height = game.height
	self.scrollFactor:set(0, 0)
end

function TimelineCanvas:__render(camera)
	local ed = self.editor
	if not ed or not ed.song then return end

	local gs = ChartingState.GRID_SIZE
	local gx = self.x
	local playheadY = ed.playheadY
	local curStep = ed.curStepFloat
	local viewTopStep = curStep - (playheadY / gs) - 2
	local viewBottomStep = curStep + ((game.height - playheadY) / gs) + 2
	local maxSteps = ed:getTotalSteps()

	local firstStep = math.max(0, math.floor(viewTopStep))
	local lastStep = math.min(maxSteps + 16, math.ceil(viewBottomStep))

	local r, g, b, a = love.graphics.getColor()
	local prevLineW = love.graphics.getLineWidth()
	local prevFont = love.graphics.getFont()
	love.graphics.setFont(ed.smallFont)

	-- 1. Draw visible grid cells
	for step = firstStep, lastStep do
		local sy = playheadY + (step - curStep) * gs
		local secIdx = math.floor(step / 16) + 1
		local sec = ed.sections[secIdx]
		local mustHit = sec and sec.mustHitSection

		for col = 0, ChartingState.COLS - 1 do
			local cx = gx + col * gs
			local parity = ((step + col) % 2 == 0)
			local shade = parity and 0.20 or 0.16
			if step >= maxSteps then
				shade = shade * 0.55
			elseif col == 0 then
				love.graphics.setColor(shade * 0.9, shade * 0.85, shade * 1.15, 0.95)
			else
				local isPlayerSide = col >= 5
				local focused = (mustHit and isPlayerSide) or (not mustHit and not isPlayerSide)
				local boost = focused and 0.04 or 0
				love.graphics.setColor(shade + boost, shade + boost, shade + boost + 0.02, 0.95)
			end
			if col ~= 0 or step >= maxSteps then
				if col == 0 then
					love.graphics.setColor(shade * 0.9, shade * 0.85, shade * 1.15, 0.95)
				end
			end
			love.graphics.rectangle("fill", cx, sy, gs, gs)
		end

		-- Beat and measure lines
		if step % 16 == 0 then
			love.graphics.setColor(0.95, 0.95, 1.0, 0.85)
			love.graphics.setLineWidth(2)
			love.graphics.line(gx, sy, gx + self.width, sy)
			local mNum = math.floor(step / 16)
			love.graphics.print(tostring(mNum), gx - 34, sy - 7)
		elseif step % 4 == 0 then
			love.graphics.setColor(0.65, 0.68, 0.78, 0.45)
			love.graphics.setLineWidth(1)
			love.graphics.line(gx, sy, gx + self.width, sy)
		end
	end

	-- Column dividers (Event | Opponent | Player)
	love.graphics.setLineWidth(2)
	love.graphics.setColor(0.85, 0.75, 1.0, 0.8)
	love.graphics.line(gx + gs, 0, gx + gs, game.height)
	love.graphics.setColor(1.0, 1.0, 1.0, 0.85)
	love.graphics.line(gx + gs * 5, 0, gx + gs * 5, game.height)
	love.graphics.setColor(0.1, 0.1, 0.14, 0.9)
	love.graphics.rectangle("line", gx, 0, self.width, game.height)

	-- Hover cell preview
	if ed.hoverCol and ed.hoverStep and not ed:isMouseOverUI() then
		local hx = gx + ed.hoverCol * gs
		local hy = playheadY + (ed.hoverStep - curStep) * gs
		love.graphics.setColor(1, 1, 1, 0.22)
		love.graphics.rectangle("fill", hx, hy, gs, gs)
		love.graphics.setColor(1, 1, 1, 0.65)
		love.graphics.setLineWidth(1.5)
		love.graphics.rectangle("line", hx + 1, hy + 1, gs - 2, gs - 2)
	end

	-- 2. Draw visible Events (col 0)
	local events = ed.song.events or {}
	for i = 1, #events do
		local ev = events[i]
		local evStep = ed:timeToStep(ev.t)
		if evStep >= viewTopStep - 2 and evStep <= viewBottomStep + 2 then
			local ey = playheadY + (evStep - curStep) * gs
			local ex = gx
			local isSelected = (ed.selectedEvent == ev)
			love.graphics.setColor(isSelected and 1.0 or 0.72, isSelected and 0.84 or 0.45, 0.98, 0.92)
			love.graphics.rectangle("fill", ex + 4, ey + 4, gs - 8, gs - 8, 5, 5)
			love.graphics.setColor(1, 1, 1, 0.95)
			love.graphics.setLineWidth(isSelected and 2.5 or 1)
			love.graphics.rectangle("line", ex + 4, ey + 4, gs - 8, gs - 8, 5, 5)
			love.graphics.print("E", ex + 15, ey + 11)
			local label = tostring(ev.e or "")
			love.graphics.setColor(0.92, 0.85, 1.0, 0.9)
			love.graphics.print(label, gx - math.min(180, ed.smallFont:getWidth(label) + 42), ey + 11)
		end
	end

	-- 3. Draw visible Notes (Opponent = cols 1..4, Player = cols 5..8)
	local function drawTrack(list, colOffset)
		if not list then return end
		for i = 1, #list do
			local n = list[i]
			local nStep = ed:timeToStep(n.t)
			local susSteps = (n.l and n.l > 0) and (ed:timeToStep(n.t + n.l) - nStep) or 0
			if (nStep + susSteps) >= viewTopStep - 1 and nStep <= viewBottomStep + 1 then
				local d = (tonumber(n.d) or 0) % 4
				local col = colOffset + d
				local nx = gx + col * gs
				local ny = playheadY + (nStep - curStep) * gs
				local colRGB = ChartingState.NOTE_COLORS[d + 1]
				local passed = n.t < ed.curTimeMs - 2

				-- Sustain bar
				if susSteps > 0.05 then
					local sh = susSteps * gs
					love.graphics.setColor(colRGB[1], colRGB[2], colRGB[3], passed and 0.35 or 0.65)
					love.graphics.rectangle("fill", nx + gs * 0.35, ny + gs * 0.5, gs * 0.30, sh, 3, 3)
					love.graphics.setColor(1, 1, 1, passed and 0.35 or 0.75)
					love.graphics.rectangle("fill", nx + gs * 0.28, ny + gs * 0.5 + sh - 5, gs * 0.44, 5, 2, 2)
				end

				-- Note body
				local alpha = passed and 0.48 or 0.96
				love.graphics.setColor(colRGB[1], colRGB[2], colRGB[3], alpha)
				love.graphics.rectangle("fill", nx + 3, ny + 3, gs - 6, gs - 6, 6, 6)

				local isSelected = (ed.selectedNote == n)
				love.graphics.setLineWidth(isSelected and 2.5 or 1.2)
				if isSelected then
					love.graphics.setColor(1, 1, 0.35, 1)
				else
					love.graphics.setColor(1, 1, 1, alpha * 0.85)
				end
				love.graphics.rectangle("line", nx + 3, ny + 3, gs - 6, gs - 6, 6, 6)

				-- Direction glyph / NoteType badge
				love.graphics.setColor(0.08, 0.08, 0.12, alpha)
				local badge = ChartingState.DIR_LABELS[d + 1]
				if n.gf then
					badge = "GF"
				elseif n.k == "alt" then
					badge = "ALT"
				elseif type(n.k) == "string" and n.k ~= "" then
					badge = n.k:sub(1, 3):upper()
				end
				local bw = ed.smallFont:getWidth(badge)
				love.graphics.print(badge, nx + (gs - bw) * 0.5, ny + 11)
			end
		end
	end

	drawTrack(ed.song.notes.enemy, 1)
	drawTrack(ed.song.notes.player, 5)

	-- Active drag-sustain preview
	if ed.dragNote then
		local dn = ed.dragNote
		local col = (dn._side == "player" and 5 or 1) + (dn.d % 4)
		local nx = gx + col * gs
		local nStep = ed:timeToStep(dn.t)
		local ny = playheadY + (nStep - curStep) * gs
		love.graphics.setColor(1, 1, 0.4, 0.9)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", nx + 1, ny + 1, gs - 2, gs - 2, 6, 6)
	end

	-- 4. Header lane labels & playhead receptor bar
	love.graphics.setColor(0.07, 0.07, 0.11, 0.92)
	love.graphics.rectangle("fill", gx, 0, self.width, 28)
	love.graphics.setColor(0.85, 0.85, 0.95, 0.95)
	love.graphics.print("EV", gx + 11, 6)
	love.graphics.print("OPPONENT (DAD)", gx + gs + 24, 6)
	love.graphics.print("PLAYER (BF)", gx + gs * 5 + 36, 6)

	love.graphics.setColor(1.0, 0.32, 0.38, 0.95)
	love.graphics.setLineWidth(3)
	love.graphics.line(gx - 8, playheadY, gx + self.width + 8, playheadY)

	love.graphics.setLineWidth(prevLineW)
	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
end

-- Build Psych/Vanilla-compatible export table that round-trips losslessly with Parser
function ChartingState.buildExportData(song, sections)
	local bpm = tonumber(song.bpm) or 120
	local totalMs = 0
	local allNotes = {}

	for _, n in ipairs(song.notes and song.notes.player or {}) do
		totalMs = math.max(totalMs, (n.t or 0) + (n.l or 0))
		table.insert(allNotes, {note = n, player = true})
	end
	for _, n in ipairs(song.notes and song.notes.enemy or {}) do
		totalMs = math.max(totalMs, (n.t or 0) + (n.l or 0))
		table.insert(allNotes, {note = n, player = false})
	end
	for _, ev in ipairs(song.events or {}) do
		totalMs = math.max(totalMs, ev.t or 0)
	end

	local outSections = {}
	local secTime = 0
	local curBpm = bpm
	local secIdx = 1
	local minSections = math.max(1, sections and #sections or 1)

	while secTime <= totalMs + 1 or secIdx <= minSections do
		local srcSec = sections and sections[secIdx]
		local secBpm = (srcSec and srcSec.changeBPM and tonumber(srcSec.bpm)) or curBpm
		local changeBPM = (srcSec and srcSec.changeBPM and secBpm ~= curBpm) or false
		if changeBPM then curBpm = secBpm end
		local stepMs = ((60 / curBpm) * 1000) / 4
		local secDur = stepMs * 16

		table.insert(outSections, {
			sectionBeats = 4,
			sectionNotes = {},
			mustHitSection = srcSec and (srcSec.mustHitSection ~= false) or true,
			gfSection = (srcSec and srcSec.gfSection) or false,
			bpm = curBpm,
			changeBPM = changeBPM,
			altAnim = false,
			_startMs = secTime,
			_endMs = secTime + secDur
		})

		secTime = secTime + secDur
		secIdx = secIdx + 1
		if secIdx > 2048 then break end
	end

	-- Assign each note to its enclosing section (format = "psych_v1": 0..3 = player, 4..7 = enemy)
	for _, entry in ipairs(allNotes) do
		local n = entry.note
		local t = tonumber(n.t) or 0
		local targetSec = outSections[#outSections]
		for i = 1, #outSections do
			local s = outSections[i]
			if t >= s._startMs - 0.5 and t < s._endMs - 0.5 then
				targetSec = s
				break
			end
		end
		local d = (tonumber(n.d) or 0) % 4
		local col = entry.player and d or (d + 4)
		local rawNote = {t, col, tonumber(n.l) or 0}
		if n.gf then
			rawNote[4] = "GF Sing"
		elseif n.k == "alt" then
			rawNote[4] = true
		elseif type(n.k) == "string" and n.k ~= "" then
			rawNote[4] = n.k
		end
		table.insert(targetSec.sectionNotes, rawNote)
	end

	for _, s in ipairs(outSections) do
		table.sort(s.sectionNotes, function(a, b)
			if a[1] == b[1] then return a[2] < b[2] end
			return a[1] < b[1]
		end)
		s._startMs = nil
		s._endMs = nil
	end

	-- Group custom events (skipping section-generated FocusCamera unless custom offset)
	local groupedEvents = {}
	local eventMap = {}
	for _, ev in ipairs(song.events or {}) do
		if ev and ev.e and ev.e ~= "FocusCamera" then
			local key = string.format("%.3f", tonumber(ev.t) or 0)
			if not eventMap[key] then
				eventMap[key] = {tonumber(ev.t) or 0, {}}
				table.insert(groupedEvents, eventMap[key])
			end
			local v1, v2 = "", ""
			if type(ev.v) == "table" then
				v1 = ev.v[1] ~= nil and tostring(ev.v[1]) or tostring(ev.v.zoom or ev.v.scroll or ev.v.anim or ev.v.rate or "")
				v2 = ev.v[2] ~= nil and tostring(ev.v[2]) or tostring(ev.v.duration or ev.v.target or ev.v.intensity or "")
			elseif ev.v ~= nil then
				v1 = tostring(ev.v)
			end
			table.insert(eventMap[key][2], {ev.e, v1, v2})
		end
	end
	table.sort(groupedEvents, function(a, b) return a[1] < b[1] end)

	return {
		song = {
			song = song.song or "bopeebo",
			bpm = bpm,
			speed = tonumber(song.speed) or 1,
			needsVoices = true,
			player1 = song.player1 or "bf",
			player2 = song.player2 or "dad",
			gfVersion = song.gfVersion or "gf",
			stage = song.stage or "stage",
			skin = song.skin or "default",
			format = "psych_v1",
			notes = outSections,
			events = groupedEvents
		}
	}
end

function ChartingState:enter()
	ChartingState.super.enter(self)

	PlayState.chartingMode = true
	Discord.changePresence({details = "In the Editor", state = "Chart Editor"})

	if not PlayState.SONG then
		local ok = pcall(PlayState.loadSong, "bopeebo", PlayState.songDifficulty or "normal")
		if not ok or not PlayState.SONG then
			PlayState.SONG = Parser.getDummyChart("bopeebo", true)
		end
	end

	self.song = PlayState.SONG
	self.song.notes = self.song.notes or {player = {}, enemy = {}}
	self.song.notes.player = self.song.notes.player or {}
	self.song.notes.enemy = self.song.notes.enemy or {}
	self.song.events = self.song.events or {}
	self.curDifficulty = (PlayState.songDifficulty and PlayState.songDifficulty ~= "")
		and PlayState.songDifficulty:lower() or "normal"

	self.quantIdx = 4 -- 16th default
	self.curQuant = ChartingState.QUANTS[self.quantIdx]
	self.curNoteType = "Normal"
	self.curTimeMs = 0
	self.curStepFloat = 0
	self.playheadY = 220
	self.playing = false
	self.playbackRate = 1
	self.metronome = false
	self.hitSoundsPlayer = true
	self.hitSoundsEnemy = false
	self._lastBeatHit = -1

	self.selectedNote = nil
	self.selectedEvent = nil
	self.dragNote = nil
	self.clipboardSection = nil
	self.undoStack = {}
	self.redoStack = {}
	self.textInputs = {}

	self.smallFont = paths.getFont("vcr.ttf", 14) or love.graphics.getFont()
	self.uiFont = paths.getFont("vcr.ttf", 15) or love.graphics.getFont()

	-- Background
	self.bg = Sprite(0, 0, paths.getImage("menus/menuDesat"))
	self.bg:setGraphicSize(game.width, game.height)
	self.bg:updateHitbox()
	self.bg:screenCenter()
	self.bg.scrollFactor:set(0, 0)
	self.bg.color = Color.fromRGB(34, 36, 52)
	self:add(self.bg)

	self:rebuildConductorAndSections()
	self:loadSongAudio()

	-- Timeline canvas on the left-center
	self.gridX = 210
	self.timeline = TimelineCanvas(self, self.gridX, 0)
	self:add(self.timeline)

	-- Build right-hand inspector UI & status HUD
	self:buildInspectorUI()
	self:syncSectionInspector()

	if Mouse and Mouse.SetCursor then Mouse.SetCursor("arrow") end
end

function ChartingState:rebuildConductorAndSections()
	local bpm = tonumber(self.song.bpm) or 120
	local tcList = (self.song.timeChanges and #self.song.timeChanges > 0)
		and self.song.timeChanges
		or {Parser.newTimeChange(0, bpm)}
	self.conductor = Conductor(tcList)

	-- Reconstruct per-section metadata (mustHitSection, gfSection, BPM changes)
	self.sections = {}
	local totalSteps = math.max(64, self:computeRawMaxSteps() + 32)
	local numSecs = math.max(4, math.ceil(totalSteps / 16))
	for i = 1, numSecs do
		self.sections[i] = {
			mustHitSection = true,
			gfSection = false,
			changeBPM = false,
			bpm = bpm
		}
	end

	-- Infer FocusCamera per section from existing events
	for _, ev in ipairs(self.song.events or {}) do
		if ev.e == "FocusCamera" then
			local st = self:timeToStep(ev.t or 0)
			local sIdx = math.max(1, math.floor(st / 16 + 0.5) + 1)
			local v = type(ev.v) == "table" and (ev.v.char or ev.v[1]) or ev.v
			for j = sIdx, #self.sections do
				self.sections[j].gfSection = (v == 2 or v == "2")
				self.sections[j].mustHitSection = (v == 0 or v == "0" or v == "bf")
			end
		end
	end

	for _, tc in ipairs(self.song.timeChanges or {}) do
		if tc.t and tc.t > 0 and tc.bpm then
			local st = tc.step or self:timeToStep(tc.t)
			local sIdx = math.max(1, math.floor(st / 16 + 0.5) + 1)
			if self.sections[sIdx] then
				self.sections[sIdx].changeBPM = true
				self.sections[sIdx].bpm = tc.bpm
			end
		end
	end
end

function ChartingState:computeRawMaxSteps()
	local maxMs = 0
	if self.inst and self.inst.duration then
		maxMs = math.max(maxMs, self.inst.duration * 1000)
	end
	for _, n in ipairs(self.song.notes.player or {}) do
		maxMs = math.max(maxMs, (n.t or 0) + (n.l or 0))
	end
	for _, n in ipairs(self.song.notes.enemy or {}) do
		maxMs = math.max(maxMs, (n.t or 0) + (n.l or 0))
	end
	for _, ev in ipairs(self.song.events or {}) do
		maxMs = math.max(maxMs, ev.t or 0)
	end
	local stepMs = ((60 / (tonumber(self.song.bpm) or 120)) * 1000) / 4
	return math.ceil(maxMs / math.max(1, stepMs))
end

function ChartingState:getTotalSteps()
	local instMs = (self.inst and self.inst.duration and self.inst.duration > 0)
		and (self.inst.duration * 1000) or 0
	local stepMs = self.conductor and self.conductor.stepCrotchet or 125
	local byAudio = instMs > 0 and math.ceil(instMs / stepMs) or 0
	return math.max(byAudio, #self.sections * 16)
end

function ChartingState:timeToStep(ms)
	local stepMs = self.conductor and self.conductor.stepCrotchet or (((60 / (self.song.bpm or 120)) * 1000) / 4)
	return (tonumber(ms) or 0) / math.max(0.001, stepMs)
end

function ChartingState:stepToTime(step)
	local stepMs = self.conductor and self.conductor.stepCrotchet or (((60 / (self.song.bpm or 120)) * 1000) / 4)
	return step * stepMs
end

function ChartingState:quantizeStep(rawStep)
	local stepSnap = 16 / (self.curQuant or 16)
	return math.max(0, math.floor(rawStep / stepSnap + 0.0001) * stepSnap)
end

function ChartingState:loadSongAudio()
	if game.sound.music then game.sound.music:stop() end
	if self.vocalsPlayer then self.vocalsPlayer:destroy(); self.vocalsPlayer = nil end
	if self.vocalsEnemy then self.vocalsEnemy:destroy(); self.vocalsEnemy = nil end

	local songKey = paths.formatToSongPath(self.song.song or "bopeebo")
	local instData = paths.getInst(songKey, self.curDifficulty, true) or paths.getInst(songKey, nil, true)
	if instData then
		game.sound.loadMusic(instData)
		game.sound.music:pause()
		self.inst = game.sound.music
	else
		self.inst = nil
	end

	local p1 = self.song.player1 or "bf"
	local p2 = self.song.player2 or "dad"
	local vMain = paths.getVoices(songKey, self.curDifficulty, false) or paths.getVoices(songKey, nil, false)
	local vP1 = paths.getVoices(songKey, p1, false) or vMain
	local vP2 = paths.getVoices(songKey, p2, false)
	if vP1 then
		self.vocalsPlayer = game.sound.load(vP1)
		self.vocalsPlayer:pause()
	end
	if vP2 and vP2 ~= vP1 then
		self.vocalsEnemy = game.sound.load(vP2)
		self.vocalsEnemy:pause()
	end

	self.hitSoundAsset = paths.getSound("hitsound") or paths.getSound("scrollMenu")
	self:rebuildConductorAndSections()
end

function ChartingState:collectAssetList(subPath, fallback)
	local out, seen = {}, {}
	for _, item in ipairs(paths.getItems(subPath, "file", "json") or {}) do
		local id = item:gsub("%.json$", "")
		if not seen[id] then
			seen[id] = true
			table.insert(out, id)
		end
	end
	if #out == 0 then
		for _, f in ipairs(fallback) do table.insert(out, f) end
	end
	table.sort(out)
	return out
end

function ChartingState:registerInput(inp)
	table.insert(self.textInputs, inp)
	return inp
end

function ChartingState:isTyping()
	for _, inp in ipairs(self.textInputs) do
		if inp.focused then return true end
	end
	return false
end

function ChartingState:isMouseOverUI()
	return Mouse.x >= self.panelX or Mouse.x < self.gridX
end

function ChartingState:buildInspectorUI()
	self.panelX = 606
	local pw = game.width - self.panelX - 18

	-- Left info HUD card
	self.infoBg = Graphic(12, 12, 186, game.height - 24, Color.fromRGB(16, 18, 28))
	self.infoBg.alpha = 0.90
	self.infoBg.scrollFactor:set(0, 0)
	self:add(self.infoBg)

	self.infoText = Text(20, 18, "", self.smallFont, Color.WHITE, "left", 170)
	self.infoText.scrollFactor:set(0, 0)
	self:add(self.infoText)

	local function addHudBtn(x, y, w, h, label, cb)
		local btn = UIButton(x, y, w, h, label, cb)
		btn.font = self.smallFont
		btn.scrollFactor:set(0, 0)
		self:add(btn)
		return btn
	end

	self.btnPlayPause = addHudBtn(18, 286, 84, 28, "Play/Pause", function()
		self:setPlaybackPlaying(not self.playing)
	end)
	self.btnExitEditor = addHudBtn(108, 286, 84, 28, "Exit", function()
		self:setPlaybackPlaying(false)
		PlayState.chartingMode = false
		util.playMenuMusic()
		game.switchState(FreeplayState())
	end)
	addHudBtn(18, 320, 84, 26, "< Sec", function()
		if self.playing then self:setPlaybackPlaying(false) end
		local targetSec = math.max(0, self:getCurrentSectionIndex() - 2)
		self:seekMs(self:stepToTime(targetSec * 16))
	end)
	addHudBtn(108, 320, 84, 26, "Sec >", function()
		if self.playing then self:setPlaybackPlaying(false) end
		local targetSec = self:getCurrentSectionIndex()
		self:seekMs(self:stepToTime(targetSec * 16))
	end)
	addHudBtn(18, 352, 84, 26, "- Step", function()
		if self.playing then self:setPlaybackPlaying(false) end
		local stepJump = 16 / (self.curQuant or 16)
		self:seekMs(self.curTimeMs - self:stepToTime(stepJump))
	end)
	addHudBtn(108, 352, 84, 26, "+ Step", function()
		if self.playing then self:setPlaybackPlaying(false) end
		local stepJump = 16 / (self.curQuant or 16)
		self:seekMs(self.curTimeMs + self:stepToTime(stepJump))
	end)
	addHudBtn(18, 384, 84, 26, "- Tail", function() self:adjustSelectedSustain(-1) end)
	addHudBtn(108, 384, 84, 26, "+ Tail", function() self:adjustSelectedSustain(1) end)

	local shortcutHelp = table.concat({
		"SHORTCUTS",
		"SPACE : Play/Pause",
		"W/S/Wheel : Scrub",
		"A / D : Prev/Next Sec",
		"LEFT/RIGHT : Snap",
		"Click/Tap : Add/Del",
		"Drag : Sustain Tail",
		"Q / E : -/+ Sustain",
		"CTRL+Z / Y : Undo/Redo",
		"CTRL+S : Save Chart",
		"ENTER : Playtest",
		"ESC : Exit Editor"
	}, "\n")
	self.helpText = Text(20, math.max(418, game.height - 236), shortcutHelp, self.smallFont, Color.fromRGB(185, 195, 220), "left", 170)
	self.helpText.scrollFactor:set(0, 0)
	self:add(self.helpText)

	-- Right TabMenu Inspector
	self.tabs = UITabMenu(self.panelX, 14, {"Song", "Section", "Events", "Tools"}, pw, game.height - 28)
	self.tabs.scrollFactor:set(0, 0)
	self:add(self.tabs)

	local charList = self:collectAssetList("data/characters", {"bf", "dad", "gf", "pico", "spooky", "mom"})
	local stageList = self:collectAssetList("data/stages", {"stage", "spooky", "philly", "limo", "mall", "school", "tank"})
	local skinList = self:collectAssetList("data/skins", {"default", "default-pixel"})

	-- TAB 1: SONG
	local gSong = Group()
	local function lbl(grp, x, y, text)
		local t = Text(x, y, text, self.smallFont, Color.fromRGB(210, 215, 235))
		grp:add(t)
		return t
	end

	lbl(gSong, 16, 12, "Song Folder / Name:")
	self.inSongName = self:registerInput(UIInputTextBox(16, 30, 240, 26, self.uiFont))
	self.inSongName.text = tostring(self.song.song or "bopeebo")
	self.inSongName.onChanged = function(val)
		if val ~= "" then self.song.song = val end
	end
	gSong:add(self.inSongName)

	lbl(gSong, 270, 12, "Difficulty:")
	local diffs = {"easy", "normal", "hard", "erect", "nightmare"}
	if not table.find(diffs, self.curDifficulty) then table.insert(diffs, self.curDifficulty) end
	self.ddDiff = UIDropDown(270, 30, diffs, math.max(1, table.find(diffs, self.curDifficulty) or 2), 140, 26)
	self.ddDiff.callback = function(val) self.curDifficulty = val end
	gSong:add(self.ddDiff)

	local btnLoadSong = UIButton(424, 30, 200, 26, "Load Song / Diff", function()
		self:reloadTargetSong(self.inSongName.text, self.curDifficulty)
	end)
	gSong:add(btnLoadSong)

	lbl(gSong, 16, 68, "BPM:")
	self.stBPM = UINumericStepper(16, 86, 1, tonumber(self.song.bpm) or 120, 20, 999, 130, 26)
	self.stBPM.onChanged = function(v)
		self.song.bpm = v
		self.conductor:mapTimeChanges({Parser.newTimeChange(0, v)})
	end
	self:registerInput(self.stBPM)
	gSong:add(self.stBPM)

	lbl(gSong, 170, 68, "Scroll Speed:")
	self.stSpeed = UINumericStepper(170, 86, 0.1, tonumber(self.song.speed) or 1, 0.1, 10, 130, 26)
	self.stSpeed.onChanged = function(v) self.song.speed = v end
	self:registerInput(self.stSpeed)
	gSong:add(self.stSpeed)

	self.cbMuteInst = UICheckbox(330, 88, 20)
	self.cbMuteInst.callback = function(c)
		if self.inst then self.inst.volume = c and 0 or 1 end
	end
	gSong:add(self.cbMuteInst)
	lbl(gSong, 358, 90, "Mute Inst")

	self.cbMuteVocals = UICheckbox(470, 88, 20)
	self.cbMuteVocals.callback = function(c)
		local vol = c and 0 or 1
		if self.vocalsPlayer then self.vocalsPlayer.volume = vol end
		if self.vocalsEnemy then self.vocalsEnemy.volume = vol end
	end
	gSong:add(self.cbMuteVocals)
	lbl(gSong, 498, 90, "Mute Voices")

	-- Save & Playtest action row
	local btnSave = UIButton(16, 360, 195, 34, "Save Chart (Ctrl+S)", function() self:saveChart(false) end)
	local btnSaveMeta = UIButton(222, 360, 195, 34, "Save Song Meta", function() self:saveSongMeta() end)
	local btnPlaytest = UIButton(428, 360, 195, 34, "Playtest Song (Enter)", function() self:playtestSong(false) end)
	local btnPlayHere = UIButton(16, 404, 300, 32, "Playtest From Here (Shift+Enter)", function() self:playtestSong(true) end)
	gSong:add(btnSave)
	gSong:add(btnSaveMeta)
	gSong:add(btnPlaytest)
	gSong:add(btnPlayHere)

	-- Add dropdowns last in gSong so open popup lists render above buttons!
	lbl(gSong, 16, 132, "Player 1 (BF):")
	self.ddP1 = UIDropDown(16, 150, charList, math.max(1, table.find(charList, self.song.player1 or "bf") or 1), 190, 26)
	self.ddP1.callback = function(v) self.song.player1 = v end

	lbl(gSong, 224, 132, "Opponent (Dad):")
	self.ddP2 = UIDropDown(224, 150, charList, math.max(1, table.find(charList, self.song.player2 or "dad") or 1), 190, 26)
	self.ddP2.callback = function(v) self.song.player2 = v end

	lbl(gSong, 432, 132, "Girlfriend (GF):")
	self.ddGF = UIDropDown(432, 150, charList, math.max(1, table.find(charList, self.song.gfVersion or "gf") or 1), 190, 26)
	self.ddGF.callback = function(v) self.song.gfVersion = v end

	lbl(gSong, 16, 200, "Stage:")
	self.ddStage = UIDropDown(16, 218, stageList, math.max(1, table.find(stageList, self.song.stage or "stage") or 1), 240, 26)
	self.ddStage.callback = function(v) self.song.stage = v end

	lbl(gSong, 276, 200, "Note Skin:")
	self.ddSkin = UIDropDown(276, 218, skinList, math.max(1, table.find(skinList, self.song.skin or "default") or 1), 240, 26)
	self.ddSkin.callback = function(v) self.song.skin = v end

	gSong:add(self.ddStage)
	gSong:add(self.ddSkin)
	gSong:add(self.ddP1)
	gSong:add(self.ddP2)
	gSong:add(self.ddGF)
	self.tabs:addGroup(gSong, 1)

	-- TAB 2: SECTION
	local gSec = Group()
	self.secTitle = lbl(gSec, 16, 14, "Section #0")

	self.cbMustHit = UICheckbox(16, 46, 22)
	self.cbMustHit.checked = true
	self.cbMustHit.callback = function(c)
		local sec = self:getCurrentSection(true)
		sec.mustHitSection = c
		self:rebuildFocusEventsFromSections()
	end
	gSec:add(self.cbMustHit)
	lbl(gSec, 46, 48, "Camera Focus Player (Must Hit Section)")

	self.cbGFSec = UICheckbox(16, 80, 22)
	self.cbGFSec.callback = function(c)
		local sec = self:getCurrentSection(true)
		sec.gfSection = c
		self:rebuildFocusEventsFromSections()
	end
	gSec:add(self.cbGFSec)
	lbl(gSec, 46, 82, "GF Section (Camera Focus GF)")

	self.cbSecBPM = UICheckbox(16, 118, 22)
	self.cbSecBPM.callback = function(c)
		local sec = self:getCurrentSection(true)
		sec.changeBPM = c
	end
	gSec:add(self.cbSecBPM)
	lbl(gSec, 46, 120, "Change BPM on this Section:")

	self.stSecBPM = UINumericStepper(280, 114, 1, tonumber(self.song.bpm) or 120, 20, 999, 135, 26)
	self.stSecBPM.onChanged = function(v)
		local sec = self:getCurrentSection(true)
		sec.bpm = v
	end
	self:registerInput(self.stSecBPM)
	gSec:add(self.stSecBPM)

	gSec:add(UIButton(16, 168, 190, 32, "Copy Section (Ctrl+C)", function() self:copyCurrentSection() end))
	gSec:add(UIButton(218, 168, 190, 32, "Paste Section (Ctrl+V)", function() self:pasteSection() end))
	gSec:add(UIButton(420, 168, 195, 32, "Clear Section Notes", function() self:clearCurrentSection() end))
	gSec:add(UIButton(16, 212, 290, 32, "Swap Sides (BF <-> Dad)", function() self:swapCurrentSectionSides() end))
	gSec:add(UIButton(320, 212, 295, 32, "Mirror Lanes (L<->R, D<->U)", function() self:mirrorCurrentSection() end))
	self.tabs:addGroup(gSec, 2)

	-- TAB 3: EVENTS
	local gEv = Group()
	lbl(gEv, 16, 14, "Event Type (Preset or Custom):")
	self.inEventName = self:registerInput(UIInputTextBox(260, 34, 355, 26, self.uiFont))
	self.inEventName.text = ChartingState.EVENT_PRESETS[1]
	gEv:add(self.inEventName)

	lbl(gEv, 16, 78, "Value 1 (e.g. target / zoom / mult / color):")
	self.inEventV1 = self:registerInput(UIInputTextBox(16, 98, 290, 26, self.uiFont))
	gEv:add(self.inEventV1)

	lbl(gEv, 325, 78, "Value 2 (e.g. duration / anim / intensity):")
	self.inEventV2 = self:registerInput(UIInputTextBox(325, 98, 290, 26, self.uiFont))
	gEv:add(self.inEventV2)

	gEv:add(UIButton(16, 146, 290, 34, "Add / Update Event at Playhead", function()
		self:placeOrUpdateEventAt(self:stepToTime(self:quantizeStep(self.curStepFloat)))
	end))
	gEv:add(UIButton(325, 146, 290, 34, "Delete Selected / Playhead Event", function()
		self:deleteEventAtPlayhead()
	end))

	self.evHintText = lbl(gEv, 16, 198, "Tip: Click column 'EV' on the timeline to place or inspect events.")
	self.ddEventPreset = UIDropDown(16, 34, ChartingState.EVENT_PRESETS, 1, 230, 26)
	self.ddEventPreset.callback = function(v)
		self.inEventName.text = v
	end
	gEv:add(self.ddEventPreset)
	self.tabs:addGroup(gEv, 3)

	-- TAB 4: TOOLS
	local gTools = Group()
	lbl(gTools, 16, 14, "Grid Snap Quantization:")
	local quantLabels = {}
	for i, q in ipairs(ChartingState.QUANTS) do quantLabels[i] = "1/" .. tostring(q) .. " step" end

	lbl(gTools, 260, 14, "Note Type:")
	self.inNoteType = self:registerInput(UIInputTextBox(435, 34, 185, 26, self.uiFont))
	self.inNoteType.text = "Normal"
	self.inNoteType.onChanged = function(v)
		self.curNoteType = (v == "" and "Normal" or v)
	end
	gTools:add(self.inNoteType)

	self.cbHitP1 = UICheckbox(16, 86, 22)
	self.cbHitP1.checked = self.hitSoundsPlayer
	self.cbHitP1.callback = function(c) self.hitSoundsPlayer = c end
	gTools:add(self.cbHitP1)
	lbl(gTools, 46, 88, "Player Hitsounds")

	self.cbHitP2 = UICheckbox(230, 86, 22)
	self.cbHitP2.checked = self.hitSoundsEnemy
	self.cbHitP2.callback = function(c) self.hitSoundsEnemy = c end
	gTools:add(self.cbHitP2)
	lbl(gTools, 260, 88, "Opponent Hitsounds")

	self.cbMetro = UICheckbox(450, 86, 22)
	self.cbMetro.checked = self.metronome
	self.cbMetro.callback = function(c) self.metronome = c end
	gTools:add(self.cbMetro)
	lbl(gTools, 480, 88, "Metronome")

	lbl(gTools, 16, 128, "Editor Playback Speed:")
	self.stRate = UINumericStepper(16, 148, 0.25, 1.0, 0.25, 2.0, 140, 26)
	self.stRate.onChanged = function(v)
		self.playbackRate = v
		if self.inst then self.inst:setPitch(v) end
		if self.vocalsPlayer then self.vocalsPlayer:setPitch(v) end
		if self.vocalsEnemy then self.vocalsEnemy:setPitch(v) end
	end
	self:registerInput(self.stRate)
	gTools:add(self.stRate)

	gTools:add(UIButton(16, 204, 190, 32, "Undo (Ctrl+Z)", function() self:undo() end))
	gTools:add(UIButton(218, 204, 190, 32, "Redo (Ctrl+Y)", function() self:redo() end))
	gTools:add(UIButton(420, 204, 195, 32, "Clear Entire Chart", function()
		self:pushUndo()
		self.song.notes.player = {}
		self.song.notes.enemy = {}
		self.selectedNote = nil
		Toast.info("Cleared all notes (Ctrl+Z to undo)")
	end))

	self.ddQuant = UIDropDown(16, 34, quantLabels, self.quantIdx, 220, 26)
	self.ddQuant.callback = function(_, idx)
		self.quantIdx = idx
		self.curQuant = ChartingState.QUANTS[idx] or 16
	end
	self.ddNoteType = UIDropDown(260, 34, ChartingState.NOTE_TYPES, 1, 165, 26)
	self.ddNoteType.callback = function(v)
		self.curNoteType = v
		self.inNoteType.text = v
	end
	gTools:add(self.ddQuant)
	gTools:add(self.ddNoteType)
	self.tabs:addGroup(gTools, 4)
end

function ChartingState:pushUndo()
	local snap = {
		player = table.clone(self.song.notes.player),
		enemy = table.clone(self.song.notes.enemy),
		events = table.clone(self.song.events)
	}
	table.insert(self.undoStack, snap)
	if #self.undoStack > 64 then table.remove(self.undoStack, 1) end
	self.redoStack = {}
end

function ChartingState:undo()
	local snap = table.remove(self.undoStack)
	if not snap then return end
	table.insert(self.redoStack, {
		player = table.clone(self.song.notes.player),
		enemy = table.clone(self.song.notes.enemy),
		events = table.clone(self.song.events)
	})
	self.song.notes.player = snap.player
	self.song.notes.enemy = snap.enemy
	self.song.events = snap.events
	self.selectedNote = nil
	self.selectedEvent = nil
	Toast.info("Undo")
end

function ChartingState:redo()
	local snap = table.remove(self.redoStack)
	if not snap then return end
	table.insert(self.undoStack, {
		player = table.clone(self.song.notes.player),
		enemy = table.clone(self.song.notes.enemy),
		events = table.clone(self.song.events)
	})
	self.song.notes.player = snap.player
	self.song.notes.enemy = snap.enemy
	self.song.events = snap.events
	self.selectedNote = nil
	self.selectedEvent = nil
	Toast.info("Redo")
end

function ChartingState:getCurrentSectionIndex()
	return math.max(1, math.floor(self.curStepFloat / 16) + 1)
end

function ChartingState:getCurrentSection(ensure)
	local idx = self:getCurrentSectionIndex()
	while ensure and #self.sections < idx do
		table.insert(self.sections, {
			mustHitSection = true,
			gfSection = false,
			changeBPM = false,
			bpm = tonumber(self.song.bpm) or 120
		})
	end
	return self.sections[idx]
end

function ChartingState:syncSectionInspector()
	local idx = self:getCurrentSectionIndex()
	local sec = self:getCurrentSection(true)
	if self.secTitle then self.secTitle.content = "Section #" .. tostring(idx - 1) end
	if self.cbMustHit then self.cbMustHit.checked = sec.mustHitSection ~= false end
	if self.cbGFSec then self.cbGFSec.checked = sec.gfSection == true end
	if self.cbSecBPM then self.cbSecBPM.checked = sec.changeBPM == true end
	if self.stSecBPM then
		self.stSecBPM.value = tonumber(sec.bpm) or tonumber(self.song.bpm) or 120
		self.stSecBPM.text = tostring(self.stSecBPM.value)
	end
end

function ChartingState:rebuildFocusEventsFromSections()
	local kept = {}
	for _, ev in ipairs(self.song.events or {}) do
		if ev.e ~= "FocusCamera" then table.insert(kept, ev) end
	end
	local lastFocus = nil
	for i, sec in ipairs(self.sections) do
		local focus = sec.gfSection and 2 or ((sec.mustHitSection ~= false) and 0 or 1)
		if focus ~= lastFocus then
			table.insert(kept, {
				t = self:stepToTime((i - 1) * 16),
				e = "FocusCamera",
				v = focus
			})
			lastFocus = focus
		end
	end
	table.sort(kept, Parser.sortByTime)
	self.song.events = kept
end

function ChartingState:getSectionTimeBounds(secIdx)
	local startMs = self:stepToTime((secIdx - 1) * 16)
	local endMs = self:stepToTime(secIdx * 16)
	return startMs, endMs
end

function ChartingState:copyCurrentSection()
	local sIdx = self:getCurrentSectionIndex()
	local startMs, endMs = self:getSectionTimeBounds(sIdx)
	local copied = {player = {}, enemy = {}}
	for _, n in ipairs(self.song.notes.player) do
		if n.t >= startMs - 0.5 and n.t < endMs - 0.5 then
			local c = table.clone(n)
			c.t = c.t - startMs
			table.insert(copied.player, c)
		end
	end
	for _, n in ipairs(self.song.notes.enemy) do
		if n.t >= startMs - 0.5 and n.t < endMs - 0.5 then
			local c = table.clone(n)
			c.t = c.t - startMs
			table.insert(copied.enemy, c)
		end
	end
	self.clipboardSection = copied
	Toast.info(string.format("Copied section #%d (%d notes)", sIdx - 1, #copied.player + #copied.enemy))
end

function ChartingState:pasteSection()
	if not self.clipboardSection then
		Toast.warn("Clipboard is empty — Copy a section first (Ctrl+C)")
		return
	end
	self:pushUndo()
	self:clearCurrentSection(true)
	local sIdx = self:getCurrentSectionIndex()
	local startMs = self:getSectionTimeBounds(sIdx)
	for _, n in ipairs(self.clipboardSection.player) do
		local c = table.clone(n)
		c.t = startMs + c.t
		table.insert(self.song.notes.player, c)
	end
	for _, n in ipairs(self.clipboardSection.enemy) do
		local c = table.clone(n)
		c.t = startMs + c.t
		table.insert(self.song.notes.enemy, c)
	end
	table.sort(self.song.notes.player, Parser.sortByTime)
	table.sort(self.song.notes.enemy, Parser.sortByTime)
	Toast.info("Pasted into section #" .. tostring(sIdx - 1))
end

function ChartingState:clearCurrentSection(noUndo)
	if not noUndo then self:pushUndo() end
	local sIdx = self:getCurrentSectionIndex()
	local startMs, endMs = self:getSectionTimeBounds(sIdx)
	local function filterOut(list)
		local out = {}
		for _, n in ipairs(list) do
			if n.t < startMs - 0.5 or n.t >= endMs - 0.5 then
				table.insert(out, n)
			end
		end
		return out
	end
	self.song.notes.player = filterOut(self.song.notes.player)
	self.song.notes.enemy = filterOut(self.song.notes.enemy)
	self.selectedNote = nil
end

function ChartingState:swapCurrentSectionSides()
	self:pushUndo()
	local sIdx = self:getCurrentSectionIndex()
	local startMs, endMs = self:getSectionTimeBounds(sIdx)
	local pKeep, eKeep, pMove, eMove = {}, {}, {}, {}
	for _, n in ipairs(self.song.notes.player) do
		if n.t >= startMs - 0.5 and n.t < endMs - 0.5 then table.insert(pMove, n) else table.insert(pKeep, n) end
	end
	for _, n in ipairs(self.song.notes.enemy) do
		if n.t >= startMs - 0.5 and n.t < endMs - 0.5 then table.insert(eMove, n) else table.insert(eKeep, n) end
	end
	for _, n in ipairs(eMove) do table.insert(pKeep, n) end
	for _, n in ipairs(pMove) do table.insert(eKeep, n) end
	table.sort(pKeep, Parser.sortByTime)
	table.sort(eKeep, Parser.sortByTime)
	self.song.notes.player = pKeep
	self.song.notes.enemy = eKeep
	Toast.info("Swapped BF <-> Dad notes in section #" .. tostring(sIdx - 1))
end

function ChartingState:mirrorCurrentSection()
	self:pushUndo()
	local sIdx = self:getCurrentSectionIndex()
	local startMs, endMs = self:getSectionTimeBounds(sIdx)
	local mirrorMap = {[0] = 3, [1] = 2, [2] = 1, [3] = 0}
	for _, track in ipairs({self.song.notes.player, self.song.notes.enemy}) do
		for _, n in ipairs(track) do
			if n.t >= startMs - 0.5 and n.t < endMs - 0.5 then
				n.d = mirrorMap[n.d % 4] or n.d
			end
		end
	end
	Toast.info("Mirrored lanes in section #" .. tostring(sIdx - 1))
end

function ChartingState:findNoteAt(side, dir, timeMs)
	local list = side == "player" and self.song.notes.player or self.song.notes.enemy
	local tol = math.max(8, (self.conductor.stepCrotchet or 125) * 0.22)
	for i, n in ipairs(list) do
		if (n.d % 4) == dir and math.abs((n.t or 0) - timeMs) <= tol then
			return n, i, list
		end
	end
	return nil, nil, list
end

function ChartingState:findEventAt(timeMs)
	local tol = math.max(8, (self.conductor.stepCrotchet or 125) * 0.25)
	for i, ev in ipairs(self.song.events) do
		if math.abs((ev.t or 0) - timeMs) <= tol then
			return ev, i
		end
	end
	return nil, nil
end

function ChartingState:applyNoteTypeFields(note)
	local nt = self.curNoteType or "Normal"
	note.gf = nil
	note.k = nil
	if nt == "GF Sing" then
		note.gf = true
	elseif nt == "Alt Anim" then
		note.k = "alt"
	elseif nt ~= "Normal" and nt ~= "" then
		note.k = nt
	end
end

function ChartingState:placeOrUpdateEventAt(timeMs)
	self:pushUndo()
	local name = (self.inEventName and self.inEventName.text ~= "") and self.inEventName.text or "Add Camera Zoom"
	local v1 = self.inEventV1 and self.inEventV1.text or ""
	local v2 = self.inEventV2 and self.inEventV2.text or ""
	local existing = self:findEventAt(timeMs)
	if existing and existing.e == name then
		existing.v = {v1, v2}
		self.selectedEvent = existing
	else
		local newEv = {t = timeMs, e = name, v = {v1, v2}}
		table.insert(self.song.events, newEv)
		table.sort(self.song.events, Parser.sortByTime)
		self.selectedEvent = newEv
	end
	Toast.info("Event '" .. name .. "' @ " .. string.format("%.2fs", timeMs / 1000))
end

function ChartingState:deleteEventAtPlayhead()
	local target = self.selectedEvent or self:findEventAt(self:stepToTime(self:quantizeStep(self.curStepFloat)))
	if not target then return end
	self:pushUndo()
	for i = #self.song.events, 1, -1 do
		if self.song.events[i] == target then
			table.remove(self.song.events, i)
			break
		end
	end
	self.selectedEvent = nil
	Toast.info("Deleted event")
end

function ChartingState:handleTimelineMouse(dt)
	local gs = ChartingState.GRID_SIZE
	local mx, my = Mouse.x, Mouse.y
	if mx >= self.gridX and mx < self.gridX + self.timeline.width and my >= 28 and my < game.height then
		local col = math.floor((mx - self.gridX) / gs)
		local rawStep = self.curStepFloat + (my - self.playheadY) / gs
		self.hoverCol = col
		self.hoverStep = self:quantizeStep(rawStep)
	else
		self.hoverCol = nil
		self.hoverStep = nil
	end

	-- Sustain dragging
	if self.dragNote then
		if Mouse.releasedLeft or not Mouse.pressedLeft then
			self.dragNote = nil
		elseif self.hoverStep then
			local startStep = self:timeToStep(self.dragNote.t)
			local deltaSteps = math.max(0, self.hoverStep - startStep)
			self.dragNote.l = self:stepToTime(deltaSteps)
		end
		return
	end

	if not Mouse.justPressedLeft or not self.hoverCol or not self.hoverStep then return end
	if self:isMouseOverUI() then return end

	local targetMs = self:stepToTime(self.hoverStep)
	if self.hoverCol == 0 then
		local ev = self:findEventAt(targetMs)
		if ev then
			self.selectedEvent = ev
			if self.inEventName then self.inEventName.text = tostring(ev.e or "") end
			if type(ev.v) == "table" then
				if self.inEventV1 then self.inEventV1.text = tostring(ev.v[1] or "") end
				if self.inEventV2 then self.inEventV2.text = tostring(ev.v[2] or "") end
			else
				if self.inEventV1 then self.inEventV1.text = tostring(ev.v or "") end
				if self.inEventV2 then self.inEventV2.text = "" end
			end
			self.tabs:selectTab(3)
		else
			self:placeOrUpdateEventAt(targetMs)
		end
		return
	end

	local side = self.hoverCol >= 5 and "player" or "enemy"
	local dir = (self.hoverCol - 1) % 4
	local existing, idx, list = self:findNoteAt(side, dir, targetMs)

	if existing then
		if game.keys.pressed.SHIFT then
			self.selectedNote = existing
		else
			self:pushUndo()
			table.remove(list, idx)
			if self.selectedNote == existing then self.selectedNote = nil end
		end
	else
		self:pushUndo()
		local newNote = {t = targetMs, d = dir, l = 0, _side = side}
		self:applyNoteTypeFields(newNote)
		table.insert(list, newNote)
		table.sort(list, Parser.sortByTime)
		self.selectedNote = newNote
		self.dragNote = newNote
	end
end

function ChartingState:adjustSelectedSustain(deltaSteps)
	local n = self.selectedNote
	if not n then return end
	self:pushUndo()
	local stepSnap = 16 / (self.curQuant or 16)
	local deltaMs = self:stepToTime(deltaSteps * stepSnap)
	n.l = math.max(0, (tonumber(n.l) or 0) + deltaMs)
end

function ChartingState:setPlaybackPlaying(play)
	self.playing = play
	if play then
		local sec = math.max(0, self.curTimeMs / 1000)
		if self.inst then
			self.inst:seek(math.min(sec, math.max(0, (self.inst.duration or sec) - 0.01)))
			self.inst:setPitch(self.playbackRate)
			self.inst:play()
		end
		if self.vocalsPlayer then
			self.vocalsPlayer:seek(math.min(sec, math.max(0, (self.vocalsPlayer.duration or sec) - 0.01)))
			self.vocalsPlayer:setPitch(self.playbackRate)
			self.vocalsPlayer:play()
		end
		if self.vocalsEnemy then
			self.vocalsEnemy:seek(math.min(sec, math.max(0, (self.vocalsEnemy.duration or sec) - 0.01)))
			self.vocalsEnemy:setPitch(self.playbackRate)
			self.vocalsEnemy:play()
		end
		self._lastAudioMs = self.curTimeMs
	else
		if self.inst then self.inst:pause() end
		if self.vocalsPlayer then self.vocalsPlayer:pause() end
		if self.vocalsEnemy then self.vocalsEnemy:pause() end
	end
end

function ChartingState:seekMs(ms)
	local prevSecIdx = self:getCurrentSectionIndex()
	local maxMs = self:stepToTime(self:getTotalSteps() + 16)
	self.curTimeMs = math.clamp(ms, 0, math.max(1000, maxMs))
	self.conductor:update(self.curTimeMs)
	self.curStepFloat = self:timeToStep(self.curTimeMs)
	if self:getCurrentSectionIndex() ~= prevSecIdx then
		self:syncSectionInspector()
	end
end

function ChartingState:checkPlaybackHitsounds(prevMs, nowMs)
	if nowMs <= prevMs then return end
	if self.metronome then
		local curBeat = math.floor(self.curStepFloat / 4)
		if curBeat ~= self._lastBeatHit then
			self._lastBeatHit = curBeat
			if self.hitSoundAsset then game.sound.play(self.hitSoundAsset, curBeat % 4 == 0 and 0.65 or 0.35) end
		end
	end
	local function scan(list, enabled)
		if not enabled or not self.hitSoundAsset then return end
		for _, n in ipairs(list) do
			if n.t > prevMs and n.t <= nowMs then
				game.sound.play(self.hitSoundAsset, 0.7)
				break
			end
		end
	end
	scan(self.song.notes.player, self.hitSoundsPlayer)
	scan(self.song.notes.enemy, self.hitSoundsEnemy)
end

function ChartingState:getSaveBasePrefix()
	if Mods.currentMod and Mods.currentMod ~= "" then
		return (Mods.root or "mods") .. "/" .. Mods.currentMod .. "/"
	end
	return "assets/"
end

function ChartingState:saveChart(useNativeDialog)
	self:rebuildFocusEventsFromSections()
	local exportTbl = ChartingState.buildExportData(self.song, self.sections)
	local encoded = JSON.encode(exportTbl, true)

	local songSlug = paths.formatToSongPath(self.song.song or "bopeebo")
	local diffSlug = (self.curDifficulty ~= "" and self.curDifficulty or "normal"):lower()
	local virtualPath = self:getSaveBasePrefix() .. "songs/" .. songSlug .. "/charts/" .. diffSlug .. ".json"

	if useNativeDialog and WindowDialogue and WindowDialogue.askSaveAsFile then
		local dst = WindowDialogue.askSaveAsFile(nil, {{"JSON Files", "*.json"}}, diffSlug .. ".json")
		if dst then
			local f = io.open(dst, "wb")
			if f then
				f:write(encoded)
				f:close()
				Parser.clearCache()
				Toast.info("Saved chart to " .. dst)
				return true, dst
			end
		end
	end

	local ok, targetOrErr = Storage.writeFile(virtualPath, encoded)
	Parser.clearCache()
	if ok then
		util.playSfx(paths.getSound("confirmMenu"))
		Toast.info("Saved chart: " .. tostring(targetOrErr))
		return true, targetOrErr
	else
		Toast.error("Save failed: " .. tostring(targetOrErr))
		return false, targetOrErr
	end
end

function ChartingState:saveSongMeta()
	local songSlug = paths.formatToSongPath(self.song.song or "bopeebo")
	local metaTbl = {
		songName = self.song.song or songSlug,
		difficulties = self.song.difficulties or {"easy", "normal", "hard"},
		stage = self.song.stage or "stage",
		skin = self.song.skin or "default",
		characters = {
			player = self.song.player1 or "bf",
			opponent = self.song.player2 or "dad",
			girlfriend = self.song.gfVersion or "gf"
		}
	}
	local virtualPath = self:getSaveBasePrefix() .. "songs/" .. songSlug .. "/meta.json"
	local ok, targetOrErr = Storage.writeFile(virtualPath, JSON.encode(metaTbl, true))
	Parser.clearCache()
	if ok then
		Toast.info("Saved meta: " .. tostring(targetOrErr))
	else
		Toast.error("Meta save failed: " .. tostring(targetOrErr))
	end
end

function ChartingState:reloadTargetSong(songName, diff)
	self:setPlaybackPlaying(false)
	Parser.clearCache()
	local ok = pcall(PlayState.loadSong, paths.formatToSongPath(songName or "bopeebo"), diff or "normal")
	if ok and PlayState.SONG then
		game.switchState(ChartingState())
	else
		Toast.error("Could not load song '" .. tostring(songName) .. "' [" .. tostring(diff) .. "]")
	end
end

function ChartingState:playtestSong(fromCurrentPos)
	self:setPlaybackPlaying(false)
	self:rebuildFocusEventsFromSections()
	PlayState.SONG = self.song
	PlayState.songDifficulty = self.curDifficulty
	PlayState.chartingMode = true
	local startMs = fromCurrentPos and math.max(0, self.curTimeMs) or 0
	game.switchState(PlayState(false, startMs))
end

function ChartingState:update(dt)
	ChartingState.super.update(self, dt)

	if self.playing then
		local prevMs = self.curTimeMs
		if self.inst and self.inst:isPlaying() then
			self:seekMs(self.inst:tell() * 1000)
		else
			self:seekMs(self.curTimeMs + dt * 1000 * self.playbackRate)
		end
		self:checkPlaybackHitsounds(prevMs, self.curTimeMs)
	end

	self:handleTimelineMouse(dt)

	if not self:isTyping() then
		local ctrl = game.keys.pressed.CONTROL
		local shift = game.keys.pressed.SHIFT

		if ctrl and game.keys.justPressed.S then
			self:saveChart(shift)
		elseif ctrl and game.keys.justPressed.Z then
			self:undo()
		elseif ctrl and game.keys.justPressed.Y then
			self:redo()
		elseif ctrl and game.keys.justPressed.C then
			self:copyCurrentSection()
		elseif ctrl and game.keys.justPressed.V then
			self:pasteSection()
		elseif game.keys.justPressed.SPACE then
			self:setPlaybackPlaying(not self.playing)
		elseif game.keys.justPressed.RETURN then
			self:playtestSong(shift or ctrl)
			return
		elseif game.keys.justPressed.ESCAPE or controls:pressed("back") then
			self:setPlaybackPlaying(false)
			PlayState.chartingMode = false
			util.playMenuMusic()
			game.switchState(FreeplayState())
			return
		elseif game.keys.justPressed.E then
			self:adjustSelectedSustain(1)
		elseif game.keys.justPressed.Q then
			self:adjustSelectedSustain(-1)
		elseif game.keys.justPressed.LEFT then
			self.quantIdx = (self.quantIdx - 2) % #ChartingState.QUANTS + 1
			self.curQuant = ChartingState.QUANTS[self.quantIdx]
			if self.ddQuant then self.ddQuant:setSelected(self.quantIdx) end
		elseif game.keys.justPressed.RIGHT then
			self.quantIdx = self.quantIdx % #ChartingState.QUANTS + 1
			self.curQuant = ChartingState.QUANTS[self.quantIdx]
			if self.ddQuant then self.ddQuant:setSelected(self.quantIdx) end
		elseif game.keys.justPressed.A then
			if self.playing then self:setPlaybackPlaying(false) end
			local targetSec = math.max(0, self:getCurrentSectionIndex() - 2)
			self:seekMs(self:stepToTime(targetSec * 16))
		elseif game.keys.justPressed.D then
			if self.playing then self:setPlaybackPlaying(false) end
			local targetSec = self:getCurrentSectionIndex()
			self:seekMs(self:stepToTime(targetSec * 16))
		elseif game.keys.justPressed.HOME then
			if self.playing then self:setPlaybackPlaying(false) end
			self:seekMs(0)
		elseif game.keys.justPressed.END then
			if self.playing then self:setPlaybackPlaying(false) end
			self:seekMs(self:stepToTime(self:getTotalSteps()))
		end

		local scrubSpeed = (shift and 4 or 1) * (self.conductor.stepCrotchet or 125) * 8
		if game.keys.pressed.W or game.keys.pressed.UP then
			if self.playing then self:setPlaybackPlaying(false) end
			self:seekMs(self.curTimeMs - scrubSpeed * dt)
		elseif game.keys.pressed.S or game.keys.pressed.DOWN then
			if self.playing then self:setPlaybackPlaying(false) end
			self:seekMs(self.curTimeMs + scrubSpeed * dt)
		end

		if Mouse.wheel ~= 0 and not self:isMouseOverUI() then
			if self.playing then self:setPlaybackPlaying(false) end
			local stepJump = (16 / self.curQuant) * (shift and 4 or 1)
			self:seekMs(self.curTimeMs - Mouse.wheel * self:stepToTime(stepJump))
		end
	end

	-- Update HUD readout
	if self.infoText then
		local durSec = (self.inst and self.inst.duration) or (self:stepToTime(self:getTotalSteps()) / 1000)
		local pCount = #(self.song.notes.player or {})
		local eCount = #(self.song.notes.enemy or {})
		local evCount = #(self.song.events or {})
		self.infoText.content = string.format(
			"SONG: %s\nDIFF: %s\nTIME: %s / %s\nBPM : %.1f\nSTEP: %.1f\nBEAT: %d\nSEC : %d\nSNAP: 1/%d\nTYPE: %s\n\nBF NOTES : %d\nDAD NOTES: %d\nEVENTS   : %d\nMOD: %s",
			tostring(self.song.song or "?"),
			self.curDifficulty:upper(),
			util.formatTime(self.curTimeMs / 1000),
			util.formatTime(durSec),
			tonumber(self.song.bpm) or 120,
			self.curStepFloat,
			math.floor(self.curStepFloat / 4),
			self:getCurrentSectionIndex() - 1,
			self.curQuant,
			self.curNoteType,
			pCount,
			eCount,
			evCount,
			tostring(Mods.currentMod or "(base)")
		)
	end
end

function ChartingState:leave()
	self:setPlaybackPlaying(false)
	if self.vocalsPlayer then self.vocalsPlayer:destroy(); self.vocalsPlayer = nil end
	if self.vocalsEnemy then self.vocalsEnemy:destroy(); self.vocalsEnemy = nil end
	if self.conductor then self.conductor:destroy(); self.conductor = nil end
end

return ChartingState

local JSON = require("funkin.backend.jsonbuilder")

local CutsceneState = State:extend("CutsceneState")

CutsceneState.CUTSCENE_EVENT_TYPES = {
	"Camera Position",
	"Camera Zoom",
	"Play Sound"
}

function CutsceneState:enter()
	CutsceneState.super.enter(self)

	if love.mouse and love.mouse.setVisible then love.mouse.setVisible(true) end
	if Mouse and Mouse.SetCursor then Mouse.SetCursor("arrow") end

	self.camHUD = Camera()
	game.cameras.add(self.camHUD, false)

	self.textInputs = {}
	self.cutsceneEvents = {}
	self.selectedCutEventIdx = 0
	self.cutsceneName = "intro"

	-- Ensure PlayState.SONG exists so Stage:load() has character names
	self._prevSong = PlayState.SONG
	if not PlayState.SONG then
		PlayState.SONG = Parser.getDummyChart("bopeebo", true)
	end

	self.curStageName = PlayState.SONG.stage or "stage"
	self.smallFont = paths.getFont("vcr.ttf", 14) or love.graphics.getFont()
	self.uiFont = paths.getFont("vcr.ttf", 15) or love.graphics.getFont()

	self.stageContainer = Group()
	self:add(self.stageContainer)

	self.camFollow = Point(game.width * 0.5, game.height * 0.5)
	game.camera:follow(self.camFollow, nil, 10)

	self:loadStagePreview(self.curStageName)

	-- Top Navbar & Right Inspector
	self.panelX = math.floor(game.width * 0.68)
	self.panelW = game.width - self.panelX - 12

	self.navbar = UINavbar({
		{"Save Stage (Ctrl+S)", function() self:saveStageJSON() end},
		{"Save Cutscene", function() self:saveCutsceneJSON() end},
		{"Play Cutscene (P)", function() self:previewCutscene() end},
		{"Focus BF (1)", function() self:focusCharacter("bf") end},
		{"Focus Dad (2)", function() self:focusCharacter("dad") end},
		{"Focus GF (3)", function() self:focusCharacter("gf") end},
		{"Exit (ESC)", function() self:exitEditor() end}
	})
	self.navbar.cameras = {self.camHUD}
	self:add(self.navbar)

	self.infoBg = Graphic(12, 42, 290, 146, Color.fromRGB(16, 18, 28))
	self.infoBg.alpha = 0.88
	self.infoBg.cameras = {self.camHUD}
	self:add(self.infoBg)

	self.infoTxt = Text(22, 50, "", self.smallFont, Color.WHITE, "left", 270)
	self.infoTxt.cameras = {self.camHUD}
	self:add(self.infoTxt)

	self.tabs = UITabMenu(self.panelX, 40, {"Stage", "Cutscene"}, self.panelW, game.height - 52)
	self.tabs.cameras = {self.camHUD}
	self:add(self.tabs)

	self:buildStageTab()
	self:buildCutsceneTab()
	self:syncStageFields()
end

function CutsceneState:registerInput(inp)
	table.insert(self.textInputs, inp)
	return inp
end

function CutsceneState:isTyping()
	for _, inp in ipairs(self.textInputs) do
		if inp.focused then return true end
	end
	return false
end

function CutsceneState:collectStages()
	local out, seen = {}, {}
	for _, item in ipairs(paths.getItems("data/stages", "file") or {}) do
		local id = item:gsub("%.%w+$", "")
		if id ~= "" and not seen[id] then
			seen[id] = true
			table.insert(out, id)
		end
	end
	if #out == 0 then out = {"stage"} end
	table.sort(out)
	return out
end

function CutsceneState:loadStagePreview(stageName)
	self.stageContainer:clear()
	self.curStageName = stageName or "stage"
	PlayState.SONG.stage = self.curStageName

	self.stage = Stage(self.curStageName)
	self.stage:load()
	self.stageContainer:add(self.stage)
	if self.stage.foreground then
		self.stageContainer:add(self.stage.foreground)
	end

	self.boyfriend = self.stage.boyfriend
	self.dad = self.stage.dad
	self.gf = self.stage.gf
	self.curZoom = tonumber(self.stage.camZoom) or 0.9
	game.camera.zoom = self.curZoom
	self:focusCharacter("dad")
end

function CutsceneState:focusCharacter(which)
	if not self.stage then return end
	local ch = (which == "bf" and self.boyfriend) or (which == "gf" and self.gf) or self.dad
	if not ch then return end
	local mx, my = ch:getMidpoint()
	local camOff = (which == "bf" and self.stage.boyfriendCam) or (which == "gf" and self.stage.gfCam) or self.stage.dadCam
	local sign = (which == "bf") and -1 or 1
	mx = mx + (which == "bf" and -100 or (which == "dad" and 150 or 0)) + sign * (ch.cameraPosition and ch.cameraPosition.x or 0) + (camOff and camOff.x or 0)
	my = my - 100 + (ch.cameraPosition and ch.cameraPosition.y or 0) + (camOff and camOff.y or 0)
	self.camFollow:set(mx, my)
end

function CutsceneState:applyPositionsToActors()
	if not self.stage then return end
	if self.boyfriend then
		self.boyfriend:setPosition(self.stage.boyfriendPos.x, self.stage.boyfriendPos.y)
	end
	if self.dad then
		self.dad:setPosition(self.stage.dadPos.x, self.stage.dadPos.y)
	end
	if self.gf then
		self.gf:setPosition(self.stage.gfPos.x, self.stage.gfPos.y)
	end
end

function CutsceneState:buildStageTab()
	local g = Group()
	local function lbl(x, y, text)
		local t = Text(x, y, text, self.smallFont, Color.fromRGB(210, 215, 235))
		g:add(t)
		return t
	end

	local stageList = self:collectStages()

	lbl(14, 10, "Load Stage:")
	lbl(212, 10, "Save Stage ID:")
	self.inStageId = self:registerInput(UIInputTextBox(212, 28, 175, 26, self.uiFont))
	self.inStageId.text = self.curStageName
	g:add(self.inStageId)

	lbl(14, 66, "Default Camera Zoom:")
	self.stZoom = UINumericStepper(14, 84, 0.05, self.curZoom, 0.2, 3.0, 140, 26)
	self.stZoom.onChanged = function(v)
		self.curZoom = v
		self.stage.camZoom = v
	end
	self:registerInput(self.stZoom)
	g:add(self.stZoom)

	lbl(14, 124, "Boyfriend Pos X / Y:")
	self.stBFX = UINumericStepper(14, 142, 10, self.stage.boyfriendPos.x, -9000, 9000, 140, 26)
	self.stBFX.onChanged = function(v) self.stage.boyfriendPos.x = v; self:applyPositionsToActors() end
	self:registerInput(self.stBFX)
	g:add(self.stBFX)

	self.stBFY = UINumericStepper(168, 142, 10, self.stage.boyfriendPos.y, -9000, 9000, 140, 26)
	self.stBFY.onChanged = function(v) self.stage.boyfriendPos.y = v; self:applyPositionsToActors() end
	self:registerInput(self.stBFY)
	g:add(self.stBFY)

	lbl(14, 182, "Opponent (Dad) Pos X / Y:")
	self.stDadX = UINumericStepper(14, 200, 10, self.stage.dadPos.x, -9000, 9000, 140, 26)
	self.stDadX.onChanged = function(v) self.stage.dadPos.x = v; self:applyPositionsToActors() end
	self:registerInput(self.stDadX)
	g:add(self.stDadX)

	self.stDadY = UINumericStepper(168, 200, 10, self.stage.dadPos.y, -9000, 9000, 140, 26)
	self.stDadY.onChanged = function(v) self.stage.dadPos.y = v; self:applyPositionsToActors() end
	self:registerInput(self.stDadY)
	g:add(self.stDadY)

	lbl(14, 240, "Girlfriend (GF) Pos X / Y:")
	self.stGFX = UINumericStepper(14, 258, 10, self.stage.gfPos.x, -9000, 9000, 140, 26)
	self.stGFX.onChanged = function(v) self.stage.gfPos.x = v; self:applyPositionsToActors() end
	self:registerInput(self.stGFX)
	g:add(self.stGFX)

	self.stGFY = UINumericStepper(168, 258, 10, self.stage.gfPos.y, -9000, 9000, 140, 26)
	self.stGFY.onChanged = function(v) self.stage.gfPos.y = v; self:applyPositionsToActors() end
	self:registerInput(self.stGFY)
	g:add(self.stGFY)

	g:add(UIButton(14, 310, 372, 34, "Save Stage JSON (Ctrl+S)", function() self:saveStageJSON() end))

	self.ddStage = UIDropDown(14, 28, stageList, math.max(1, table.find(stageList, self.curStageName) or 1), 186, 26)
	self.ddStage.callback = function(v)
		self:loadStagePreview(v)
		self:syncStageFields()
	end
	g:add(self.ddStage)
	self.tabs:addGroup(g, 1)
end

function CutsceneState:buildCutsceneTab()
	local g = Group()
	local function lbl(x, y, text)
		local t = Text(x, y, text, self.smallFont, Color.fromRGB(210, 215, 235))
		g:add(t)
		return t
	end

	lbl(14, 10, "Cutscene File Name (data/cutscenes/<name>.json):")
	self.inCutName = self:registerInput(UIInputTextBox(14, 28, 240, 26, self.uiFont))
	self.inCutName.text = self.cutsceneName
	g:add(self.inCutName)

	g:add(UIButton(264, 28, 120, 26, "Load JSON", function() self:loadCutsceneJSON() end))

	lbl(14, 66, "Event Action:")
	lbl(224, 66, "Time (ms):")
	self.stCutTime = UINumericStepper(224, 84, 100, 0, 0, 600000, 160, 26)
	self:registerInput(self.stCutTime)
	g:add(self.stCutTime)

	lbl(14, 122, "Param 1 (Cam X / Zoom / Sound Path):")
	self.inCutP1 = self:registerInput(UIInputTextBox(14, 140, 180, 26, self.uiFont))
	self.inCutP1.text = "640"
	g:add(self.inCutP1)

	lbl(206, 122, "Param 2 (Cam Y / TweenSec / Vol):")
	self.inCutP2 = self:registerInput(UIInputTextBox(206, 140, 180, 26, self.uiFont))
	self.inCutP2.text = "360"
	g:add(self.inCutP2)

	lbl(14, 178, "Tween Duration (s, 0 = instant):")
	self.stCutDur = UINumericStepper(14, 196, 0.1, 0.8, 0, 30, 150, 26)
	self:registerInput(self.stCutDur)
	g:add(self.stCutDur)

	lbl(180, 178, "Ease:")
	self.inCutEase = self:registerInput(UIInputTextBox(180, 196, 206, 26, self.uiFont))
	self.inCutEase.text = "quadOut"
	g:add(self.inCutEase)

	g:add(UIButton(14, 236, 184, 30, "Capture Cam Here", function()
		self.inCutP1.text = tostring(math.floor(self.camFollow.x))
		self.inCutP2.text = tostring(math.floor(self.camFollow.y))
		Toast.info("Captured current camera X/Y")
	end))
	g:add(UIButton(204, 236, 182, 30, "Add Keyframe", function() self:addCutsceneEvent() end))

	g:add(UIButton(14, 274, 184, 30, "Clear Keyframes", function()
		self.cutsceneEvents = {}
		self:refreshCutsceneSummary()
	end))
	g:add(UIButton(204, 274, 182, 30, "Preview (P)", function() self:previewCutscene() end))
	g:add(UIButton(14, 312, 372, 32, "Save Cutscene JSON", function() self:saveCutsceneJSON() end))

	self.cutListTxt = Text(14, 354, "Keyframes: (0)", self.smallFont, Color.fromRGB(190, 210, 240), "left", 372)
	g:add(self.cutListTxt)

	self.ddCutType = UIDropDown(14, 84, CutsceneState.CUTSCENE_EVENT_TYPES, 1, 198, 26)
	g:add(self.ddCutType)
	self.tabs:addGroup(g, 2)
end

function CutsceneState:syncStageFields()
	if not self.stage then return end
	if self.inStageId then self.inStageId.text = tostring(self.curStageName) end
	if self.stZoom then self.stZoom.value = self.curZoom; self.stZoom.text = tostring(self.curZoom) end
	if self.stBFX then self.stBFX.value = self.stage.boyfriendPos.x; self.stBFX.text = tostring(self.stBFX.value) end
	if self.stBFY then self.stBFY.value = self.stage.boyfriendPos.y; self.stBFY.text = tostring(self.stBFY.value) end
	if self.stDadX then self.stDadX.value = self.stage.dadPos.x; self.stDadX.text = tostring(self.stDadX.value) end
	if self.stDadY then self.stDadY.value = self.stage.dadPos.y; self.stDadY.text = tostring(self.stDadY.value) end
	if self.stGFX then self.stGFX.value = self.stage.gfPos.x; self.stGFX.text = tostring(self.stGFX.value) end
	if self.stGFY then self.stGFY.value = self.stage.gfPos.y; self.stGFY.text = tostring(self.stGFY.value) end
end

function CutsceneState:addCutsceneEvent()
	local kind = self.ddCutType and self.ddCutType.items[self.ddCutType.curSelected] or "Camera Position"
	local tMs = self.stCutTime and tonumber(self.stCutTime.value) or 0
	local dur = self.stCutDur and tonumber(self.stCutDur.value) or 0
	local ease = (self.inCutEase and self.inCutEase.text ~= "") and self.inCutEase.text or "quadOut"
	local p1 = self.inCutP1 and self.inCutP1.text or ""
	local p2 = self.inCutP2 and self.inCutP2.text or ""

	local params
	if kind == "Camera Position" then
		params = {tonumber(p1) or 0, tonumber(p2) or 0, dur > 0, dur, ease}
	elseif kind == "Camera Zoom" then
		params = {tonumber(p1) or 1, dur > 0, dur, ease}
	else
		params = {p1 ~= "" and p1 or "confirmMenu", tonumber(p2) or 1, false, 0, 1, 1}
	end

	table.insert(self.cutsceneEvents, {
		time = tMs,
		event = {name = kind, params = params}
	})
	table.sort(self.cutsceneEvents, function(a, b) return a.time < b.time end)
	self:refreshCutsceneSummary()
end

function CutsceneState:refreshCutsceneSummary()
	if not self.cutListTxt then return end
	local lines = {"Keyframes (" .. tostring(#self.cutsceneEvents) .. "):"}
	for i = 1, math.min(8, #self.cutsceneEvents) do
		local ce = self.cutsceneEvents[i]
		table.insert(lines, string.format("%d) %dms — %s", i, ce.time, ce.event.name))
	end
	if #self.cutsceneEvents > 8 then
		table.insert(lines, "... +" .. tostring(#self.cutsceneEvents - 8) .. " more")
	end
	self.cutListTxt.content = table.concat(lines, "\n")
end

function CutsceneState:previewCutscene()
	if #self.cutsceneEvents == 0 then
		Toast.warn("Add at least 1 keyframe in the Cutscene tab first")
		return
	end
	for _, ce in ipairs(self.cutsceneEvents) do
		Timer.wait(math.max(0, (ce.time or 0) / 1000), function()
			local ev = ce.event
			if ev.name == "Camera Position" then
				local xCam, yCam, isTw, dur, ease = ev.params[1], ev.params[2], ev.params[3], ev.params[4], ev.params[5]
				if isTw and dur > 0 then
					Tween.tween(self.camFollow, {x = xCam, y = yCam}, dur, {ease = Ease[ease] or Ease.quadOut})
				else
					self.camFollow:set(xCam, yCam)
				end
			elseif ev.name == "Camera Zoom" then
				local z, isTw, dur, ease = ev.params[1], ev.params[2], ev.params[3], ev.params[4]
				if isTw and dur > 0 then
					Tween.tween(self, {curZoom = z}, dur, {ease = Ease[ease] or Ease.quadOut})
				else
					self.curZoom = z
				end
			elseif ev.name == "Play Sound" then
				local snd = paths.getSound(tostring(ev.params[1] or "confirmMenu"))
				if snd then util.playSfx(snd, tonumber(ev.params[2]) or 1) end
			end
		end)
	end
	Toast.info("Playing cutscene preview...")
end

function CutsceneState:getModPrefix()
	if Mods.currentMod and Mods.currentMod ~= "" then
		return (Mods.root or "mods") .. "/" .. Mods.currentMod .. "/"
	end
	return "assets/"
end

function CutsceneState:saveStageJSON()
	local stageId = (self.inStageId and self.inStageId.text ~= "") and self.inStageId.text or self.curStageName
	local existingProps = (self.stage and self.stage.data and self.stage.data.props) or {}
	local out = {
		name = stageId,
		cameraZoom = tonumber(self.curZoom) or 0.9,
		props = existingProps,
		characters = {
			bf = {
				position = {self.stage.boyfriendPos.x, self.stage.boyfriendPos.y},
				cameraOffsets = {self.stage.boyfriendCam.x, self.stage.boyfriendCam.y}
			},
			dad = {
				position = {self.stage.dadPos.x, self.stage.dadPos.y},
				cameraOffsets = {self.stage.dadCam.x, self.stage.dadCam.y}
			},
			gf = {
				position = {self.stage.gfPos.x, self.stage.gfPos.y},
				cameraOffsets = {self.stage.gfCam.x, self.stage.gfCam.y}
			}
		}
	}
	local vpath = self:getModPrefix() .. "data/stages/" .. stageId .. ".json"
	local ok, dst = Storage.writeFile(vpath, JSON.encode(out, true))
	Parser.clearCache()
	if ok then Toast.info("Saved stage: " .. tostring(dst)) else Toast.error(tostring(dst)) end
end

function CutsceneState:saveCutsceneJSON()
	local name = (self.inCutName and self.inCutName.text ~= "") and self.inCutName.text or "intro"
	local vpath = self:getModPrefix() .. "data/cutscenes/" .. name .. ".json"
	local ok, dst = Storage.writeFile(vpath, JSON.encode({cutscene = self.cutsceneEvents}, true))
	if ok then Toast.info("Saved cutscene: " .. tostring(dst)) else Toast.error(tostring(dst)) end
end

function CutsceneState:loadCutsceneJSON()
	local name = (self.inCutName and self.inCutName.text ~= "") and self.inCutName.text or "intro"
	local data = paths.getJSON("data/cutscenes/" .. name)
	if data and type(data.cutscene) == "table" then
		self.cutsceneEvents = table.clone(data.cutscene)
		self:refreshCutsceneSummary()
		Toast.info("Loaded cutscene '" .. name .. "'")
	else
		Toast.warn("No cutscene JSON found at data/cutscenes/" .. name .. ".json")
	end
end

function CutsceneState:exitEditor()
	PlayState.SONG = self._prevSong
	util.playMenuMusic()
	game.switchState(MainMenuState())
end

function CutsceneState:update(dt)
	CutsceneState.super.update(self, dt)

	local mouseInStage = Mouse.x < self.panelX and Mouse.y > 30

	if not self:isTyping() then
		local shift = game.keys.pressed.SHIFT
		local ctrl = game.keys.pressed.CONTROL
		local speed = (shift and 650 or 260) * dt

		if ctrl and game.keys.justPressed.S then
			self:saveStageJSON()
		elseif game.keys.justPressed.P then
			self:previewCutscene()
		elseif game.keys.justPressed.ONE then
			self:focusCharacter("bf")
		elseif game.keys.justPressed.TWO then
			self:focusCharacter("dad")
		elseif game.keys.justPressed.THREE then
			self:focusCharacter("gf")
		elseif game.keys.justPressed.ESCAPE then
			self:exitEditor()
			return
		end

		if game.keys.pressed.A then self.camFollow.x = self.camFollow.x - speed end
		if game.keys.pressed.D then self.camFollow.x = self.camFollow.x + speed end
		if game.keys.pressed.W then self.camFollow.y = self.camFollow.y - speed end
		if game.keys.pressed.S and not ctrl then self.camFollow.y = self.camFollow.y + speed end

		if mouseInStage and Mouse.pressedLeft then
			self.camFollow.x = self.camFollow.x - (Mouse.deltaScreenX / math.max(0.1, self.curZoom))
			self.camFollow.y = self.camFollow.y - (Mouse.deltaScreenY / math.max(0.1, self.curZoom))
		end

		if mouseInStage and Mouse.wheel ~= 0 then
			self.curZoom = math.clamp(self.curZoom + Mouse.wheel * 0.06, 0.2, 3.0)
			if self.stZoom then self.stZoom.value = self.curZoom; self.stZoom.text = tostring(self.curZoom) end
		end
	end

	game.camera.zoom = util.coolLerp(game.camera.zoom, self.curZoom, 10, dt)

	if self.infoTxt and self.stage then
		self.infoTxt.content = string.format(
			"STAGE: %s\nCam X/Y : [%d, %d]\nZoom    : %.2fx\nBF Pos  : [%d, %d]\nDad Pos : [%d, %d]\nGF Pos  : [%d, %d]\nWASD/Drag: Pan | 1/2/3: Focus",
			tostring(self.curStageName),
			math.floor(self.camFollow.x), math.floor(self.camFollow.y),
			self.curZoom,
			self.stage.boyfriendPos.x, self.stage.boyfriendPos.y,
			self.stage.dadPos.x, self.stage.dadPos.y,
			self.stage.gfPos.x, self.stage.gfPos.y
		)
	end
end

function CutsceneState:leave()
	PlayState.SONG = self._prevSong
end

return CutsceneState

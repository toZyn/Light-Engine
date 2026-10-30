local JSON = require("funkin.backend.jsonbuilder")

local CharacterEditor = State:extend("CharacterEditor")

CharacterEditor.onPlayState = false

function CharacterEditor:enter()
	CharacterEditor.super.enter(self)

	if love.mouse and love.mouse.setVisible then love.mouse.setVisible(true) end
	if Mouse and Mouse.SetCursor then Mouse.SetCursor("arrow") end
	Character.editorMode = true

	self.curChar = "bf"
	self.curSelected = 1
	self.curAnim = nil
	self.isPlayer = true
	self.showGhost = true
	self.ghostAnimName = "idle"
	self.textInputs = {}

	if CharacterEditor.onPlayState and PlayState.SONG then
		self.curChar = PlayState.SONG.player2 or "dad"
		self.isPlayer = self.curChar:startsWith("bf")
	end

	self.camFollow = {x = 0, y = 0}
	self.curZoom = 0.9

	self.camChar = Camera()
	self.camChar.scroll = {x = 0, y = 0}
	self.camMenu = Camera()
	game.cameras.add(self.camChar, false)
	game.cameras.add(self.camMenu, false)

	local bg = Sprite(0, 0, paths.getImage("menus/menuDesat"))
	bg:setGraphicSize(game.width, game.height)
	bg:updateHitbox()
	bg:screenCenter()
	bg.color = Color.fromRGB(36, 38, 52)
	bg.scrollFactor:set(0, 0)
	self:add(bg)

	self.floor = Graphic(-2000, 840, 6000, 4, Color.fromRGB(15, 15, 22))
	self.floor.cameras = {self.camChar}
	self:add(self.floor)

	local bfRefImg = paths.getImage("editor/character/bf-white")
	if bfRefImg then
		self.bfPos = Sprite(777, 449, bfRefImg)
		self.bfPos.cameras = {self.camChar}
		self.bfPos.alpha = 0.25
		self:add(self.bfPos)
	end

	local dadRefImg = paths.getImage("editor/character/dad-white")
	if dadRefImg then
		self.dadPos = Sprite(105, 100, dadRefImg)
		self.dadPos.cameras = {self.camChar}
		self.dadPos.alpha = 0.25
		self:add(self.dadPos)
	end

	self.ghostLayer = Group()
	self:add(self.ghostLayer)

	self.charLayer = Group()
	self:add(self.charLayer)

	self.camPoint1 = Graphic(0, 0, 3, 30, Color.fromRGB(255, 230, 80))
	self.camPoint1.cameras = {self.camChar}
	self:add(self.camPoint1)

	self.camPoint2 = Graphic(0, 0, 30, 3, Color.fromRGB(255, 230, 80))
	self.camPoint2.cameras = {self.camChar}
	self:add(self.camPoint2)

	self.smallFont = paths.getFont("vcr.ttf", 14) or love.graphics.getFont()
	self.uiFont = paths.getFont("vcr.ttf", 15) or love.graphics.getFont()

	self.hudCard = Graphic(14, 14, 280, 290, Color.fromRGB(16, 18, 28))
	self.hudCard.alpha = 0.88
	self.hudCard.cameras = {self.camMenu}
	self:add(self.hudCard)

	self.charInfoTxt = Text(24, 22, "", self.smallFont, Color.WHITE, "left", 260)
	self.charInfoTxt.cameras = {self.camMenu}
	self:add(self.charInfoTxt)

	self.animInfoTxt = Text(24, 132, "", self.smallFont, Color.fromRGB(205, 220, 255), "left", 260)
	self.animInfoTxt.cameras = {self.camMenu}
	self:add(self.animInfoTxt)

	self.helpTxt = Text(14, game.height - 132, table.concat({
		"WASD / Drag : Move Camera  |  Wheel / Ctrl+-+ : Zoom",
		"Q / E : Prev / Next Anim   |  SPACE : Replay Anim",
		"Arrows : Offset (-/+ 1px, Shift = 10px)  |  G : Toggle Ghost",
		"Ctrl+S : Save Character    |  ESC : Exit Editor"
	}, "\n"), self.smallFont, Color.fromRGB(200, 205, 225))
	self.helpTxt.outline.style = "simple"
	self.helpTxt.outline.size = 1
	self.helpTxt.cameras = {self.camMenu}
	self:add(self.helpTxt)

	self.panelX = math.floor(game.width * 0.66)
	self.panelW = game.width - self.panelX - 12

	self.tabs = UITabMenu(self.panelX, 12, {"Character", "Animations"}, self.panelW, game.height - 24)
	self.tabs.cameras = {self.camMenu}
	self:add(self.tabs)

	self:loadCharacter()
	self:buildCharacterTab()
	self:buildAnimationTab()
	self:syncUIWithCharacter()

	if Discord then
		Discord.changePresence({
			details = "Character Editor",
			state = "Editing: " .. tostring(self.curChar)
		})
	end
end

function CharacterEditor:registerInput(inp)
	table.insert(self.textInputs, inp)
	return inp
end

function CharacterEditor:isTyping()
	for _, inp in ipairs(self.textInputs) do
		if inp.focused then return true end
	end
	return false
end

function CharacterEditor:collectCharacterNames()
	local out, seen = {}, {}
	for _, item in ipairs(paths.getItems("data/characters", "file", "json") or {}) do
		local id = item:gsub("%.json$", "")
		if not seen[id] then
			seen[id] = true
			table.insert(out, id)
		end
	end
	if #out == 0 then out = {"bf", "dad", "gf"} end
	table.sort(out)
	return out
end

function CharacterEditor:loadCharacter(overrideData)
	self.ghostLayer:clear()
	self.charLayer:clear()

	if overrideData then
		Parser.clearCache()
	end

	local ok, ch = pcall(Character, 0, 0, self.curChar, self.isPlayer)
	if not ok or not ch then
		self.curChar = "bf"
		ch = Character(0, 0, "bf", self.isPlayer)
	end
	self.char = ch
	self.char.cameras = {self.camChar}
	self.charLayer:add(self.char)

	-- Ensure animationsTable is populated
	self.char.animationsTable = self.char.animationsTable or {}
	if #self.char.animationsTable == 0 then
		table.insert(self.char.animationsTable, {"idle", "idle", {}, 24, false, {0, 0}})
	end
	for _, anim in ipairs(self.char.animationsTable) do
		anim[3] = anim[3] or {}
		anim[4] = anim[4] or 24
		anim[5] = anim[5] == true
		anim[6] = anim[6] or {0, 0}
	end

	-- Ghost reference character
	local gOk, ghost = pcall(Character, 0, 0, self.curChar, self.isPlayer)
	if gOk and ghost then
		self.ghost = ghost
		self.ghost.cameras = {self.camChar}
		self.ghost.alpha = self.showGhost and 0.38 or 0
		self.ghost.color = Color.fromRGB(165, 195, 255)
		self.ghostLayer:add(self.ghost)
	else
		self.ghost = nil
	end

	self:refreshHealthPreview()

	self.curSelected = 1
	self:changeAnim(0)
	self:repositionCharacter()
	self.camFollow = {x = (self.isPlayer and 430 or -130), y = 260}
end

function CharacterEditor:refreshHealthPreview()
	if self.healthIcon then self.healthIcon:destroy(); self.healthIcon = nil end
	if self.iconSwatch then self.iconSwatch:destroy(); self.iconSwatch = nil end

	local col = Color.fromRGB(161, 161, 161)
	if self.char.iconColor then
		local ok, parsed = pcall(Color.fromString, tostring(self.char.iconColor))
		if ok and parsed then col = parsed end
	end
	self.iconSwatch = Graphic(234, 26, 44, 44, col)
	self.iconSwatch.lined = true
	self.iconSwatch.line.width = 2
	self.iconSwatch.line.color = Color.WHITE
	self.iconSwatch.config.round = {6, 6}
	self.iconSwatch.cameras = {self.camMenu}
	self.charLayer:add(self.iconSwatch)

	self.healthIcon = HealthIcon(self.char.icon or "face", false)
	self.healthIcon.cameras = {self.camMenu}
	self.healthIcon:setPosition(190, 198)
	self.healthIcon:setScale(0.62)
	self.charLayer:add(self.healthIcon)
end

function CharacterEditor:repositionCharacter()
	local baseX = self.isPlayer and 770 or 100
	local px = (self.char.positionTable and self.char.positionTable.x) or 0
	local py = (self.char.positionTable and self.char.positionTable.y) or 0
	self.char.x = baseX + px
	self.char.y = 100 + py
	if self.ghost then
		self.ghost.x = self.char.x
		self.ghost.y = self.char.y
		self.ghost.flipX = self.char.flipX
		self.ghost.scale:set(self.char.scale.x, self.char.scale.y)
	end
end

function CharacterEditor:buildCharacterTab()
	local g = Group()
	local function lbl(x, y, text)
		local t = Text(x, y, text, self.smallFont, Color.fromRGB(210, 215, 235))
		g:add(t)
		return t
	end

	local charNames = self:collectCharacterNames()

	lbl(14, 10, "Preset Character:")
	lbl(224, 10, "Save Name / ID:")
	self.inCharId = self:registerInput(UIInputTextBox(224, 28, 185, 26, self.uiFont))
	self.inCharId.text = self.curChar
	g:add(self.inCharId)

	lbl(14, 64, "Sprite Atlas Path (images/...):")
	self.inSprite = self:registerInput(UIInputTextBox(14, 82, 270, 26, self.uiFont))
	self.inSprite.text = tostring(self.char.imageFile or "characters/BOYFRIEND")
	self.inSprite.onChanged = function(v) self.char.imageFile = v end
	g:add(self.inSprite)

	g:add(UIButton(294, 82, 115, 26, "Apply Atlas", function()
		self:applySpriteAtlas(self.inSprite.text)
	end))

	lbl(14, 118, "Health Icon:")
	self.inIcon = self:registerInput(UIInputTextBox(14, 136, 185, 26, self.uiFont))
	self.inIcon.text = tostring(self.char.icon or "bf")
	self.inIcon.onChanged = function(v)
		self.char.icon = v ~= "" and v or "face"
		self:refreshHealthPreview()
	end
	g:add(self.inIcon)

	lbl(214, 118, "Bar Color (#HEX):")
	self.inColor = self:registerInput(UIInputTextBox(214, 136, 195, 26, self.uiFont))
	self.inColor.text = tostring(self.char.iconColor or "#31B0D1")
	self.inColor.onChanged = function(v)
		self.char.iconColor = v
		self:refreshHealthPreview()
	end
	g:add(self.inColor)

	self.cbPlayable = UICheckbox(14, 176, 20)
	self.cbPlayable.checked = self.isPlayer
	self.cbPlayable.callback = function(c)
		self.isPlayer = c
		self.char.flipX = self.char.jsonFlipX
		if self.isPlayer then self.char.flipX = not self.char.flipX end
		self:repositionCharacter()
	end
	g:add(self.cbPlayable)
	lbl(40, 178, "Playable (BF)")

	self.cbFlipX = UICheckbox(165, 176, 20)
	self.cbFlipX.checked = self.char.jsonFlipX == true
	self.cbFlipX.callback = function(c)
		self.char.jsonFlipX = c
		self.char.flipX = c
		if self.isPlayer then self.char.flipX = not self.char.flipX end
		self:repositionCharacter()
	end
	g:add(self.cbFlipX)
	lbl(191, 178, "Flip X")

	self.cbAntialias = UICheckbox(280, 176, 20)
	self.cbAntialias.checked = self.char.jsonAntialiasing ~= false
	self.cbAntialias.callback = function(c)
		self.char.jsonAntialiasing = c
		self.char.antialiasing = c
	end
	g:add(self.cbAntialias)
	lbl(306, 178, "Antialias")

	lbl(14, 212, "Scale:")
	self.stScale = UINumericStepper(14, 230, 0.05, tonumber(self.char.jsonScale) or 1, 0.1, 10, 125, 26)
	self.stScale.onChanged = function(v)
		self.char.jsonScale = v
		self.char.scale:set(v, v)
		self.char:updateHitbox()
		self:repositionCharacter()
	end
	self:registerInput(self.stScale)
	g:add(self.stScale)

	lbl(156, 212, "Sing Hold (steps):")
	self.stHold = UINumericStepper(156, 230, 0.5, tonumber(self.char.holdTime) or 4, 1, 64, 135, 26)
	self.stHold.onChanged = function(v) self.char.holdTime = v end
	self:registerInput(self.stHold)
	g:add(self.stHold)

	lbl(14, 268, "Position X / Y:")
	self.stPosX = UINumericStepper(14, 286, 10, self.char.positionTable.x, -9000, 9000, 135, 26)
	self.stPosX.onChanged = function(v)
		self.char.positionTable.x = v
		self:repositionCharacter()
	end
	self:registerInput(self.stPosX)
	g:add(self.stPosX)

	self.stPosY = UINumericStepper(162, 286, 10, self.char.positionTable.y, -9000, 9000, 135, 26)
	self.stPosY.onChanged = function(v)
		self.char.positionTable.y = v
		self:repositionCharacter()
	end
	self:registerInput(self.stPosY)
	g:add(self.stPosY)

	lbl(14, 324, "Camera Offset X / Y:")
	self.stCamX = UINumericStepper(14, 342, 10, self.char.cameraPosition.x, -9000, 9000, 135, 26)
	self.stCamX.onChanged = function(v) self.char.cameraPosition.x = v end
	self:registerInput(self.stCamX)
	g:add(self.stCamX)

	self.stCamY = UINumericStepper(162, 342, 10, self.char.cameraPosition.y, -9000, 9000, 135, 26)
	self.stCamY.onChanged = function(v) self.char.cameraPosition.y = v end
	self:registerInput(self.stCamY)
	g:add(self.stCamY)

	g:add(UIButton(14, 392, 190, 34, "Save Character (Ctrl+S)", function() self:saveCharacter(false) end))
	g:add(UIButton(216, 392, 190, 34, "Reset Cam View", function()
		self.curZoom = 0.9
		self.camFollow = {x = (self.isPlayer and 430 or -130), y = 260}
	end))

	-- Dropdown added last for top Z-order
	self.ddChar = UIDropDown(14, 28, charNames, math.max(1, table.find(charNames, self.curChar) or 1), 198, 26)
	self.ddChar.callback = function(val)
		self.curChar = val
		self.isPlayer = val:startsWith("bf")
		self:loadCharacter()
		self:syncUIWithCharacter()
	end
	g:add(self.ddChar)

	self.tabs:addGroup(g, 1)
end

function CharacterEditor:buildAnimationTab()
	local g = Group()
	local function lbl(x, y, text)
		local t = Text(x, y, text, self.smallFont, Color.fromRGB(210, 215, 235))
		g:add(t)
		return t
	end

	lbl(14, 10, "Select Animation:")
	lbl(224, 10, "Ghost Reference:")

	self.cbGhost = UICheckbox(14, 68, 20)
	self.cbGhost.checked = self.showGhost
	self.cbGhost.callback = function(c)
		self.showGhost = c
		if self.ghost then self.ghost.alpha = c and 0.38 or 0 end
	end
	g:add(self.cbGhost)
	lbl(40, 70, "Show Onion-Skin Ghost (G)")

	lbl(14, 104, "Anim Name (e.g. idle, singLEFT):")
	self.inAnimName = self:registerInput(UIInputTextBox(14, 122, 190, 26, self.uiFont))
	g:add(self.inAnimName)

	lbl(216, 104, "Atlas Prefix (XML frame name):")
	self.inAnimPrefix = self:registerInput(UIInputTextBox(216, 122, 195, 26, self.uiFont))
	g:add(self.inAnimPrefix)

	lbl(14, 160, "Frame Indices CSV (optional, e.g. 0,1,2,3):")
	self.inAnimIndices = self:registerInput(UIInputTextBox(14, 178, 240, 26, self.uiFont))
	g:add(self.inAnimIndices)

	lbl(270, 160, "FPS:")
	self.stAnimFPS = UINumericStepper(270, 178, 1, 24, 1, 120, 138, 26)
	self:registerInput(self.stAnimFPS)
	g:add(self.stAnimFPS)

	self.cbAnimLoop = UICheckbox(14, 218, 20)
	g:add(self.cbAnimLoop)
	lbl(40, 220, "Loop Animation")

	lbl(14, 254, "Offset X / Y (or use Arrow keys):")
	self.stOffX = UINumericStepper(14, 272, 1, 0, -4000, 4000, 138, 26)
	self.stOffX.onChanged = function(v)
		if self.curAnim then self:changeOffsets(v, self.curAnim[6][2]) end
	end
	self:registerInput(self.stOffX)
	g:add(self.stOffX)

	self.stOffY = UINumericStepper(166, 272, 1, 0, -4000, 4000, 138, 26)
	self.stOffY.onChanged = function(v)
		if self.curAnim then self:changeOffsets(self.curAnim[6][1], v) end
	end
	self:registerInput(self.stOffY)
	g:add(self.stOffY)

	g:add(UIButton(14, 322, 192, 34, "Add / Update Anim", function() self:addOrUpdateAnimation() end))
	g:add(UIButton(218, 322, 192, 34, "Delete Current Anim", function() self:deleteCurrentAnimation() end))
	g:add(UIButton(14, 368, 396, 32, "Save Character JSON (Ctrl+S)", function() self:saveCharacter(false) end))

	local animNames = self:getAnimNames()
	self.ddGhost = UIDropDown(224, 28, animNames, 1, 186, 26)
	self.ddGhost.callback = function(v)
		self.ghostAnimName = v
		if self.ghost and self.ghost:hasAnim(v) then
			self.ghost:playAnim(v, true)
		end
	end
	self.ddAnim = UIDropDown(14, 28, animNames, 1, 196, 26)
	self.ddAnim.callback = function(_, idx)
		self.curSelected = idx
		self:changeAnim(0)
	end
	g:add(self.ddGhost)
	g:add(self.ddAnim)

	self.tabs:addGroup(g, 2)
end

function CharacterEditor:getAnimNames()
	local list = {}
	for _, a in ipairs(self.char and self.char.animationsTable or {}) do
		table.insert(list, tostring(a[1] or "idle"))
	end
	if #list == 0 then list = {"idle"} end
	return list
end

function CharacterEditor:syncUIWithCharacter()
	if not self.char then return end
	if self.inCharId then self.inCharId.text = tostring(self.curChar) end
	if self.inSprite then self.inSprite.text = tostring(self.char.imageFile or "") end
	if self.inIcon then self.inIcon.text = tostring(self.char.icon or "bf") end
	if self.inColor then self.inColor.text = tostring(self.char.iconColor or "#31B0D1") end
	if self.cbPlayable then self.cbPlayable.checked = self.isPlayer end
	if self.cbFlipX then self.cbFlipX.checked = self.char.jsonFlipX == true end
	if self.cbAntialias then self.cbAntialias.checked = self.char.jsonAntialiasing ~= false end
	if self.stScale then self.stScale.value = tonumber(self.char.jsonScale) or 1; self.stScale.text = tostring(self.stScale.value) end
	if self.stHold then self.stHold.value = tonumber(self.char.holdTime) or 4; self.stHold.text = tostring(self.stHold.value) end
	if self.stPosX then self.stPosX.value = self.char.positionTable.x; self.stPosX.text = tostring(self.stPosX.value) end
	if self.stPosY then self.stPosY.value = self.char.positionTable.y; self.stPosY.text = tostring(self.stPosY.value) end
	if self.stCamX then self.stCamX.value = self.char.cameraPosition.x; self.stCamX.text = tostring(self.stCamX.value) end
	if self.stCamY then self.stCamY.value = self.char.cameraPosition.y; self.stCamY.text = tostring(self.stCamY.value) end

	local animNames = self:getAnimNames()
	if self.ddAnim then self.ddAnim:setItems(animNames, self.curSelected) end
	if self.ddGhost then
		local gIdx = table.find(animNames, self.ghostAnimName) or 1
		self.ddGhost:setItems(animNames, gIdx)
	end
	self:syncAnimFields()
end

function CharacterEditor:syncAnimFields()
	local a = self.curAnim
	if not a then return end
	if self.inAnimName then self.inAnimName.text = tostring(a[1] or "") end
	if self.inAnimPrefix then self.inAnimPrefix.text = tostring(a[2] or "") end
	if self.inAnimIndices then
		local idxList = type(a[3]) == "table" and a[3] or {}
		local parts = {}
		for i, v in ipairs(idxList) do parts[i] = tostring(v) end
		self.inAnimIndices.text = table.concat(parts, ",")
	end
	if self.stAnimFPS then
		self.stAnimFPS.value = tonumber(a[4]) or 24
		self.stAnimFPS.text = tostring(self.stAnimFPS.value)
	end
	if self.cbAnimLoop then self.cbAnimLoop.checked = a[5] == true end
	a[6] = a[6] or {0, 0}
	if self.stOffX then self.stOffX.value = a[6][1] or 0; self.stOffX.text = tostring(self.stOffX.value) end
	if self.stOffY then self.stOffY.value = a[6][2] or 0; self.stOffY.text = tostring(self.stOffY.value) end
end

function CharacterEditor:applySpriteAtlas(spritePath)
	if not spritePath or spritePath == "" then return end
	local atlas = paths.getAtlas(spritePath)
	if not atlas then
		Toast.error("Atlas not found: images/" .. tostring(spritePath))
		return
	end
	self.char.imageFile = spritePath
	self.char:setFrames(atlas)
	for _, an in ipairs(self.char.animationsTable) do
		local animName, prefix, indices, fps, loop, off = an[1], an[2], an[3], an[4] or 24, an[5] == true, an[6] or {0, 0}
		if indices and #indices > 0 then
			self.char.anim:addByIndices(animName, prefix, indices, nil, fps, loop)
		else
			self.char.anim:addByPrefix(animName, prefix, fps, loop)
		end
		local added = self.char.anim:get(animName)
		if added then added.offset:set(off[1] or 0, off[2] or 0) end
	end
	self:changeAnim(0)
	Toast.info("Loaded atlas: " .. spritePath)
end

function CharacterEditor:addOrUpdateAnimation()
	local name = self.inAnimName and self.inAnimName.text or ""
	local prefix = self.inAnimPrefix and self.inAnimPrefix.text or ""
	if name == "" or prefix == "" then
		Toast.error("Animation Name and XML Prefix are required")
		return
	end
	local indices = {}
	if self.inAnimIndices and self.inAnimIndices.text ~= "" then
		for tok in self.inAnimIndices.text:gmatch("[^,%s]+") do
			local n = tonumber(tok)
			if n then table.insert(indices, math.floor(n)) end
		end
	end
	local fps = self.stAnimFPS and tonumber(self.stAnimFPS.value) or 24
	local loop = self.cbAnimLoop and self.cbAnimLoop.checked or false
	local ox = self.stOffX and tonumber(self.stOffX.value) or 0
	local oy = self.stOffY and tonumber(self.stOffY.value) or 0

	if #indices > 0 then
		self.char.anim:addByIndices(name, prefix, indices, nil, fps, loop)
	else
		self.char.anim:addByPrefix(name, prefix, fps, loop)
	end
	if not self.char.anim:has(name) then
		Toast.error("No frames matched prefix '" .. prefix .. "'")
		return
	end
	local added = self.char.anim:get(name)
	if added then added.offset:set(ox, oy) end

	local entry = {name, prefix, indices, fps, loop, {ox, oy}}
	local foundIdx = nil
	for i, a in ipairs(self.char.animationsTable) do
		if a[1] == name then foundIdx = i; break end
	end
	if foundIdx then
		self.char.animationsTable[foundIdx] = entry
		self.curSelected = foundIdx
	else
		table.insert(self.char.animationsTable, entry)
		self.curSelected = #self.char.animationsTable
	end
	self.char.animOffsets[name] = {x = ox, y = oy}

	local animNames = self:getAnimNames()
	if self.ddAnim then self.ddAnim:setItems(animNames, self.curSelected) end
	if self.ddGhost then self.ddGhost:setItems(animNames, table.find(animNames, self.ghostAnimName) or 1) end
	self:changeAnim(0)
	Toast.info("Saved animation '" .. name .. "'")
end

function CharacterEditor:deleteCurrentAnimation()
	if #self.char.animationsTable <= 1 then
		Toast.warn("Character must keep at least 1 animation")
		return
	end
	local removed = table.remove(self.char.animationsTable, self.curSelected)
	if self.curSelected > #self.char.animationsTable then
		self.curSelected = #self.char.animationsTable
	end
	local animNames = self:getAnimNames()
	if self.ddAnim then self.ddAnim:setItems(animNames, self.curSelected) end
	self:changeAnim(0)
	if removed then Toast.info("Deleted animation '" .. tostring(removed[1]) .. "'") end
end

function CharacterEditor:changeOffsets(x, y)
	if not self.curAnim then return end
	self.curAnim[6] = self.curAnim[6] or {0, 0}
	self.curAnim[6][1], self.curAnim[6][2] = x, y
	self.char.animOffsets[self.curAnim[1]] = {x = x, y = y}
	local animation = self.char.anim:get(self.curAnim[1])
	if animation then animation.offset:set(x, y) end
	if self.stOffX then self.stOffX.value = x; self.stOffX.text = tostring(x) end
	if self.stOffY then self.stOffY.value = y; self.stOffY.text = tostring(y) end
end

function CharacterEditor:changeAnim(delta)
	local tbl = self.char.animationsTable
	if not tbl or #tbl == 0 then return end
	self.curSelected = (self.curSelected - 1 + (delta or 0)) % #tbl + 1
	self.curAnim = tbl[self.curSelected]
	if self.curAnim and self.char:hasAnim(self.curAnim[1]) then
		self.char:playAnim(self.curAnim[1], true)
	end
	if self.ddAnim then self.ddAnim.curSelected = self.curSelected; self.ddAnim.label.content = tostring(self.curAnim[1]) end
	self:syncAnimFields()
end

function CharacterEditor:buildExportTable()
	return {
		animations = self.char.animationsTable,
		sprite = self.char.imageFile,
		position = {self.char.positionTable.x, self.char.positionTable.y},
		camera_points = {self.char.cameraPosition.x, self.char.cameraPosition.y},
		icon = self.char.icon,
		color = self.char.iconColor,
		flip_x = self.char.jsonFlipX == true,
		antialiasing = self.char.jsonAntialiasing ~= false,
		sing_duration = tonumber(self.char.holdTime) or 4,
		scale = tonumber(self.char.jsonScale) or 1
	}
end

function CharacterEditor:saveCharacter(useNativeDialog)
	local charId = (self.inCharId and self.inCharId.text ~= "") and self.inCharId.text or self.curChar
	self.curChar = charId
	local payload = JSON.buildChar(self:buildExportTable())

	if useNativeDialog and WindowDialogue and WindowDialogue.askSaveAsFile then
		local dst = WindowDialogue.askSaveAsFile(nil, {{"JSON Files", "*.json"}}, charId .. ".json")
		if dst then
			local f = io.open(dst, "wb")
			if f then
				f:write(payload)
				f:close()
				Parser.clearCache()
				Toast.info("Saved character: " .. dst)
				return true, dst
			end
		end
	end

	local prefix = (Mods.currentMod and Mods.currentMod ~= "")
		and ((Mods.root or "mods") .. "/" .. Mods.currentMod .. "/") or "assets/"
	local virtualPath = prefix .. "data/characters/" .. charId .. ".json"
	local ok, targetOrErr = Storage.writeFile(virtualPath, payload)
	Parser.clearCache()
	if ok then
		util.playSfx(paths.getSound("confirmMenu"))
		Toast.info("Saved character: " .. tostring(targetOrErr))
		return true, targetOrErr
	else
		Toast.error("Save failed: " .. tostring(targetOrErr))
		return false, targetOrErr
	end
end

function CharacterEditor:updateCameraCrosshair()
	local midX, midY = self.char:getMidpoint()
	midX = midX + (self.isPlayer and -100 or 150)
	midY = midY - 100
	local cx = (self.isPlayer and -self.char.cameraPosition.x or self.char.cameraPosition.x)
	local cy = self.char.cameraPosition.y
	self.camPoint1.x, self.camPoint1.y = midX + cx - 1.5, midY + cy - 15
	self.camPoint2.x, self.camPoint2.y = midX + cx - 15, midY + cy - 1.5
end

function CharacterEditor:update(dt)
	CharacterEditor.super.update(self, dt)

	local mouseInStage = Mouse.x >= 0 and Mouse.x < self.panelX and Mouse.y >= 0 and Mouse.y < game.height

	if not self:isTyping() then
		local shift = game.keys.pressed.SHIFT
		local ctrl = game.keys.pressed.CONTROL
		local step = shift and 10 or 1
		local camPan = (shift and 520 or 220) * dt

		if ctrl and game.keys.justPressed.S then
			self:saveCharacter(shift)
		elseif game.keys.justPressed.SPACE and self.curAnim then
			self.char:playAnim(self.curAnim[1], true)
		elseif game.keys.justPressed.G then
			self.showGhost = not self.showGhost
			if self.cbGhost then self.cbGhost.checked = self.showGhost end
			if self.ghost then self.ghost.alpha = self.showGhost and 0.38 or 0 end
		elseif game.keys.justPressed.Q then
			self:changeAnim(-1)
		elseif game.keys.justPressed.E then
			self:changeAnim(1)
		elseif game.keys.justPressed.ESCAPE then
			if CharacterEditor.onPlayState then
				CharacterEditor.onPlayState = false
				game.switchState(PlayState())
			else
				util.playMenuMusic()
				game.switchState(MainMenuState())
			end
			return
		end

		if game.keys.pressed.A then self.camFollow.x = self.camFollow.x - camPan end
		if game.keys.pressed.D then self.camFollow.x = self.camFollow.x + camPan end
		if game.keys.pressed.W then self.camFollow.y = self.camFollow.y - camPan end
		if game.keys.pressed.S and not ctrl then self.camFollow.y = self.camFollow.y + camPan end

		if mouseInStage and Mouse.pressedLeft and (Mouse.x > 300 or Mouse.y > 310) then
			self.camFollow.x = self.camFollow.x - (Mouse.deltaScreenX / math.max(0.1, self.curZoom))
			self.camFollow.y = self.camFollow.y - (Mouse.deltaScreenY / math.max(0.1, self.curZoom))
		end

		if mouseInStage and Mouse.wheel ~= 0 then
			self.curZoom = math.clamp(self.curZoom + Mouse.wheel * 0.08, 0.2, 2.5)
		elseif ctrl and (game.keys.justPressed.PLUS or game.keys.justPressed.EQUALS) then
			self.curZoom = math.clamp(self.curZoom + 0.1, 0.2, 2.5)
		elseif ctrl and game.keys.justPressed.MINUS then
			self.curZoom = math.clamp(self.curZoom - 0.1, 0.2, 2.5)
		end

		if self.curAnim then
			local ox, oy = self.curAnim[6][1] or 0, self.curAnim[6][2] or 0
			if game.keys.justPressed.LEFT then
				self:changeOffsets(ox + step, oy)
			elseif game.keys.justPressed.RIGHT then
				self:changeOffsets(ox - step, oy)
			end
			if game.keys.justPressed.UP then
				self:changeOffsets(self.curAnim[6][1], oy + step)
			elseif game.keys.justPressed.DOWN then
				self:changeOffsets(self.curAnim[6][1], oy - step)
			end
		end
	end

	self.camChar.zoom = util.coolLerp(self.camChar.zoom, self.curZoom, 10, dt)
	self.camChar.scroll.x = util.coolLerp(self.camChar.scroll.x, self.camFollow.x, 12, dt)
	self.camChar.scroll.y = util.coolLerp(self.camChar.scroll.y, self.camFollow.y, 12, dt)

	self:updateCameraCrosshair()

	self.charInfoTxt.content = string.format(
		"CHARACTER: %s\nAtlas : %s\nIcon  : %s\nFlipX : %s  |  Zoom: %.2fx\nMod   : %s",
		tostring(self.curChar),
		tostring(self.char.imageFile or "?"),
		tostring(self.char.icon or "?"),
		tostring(self.char.jsonFlipX == true),
		self.curZoom,
		tostring(Mods.currentMod or "(base)")
	)

	if self.curAnim then
		self.animInfoTxt.content = string.format(
			"ANIMATION [%d/%d]\nName   : %s\nPrefix : %s\nOffset : [%d, %d]\nFPS    : %s  |  Loop: %s\nGhost  : %s (%s)",
			self.curSelected,
			#self.char.animationsTable,
			tostring(self.curAnim[1]),
			tostring(self.curAnim[2]),
			self.curAnim[6][1] or 0,
			self.curAnim[6][2] or 0,
			tostring(self.curAnim[4] or 24),
			tostring(self.curAnim[5] == true),
			tostring(self.ghostAnimName),
			self.showGhost and "ON" or "OFF"
		)
	end
end

function CharacterEditor:leave()
	Character.editorMode = false
	if love.window and Project and Project.title then
		love.window.setTitle(Project.title)
	end
end

return CharacterEditor

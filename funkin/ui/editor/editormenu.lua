local EditorMenu = Substate:extend("EditorMenu")

EditorMenu.entries = {
	{
		label = "Chart Editor",
		desc = "Create & edit songs, notes, sustains, BPM, events, and difficulties.",
		action = function()
			PlayState.chartingMode = true
			if not PlayState.SONG then
				pcall(PlayState.loadSong, "bopeebo", "normal")
			end
			game.switchState(ChartingState())
		end
	},
	{
		label = "Character Editor",
		desc = "Configure character sprites, animations, offsets, health icons, and camera.",
		action = function()
			CharacterEditor.onPlayState = false
			game.switchState(CharacterEditor())
		end
	},
	{
		label = "Stage & Cutscene Editor",
		desc = "Preview stages, adjust character/camera positions, and build JSON cutscenes.",
		action = function()
			game.switchState(CutsceneState())
		end
	},
	{
		label = "Create New Mod",
		desc = "Generate a ready-to-use mod template folder with metadata, song, character, stage & script.",
		action = function(menu)
			local baseId = "my-mod"
			local idx = 1
			local candidate = baseId
			while paths.exists((Mods.root or "mods") .. "/" .. candidate, "directory") do
				idx = idx + 1
				candidate = baseId .. "-" .. idx
			end
			local ok, msg = ModAPI.createTemplate(candidate, {
				name = "My Mod " .. tostring(idx)
			})
			if ok then
				util.playSfx(paths.getSound("confirmMenu"))
				Toast.info("Mod created: " .. tostring(msg))
			else
				Toast.error(tostring(msg))
			end
		end
	}
}

function EditorMenu:new(onSave)
	EditorMenu.super.new(self)

	self.onSave = onSave
	self.curSelected = 1

	self.bg = Graphic(0, 0, game.width, game.height, Color.BLACK)
	self.bg.alpha = 0
	self.bg.scrollFactor:set(0, 0)
	self:add(self.bg)

	self.headerBg = Graphic(0, 0, game.width, 64, Color.fromRGB(16, 16, 24))
	self.headerBg.alpha = 0.9
	self.headerBg.scrollFactor:set(0, 0)
	self:add(self.headerBg)

	local titleFont = paths.getFont("vcr.ttf", 28) or love.graphics.getFont()
	self.titleText = Text(28, 18, "LIGHT ENGINE — EDITORS & MODDING TOOLS", titleFont, Color.WHITE)
	self.titleText.scrollFactor:set(0, 0)
	self:add(self.titleText)

	self.grpOptions = Group()
	self:add(self.grpOptions)

	for i, entry in ipairs(EditorMenu.entries) do
		local item = AtlasText(90, 130 + (i - 1) * 110, entry.label, "bold")
		item.scrollFactor:set(0, 0)
		item.ID = i
		item._targetX = 90
		item._targetY = 130 + (i - 1) * 110
		self.grpOptions:add(item)
	end

	self.footerBg = Graphic(0, game.height - 64, game.width, 64, Color.fromRGB(16, 16, 24))
	self.footerBg.alpha = 0.92
	self.footerBg.scrollFactor:set(0, 0)
	self:add(self.footerBg)

	local descFont = paths.getFont("vcr.ttf", 18) or love.graphics.getFont()
	self.descText = Text(24, game.height - 44, "", descFont, Color.fromRGB(215, 220, 240), "center", game.width - 48)
	self.descText.scrollFactor:set(0, 0)
	self:add(self.descText)

	self.throttles = {
		up = Throttle:make({controls.down, controls, "ui_up"}),
		down = Throttle:make({controls.down, controls, "ui_down"})
	}

	self:changeSelection(0)
end

function EditorMenu:enter()
	EditorMenu.super.enter(self)
	Tween.tween(self.bg, {alpha = 0.72}, 0.25, {ease = Ease.quartOut})
end

function EditorMenu:update(dt)
	EditorMenu.super.update(self, dt)

	if Mouse.wheel ~= 0 then
		self:changeSelection(-Mouse.wheel)
	end

	if self.throttles then
		local shift = game.keys.pressed.SHIFT
		if self.throttles.up:check(shift) then self:changeSelection(-1) end
		if self.throttles.down:check(shift) then self:changeSelection(1) end
	end

	for _, item in ipairs(self.grpOptions.members) do
		item.x = math.lerp(item._targetX, item.x, math.exp(-dt * 14))
		item.y = math.lerp(item._targetY, item.y, math.exp(-dt * 14))
	end

	if controls:pressed("back") then
		util.playSfx(paths.getSound("cancelMenu"))
		self:close()
		return
	end

	if controls:pressed("accept") then
		self:activateCurrent()
	end
end

function EditorMenu:activateCurrent()
	local entry = EditorMenu.entries[self.curSelected]
	if not entry then return end
	if entry.label == "Create New Mod" then
		entry.action(self)
		return
	end
	if self.onSave then self.onSave() end
	util.playSfx(paths.getSound("confirmMenu"))
	self:close()
	entry.action(self)
end

function EditorMenu:changeSelection(change)
	change = change or 0
	self.curSelected = (self.curSelected - 1 + change) % #EditorMenu.entries + 1

	for _, item in ipairs(self.grpOptions.members) do
		if item.ID == self.curSelected then
			item.alpha = 1
			item._targetX = 120
		else
			item.alpha = 0.55
			item._targetX = 80
		end
	end

	local entry = EditorMenu.entries[self.curSelected]
	if entry and self.descText then
		self.descText.content = entry.desc .. "  [ENTER: Open | ESC: Back]"
	end

	if change ~= 0 then
		util.playSfx(paths.getSound("scrollMenu"))
	end
end

function EditorMenu:close()
	if self.throttles then
		for _, t in pairs(self.throttles) do t:destroy() end
		self.throttles = nil
	end
	EditorMenu.super.close(self)
end

return EditorMenu

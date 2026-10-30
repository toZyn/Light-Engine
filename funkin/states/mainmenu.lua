local MainMenuState = State:extend("MainMenuState")

MainMenuState.curSelected = 1

function MainMenuState:enter()
	self.notCreated = false

	self.versionText = Text(0, game.height - 18, "v" .. Project.version, paths.getFont("vcr.ttf", 16))
	self.versionText.antialiasing = false
	self.versionText.outline.width = 1
	self.versionText.scrollFactor:set()

	self.script = Script("data/states/mainmenu", false)
	local event = self.script:call("create")
	if event == Script.Event_Cancel then
		self.notCreated = true
		MainMenuState.super.enter(self)
		self:add(self.versionText)
		self.script:call("postCreate")
		return
	end
	MainMenuState.super.enter(self)

	-- Update Presence
	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Main Menu"})
	end

	self.menuItems = {'storymode', 'freeplay', 'credits', 'options', 'donate'}
	self.triggerChoices = {}
	for k, v in pairs(MainMenuState.triggerChoices) do
		self.triggerChoices[k] = v
	end

	self.selectedSomethin = false

	game.camera.target = {x = 0, y = 0}
	self.camFollow = {x = 0, y = 0}
	game.camera:follow(self.camFollow, nil, 10)

	local yScroll = math.max(0.25 - (0.05 * (#self.menuItems - 4)), 0.1)
	self.menuBg = Sprite()
	self.menuBg:loadTexture(paths.getImage('menus/menuBG'))
	self.menuBg.scrollFactor:set(0, yScroll)
	self.menuBg:setGraphicSize(math.floor(self.menuBg.width * 1.175))
	self.menuBg:updateHitbox()
	self.menuBg:screenCenter()
	self:add(self.menuBg)

	self.menuYellow = paths.getImage('menus/menuBG')
	self.menuMagenta = paths.getImage('menus/menuBGMagenta')

	self.menuList = MenuList(paths.getSound("scrollMenu"), true, "centered", function(self, obj)
		for _, spr in ipairs(self.members) do
			spr.yAdd = 50 + (self.curSelected) * (80 - game.height * 0.005)
		end
	end)
	self.menuList.selectCallback = function(menuItem)
		self:enterSelection(self.menuItems[menuItem.ID])
	end
	self.menuList.speed = 8
	self.menuList.scrollFactor:set()

	for i = 0, #self.menuItems - 1 do
		local item = Sprite(0, 0)
		item:setFrames(paths.getSparrowAtlas('menus/mainmenu/' .. self.menuItems[i + 1]))
		item.animation:addByPrefix('idle', self.menuItems[i + 1] .. ' idle', 24)
		item.animation:addByPrefix('selected', self.menuItems[i + 1] .. ' selected', 24)
		item.animation:play('idle')
		item.yAdd = 50 + (self.menuList.curSelected) * (80 - game.height * 0.005)

		self.menuList:add(item)
	end

	self:add(self.menuList)
	self:add(self.versionText)

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = util.createButtons("udab")
		self.buttons:add(VirtualPad("tab", game.width - 126, (game.height - 126) / 2, 126, 126))
		self:add(self.buttons)
	end

	self.menuList.changeCallback = function(curSelected, item)
		for _, spr in ipairs(self.menuList.members) do
			if spr.animation and spr.animation:has('idle') then
				spr.animation:play('idle')
				spr:updateHitbox()
			else
				spr.alpha = (spr == item) and 1 or 0.6
			end
		end

		if item.animation and item.animation:has('selected') then
			item.animation:play('selected')
			item:fixOffsets()
		else
			item.alpha = 1
		end
		local y = 120 * curSelected
		self.camFollow.x, self.camFollow.y = 0, y
	end
	self.menuList:changeSelection()
	self.menuList:updatePositions(0, 0)

	self.script:call("postCreate")
end

function MainMenuState:addMenuButton(id, labelOrCallback, callbackOrOpts, maybeOpts)
	if not id or id == "" or not self.menuList then return nil end
	local label, callback, opts
	if type(labelOrCallback) == "function" then
		label = tostring(id)
		callback = labelOrCallback
		opts = type(callbackOrOpts) == "table" and callbackOrOpts or {}
	else
		label = tostring(labelOrCallback or id)
		callback = callbackOrOpts
		opts = type(maybeOpts) == "table" and maybeOpts or {}
	end
	id = tostring(id)

	local atlasKey = opts.atlas or ("menus/mainmenu/" .. id)
	local idlePrefix = opts.idlePrefix or (id .. " idle")
	local selectedPrefix = opts.selectedPrefix or (id .. " selected")
	local hasAtlas = not opts.useText and paths.exists(paths.getPath("images/" .. atlasKey .. ".xml"), "file")

	local item
	if hasAtlas then
		item = Sprite(0, 0)
		item:setFrames(paths.getSparrowAtlas(atlasKey))
		item.animation:addByPrefix('idle', idlePrefix, 24)
		item.animation:addByPrefix('selected', selectedPrefix, 24)
		item.animation:play('idle')
	else
		item = AtlasText(0, 0, label, opts.font or "bold")
		item.alpha = 0.6
	end
	item.yAdd = 50 + (self.menuList.curSelected) * (80 - game.height * 0.005)

	local index = opts.index
	if type(index) == "number" and index >= 1 and index <= #self.menuItems + 1 then
		table.insert(self.menuItems, index, id)
		self.menuList:insert(index, item)
		for idx, member in ipairs(self.menuList.members) do
			member.ID = idx
		end
	else
		table.insert(self.menuItems, id)
		self.menuList:add(item)
	end

	local stay = opts.stay == true
	local flickerOut = (opts.flicker ~= nil) and (opts.flicker == true) or (not stay)
	self.triggerChoices = self.triggerChoices or {}
	self.triggerChoices[id] = {flickerOut, function(st)
		local res
		if type(callback) == "function" then
			res = callback(st, id, item)
		end
		if stay or res == true then
			if st.menuList and not st.optionsUI then
				st.menuList.lock = false
			end
			return true
		end
		return res == true
	end}

	local yScroll = math.max(0.25 - (0.05 * (#self.menuItems - 4)), 0.1)
	if self.menuBg then self.menuBg.scrollFactor:set(0, yScroll) end
	self.menuList:changeSelection(0, true)
	self.menuList:updatePositions(0, 0)
	return item
end

function MainMenuState:update(dt)
	self.script:call("update", dt)

	if self.notCreated then
		MainMenuState.super.update(self, dt)
		self.script:call("postUpdate", dt)
		return
	end

	if not self.selectedSomethin then
		if controls:pressed("back") then
			game.sound.play(paths.getSound('cancelMenu'))
			game.switchState(TitleState())
		elseif controls:pressed("pick_mods") then
			game.switchState(ModsState())
		elseif controls:pressed("debug_1") then
			util.playSfx(paths.getSound('scrollMenu'))
			self:openEditorMenu()
		elseif controls:pressed("debug_2") then
			util.playSfx(paths.getSound('scrollMenu'))
			game.switchState(CharacterEditor())
		end
	end

	MainMenuState.super.update(self, dt)
	self.script:call("postUpdate", dt)
end

MainMenuState.triggerChoices = {
	storymode = {true, function(self)
		game.switchState(StoryMenuState())
	end},
	freeplay = {true, function(self)
		game.switchState(FreeplayState())
	end},
	credits = {true, function(self)
		game.switchState(CreditsState())
	end},
	options = {false, function(self)
		if self.buttons then self:remove(self.buttons) end
		self.optionsUI = self.optionsUI or Options(true, function()
			self.menuList.lock = false

			if Discord then
				Discord.changePresence({details = "In the Menus", state = "Main Menu"})
			end
			if self.buttons then self:add(self.buttons) end
		end)
		self.optionsUI.applySettings = bind(self, self.onSettingChange)
		self.optionsUI.scrollFactor:set()
		self.optionsUI:screenCenter()
		self:add(self.optionsUI)
		return false
	end},
	donate = {false, function(self)
		love.system.openURL('https://ninja-muffin24.itch.io/funkin')
		self.menuList.lock = false
		return true
	end}
}

function MainMenuState:onSettingChange(setting, option)
	if setting == "gameplay" and option == "menuMusicVolume" then
		game.sound.music:fade(1, game.sound.music.volume, ClientPrefs.data.menuMusicVolume / 100)
	end
end

function MainMenuState:openEditorMenu()
	self.selectedSomethin = true
	self.editorUI = self.editorUI or EditorMenu(function()
		self.selectedSomethin = false
	end)
	self.editorUI.scrollFactor:set()
	self.editorUI:screenCenter()
	self:add(self.editorUI)
end

function MainMenuState:enterSelection(choice)
	local switch = (self.triggerChoices and self.triggerChoices[choice]) or MainMenuState.triggerChoices[choice]
	if not switch then
		local event = self.script and self.script:call("onSelectItem", choice) or nil
		if self.menuList and not self.optionsUI then
			self.menuList.lock = false
		end
		if event ~= Script.Event_Cancel then
			self.selectedSomethin = false
		end
		return
	end
	self.selectedSomethin = true

	game.sound.play(paths.getSound('confirmMenu'))
	local flicker = Flicker(self.menuBg, switch[1] and 1.1 or 1, 0.15, true)
	local magenta = false
	flicker.onFlicker = function()
		magenta = not magenta
		self.menuBg:loadTexture(magenta and self.menuMagenta or self.menuYellow)
	end
	flicker.completionCallback = function()
		self.menuBg:loadTexture(self.menuYellow)
	end

	local selectedItem = self.menuList.members[self.menuList.curSelected]
	Flicker(selectedItem, 1, 0.05, not switch[1], false, function()
		local stayUnlocked = switch[2](self)
		if stayUnlocked and self.menuList and not self.optionsUI then
			self.menuList.lock = false
		end
		self.selectedSomethin = not stayUnlocked
	end)
	for _, spr in ipairs(self.menuList.members) do
		if switch[1] and self.menuList.curSelected ~= spr.ID then
			Tween.tween(spr, {alpha = 0}, 0.4, {
				ease = "quadOut",
				onComplete = function()
					spr:destroy()
				end
			})
		end
	end
end

function MainMenuState:leave()
	self.script:call("leave")
	if self.throttles then
		for _, v in pairs(self.throttles) do v:destroy() end
		self.throttles = nil
	end
	self.script:call("postLeave")
	self.script:close()
end

return MainMenuState

---@class UITabMenu:SpriteGroup
local UITabMenu = SpriteGroup:extend("UITabMenu")

function UITabMenu:new(x, y, tabs)
	UITabMenu.super.new(self, x, y)

	self.tabs = tabs or {}
	self.groups = {}
	self.selected = 1
	self.width, self.height = 1, 1
end

function UITabMenu:addGroup(group)
	table.insert(self.groups, group)
	return self:add(group)
end

return UITabMenu

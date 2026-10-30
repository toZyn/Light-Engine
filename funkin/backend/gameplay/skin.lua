local function loadAsset(type, p)
	local obj
	switch(type, {
		["image"] = function() obj = paths.getImage(p) end,
		["atlas"] = function() obj = paths.getAtlas(p) end,
		["sound"] = function() obj = paths.getSound(p) end
	})
	return obj
end

local Skin = Basic:extend("Skin")

function Skin.resolveName(raw)
	if type(raw) == "table" then
		if type(raw.skin) == "string" and raw.skin ~= "" then
			return raw.skin
		elseif type(raw.name) == "string" and raw.name ~= "" then
			return raw.name
		elseif type(raw.data) == "table" and type(raw.data.skin) == "string" and raw.data.skin ~= "" then
			return raw.data.skin
		end
		return "default"
	elseif type(raw) == "string" and raw ~= "" then
		return raw
	end
	return "default"
end

function Skin:new(name)
	name = Skin.resolveName(name)
	local s, d = pcall(paths.getJSON, "data/skins/" .. name)

	if s and d ~= nil then
		self.data = d
		self.data.skin = self.data.skin or name
	else
		self.data = paths.getJSON("data/skins/default" ..
			(name:endsWith("-pixel") and "-pixel" or ""))
		self.data.skin = name:endsWith("-pixel") and "default-pixel" or "default"
	end
	self.skin = self.data.skin
	self.isPixel = self.skin:endsWith("-pixel")
end

function Skin:get(asset, type)
	type = type or "image"
	return loadAsset(type, self:getPath(asset, type))
end

function Skin:getPath(asset, type)
	type = type or "image"

	local function buildFullPath(skin)
		local path, full = "skins/" .. skin .. "/" .. asset
		switch(type, {
			[{"image", "atlas"}] = function() full = "images/" .. path .. ".png" end,
			["sound"] = function() full = "sounds/" .. path .. ".ogg" end
		})
		if full and paths.exists(paths.getPath(full), "file") then
			return path
		end
	end

	local path = buildFullPath(self.skin)
	if not path and self.isPixel and self.skin ~= "default-pixel" then
		path = buildFullPath("default-pixel")
	end
	if not path then path = buildFullPath("default") end
	return path or ("skins/default/" .. asset)
end

return Skin

local ModdingUtil = {}

local decodeJSON = (loxreq "lib.json").decode

local function createMeta(name)
	return {
		name = name or "Unknown",
		color = "#1F1F1F",
		description = "No description provided.",
		version = 1
	}
end

local function normalizeMeta(raw, fallbackName)
	local defaults = createMeta(fallbackName)
	if type(raw) ~= "table" then return defaults end

	local meta = table.clone(raw)
	if type(meta.name) ~= "string" or meta.name == "" then
		meta.name = defaults.name
	end
	if type(meta.description) ~= "string" then
		meta.description = defaults.description
	end
	if meta.version == nil then
		meta.version = defaults.version
	end

	-- Support hex strings ("#FF00AA", "0xFF00AA") and RGB arrays ({255, 0, 170})
	if type(meta.color) == "table" then
		meta.color = Color.toHexString(meta.color)
	elseif type(meta.color) ~= "string" or meta.color == "" then
		meta.color = defaults.color
	end

	return meta
end

local function getImage(path)
	local obj = paths.images[path]
	if obj then return obj end

	if paths.exists(path, "file") then
		obj = love.graphics.newImage(path)
		paths.images[path] = obj
		return obj
	end
end

function ModdingUtil.getBanner(root, name)
	local obj = getImage(root .. "/" .. name .. "/banner.png")
	if obj then return obj end
	return paths.getImage("menus/modding/banner")
end

function ModdingUtil.getIcon(root, name)
	local obj = getImage(root .. "/" .. name .. "/icon.png")
		or getImage(root .. "/" .. name .. "/pack.png")
	if obj then return obj end
	return paths.getImage("menus/modding/icon")
end

function ModdingUtil.getMeta(root, name)
	local onErr = function(r)
		r = tostring(r):gsub("^.-:%d+: ERROR: ", "")
		Logger.log("error", tostring(name) .. "'s JSON metadata returned an error: " .. r)
	end

	if paths.exists(root, "directory") then
		for _, filename in ipairs({"meta.json", "pack.json"}) do
			local path = root .. "/" .. name .. "/" .. filename
			if paths.exists(path, "file") then
				local content = love.filesystem.read(path)
				if content then
					local s, r = xpcall(decodeJSON, onErr, content)
					if s and type(r) == "table" then
						return normalizeMeta(r, name)
					end
				end
				return createMeta(name)
			end
		end
	end
	return createMeta(name)
end

return ModdingUtil

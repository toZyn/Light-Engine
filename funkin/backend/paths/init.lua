local decodeJson = (loxreq "lib.json").decode
local parseXml = loxreq "lib.xml"

local FrameCollection = loxreq "animation.frame.collection"
local AnimateLibrary = require "funkin.backend.animatelibrary"

local paths = {
	async = require "funkin.backend.paths.async",

	images = {},
	audio = {},
	audioPaths = setmetatable({}, {__mode = "k"}),
	atlases = {},
	fonts = {},
	skins = {},
	animate_atlases = {},
	persistantAssets = {"music/freakyMenu.ogg"}
}

local audioAliases = {
	["music/gameOverend-pixel.ogg"] =
		"music/gameOverEnd-pixel.ogg",
	["songs/bopeebo/Voices-pico-playable-pico.ogg"] =
		"songs/bopeebo/Voices-pico-pico.ogg",
	["songs/cocoa/Voices-bf-christmas-erect.ogg"] =
		"songs/cocoa/Voices-bf-erect.ogg",
	["songs/south/Voices-pico-playable-pico.ogg"] =
		"songs/south/Voices-pico-pico.ogg"
}

local ktx = {"ETC1", "ETC2rgb", "ETC2rgba", "ETC2rgba1", "EACr", "EACrs", "EACrg", "EACrgs"}
local dds = {"DXT1", "DXT3", "DXT5", "BC4", "BC4s", "BC5", "BC5s", "BC6h", "BC6hs", "BC7"}
local astc = {"ASTC4x4", "ASTC5x4", "ASTC5x5", "ASTC6x5", "ASTC6x6", "ASTC8x5", "ASTC8x6", "ASTC8x8",
			  "ASTC10x5", "ASTC10x6", "ASTC10x8", "ASTC10x10", "ASTC12x10", "ASTC12x12"}

local function initCompressedSupport()
	local supported = love.graphics.getImageFormats()
	local hasKTX, hasDDS, hasASTC

	for _, format in ipairs(ktx) do
		if supported[format] then hasKTX = true; break end
	end
	for _, format in ipairs(dds) do
		if supported[format] then hasDDS = true; break end
	end
	for _, format in ipairs(astc) do
		if supported[format] then hasASTC = true; break end
	end

	paths.compressedSupport = {ktx = hasKTX, dds = hasDDS, astc = hasASTC}
end

local function readFile(key)
	if paths.exists(key, "file") then return love.filesystem.read(key) end
	return nil
end

local function getSavesRoot()
	if Storage and Storage.getContentRoot then
		return Storage.getContentRoot("saves")
	end
	return "saves"
end

local function excludeAssets(path)
	local i, n = path:find("assets/")
	if i == 1 then
		return path:sub(n + 1)
	end

	for _, root in ipairs({getSavesRoot(), "saves", Mods.root, Addons.root}) do
		if root and root ~= "" then
			local prefix = root .. "/"
			if path:sub(1, #prefix) == prefix then return path:sub(#prefix + 1) end
		end
	end

	return path
end

paths.excludeAssets = excludeAssets

local function insertFile(path, file, type, tbl)
	local info = love.filesystem.getInfo(path)
	if info and (type == "any" or info.type == type:lower()) then
		table.insert(tbl, file)
	end
end

local function generate(cache, key, createFunc, error, path)
	local obj = cache[key]
	if obj then return obj end

	local exists = paths.exists(key, path and "directory" or "file")
	obj = createFunc(exists)
	if obj then cache[key] = obj; return obj end
	if error then Logger.log("debug", "[ PATHS ] " .. error .. ' returned a null value: ' .. key, 4) end
	return nil
end

function paths.addPersistant(path)
	path = excludeAssets(path)
	if not table.find(paths.persistantAssets, path) then
		table.insert(paths.persistantAssets, path)
	end
end

function paths.isPersistant(path)
	path = excludeAssets(path)
	for _, k in pairs(paths.persistantAssets) do
		if path:startsWith(k) then return true end
	end
	return false
end

local function clear(tbl)
	for k, o in pairs(tbl) do
		if not paths.isPersistant(k) then
			if o.release then o:release() end
			if o.destroy then o:destroy() end
			tbl[k] = nil
		end
	end
end

function paths.clearCache()
	-- Cancel callbacks/results before releasing their possible cache targets.
	paths.async.stop()
	clear(paths.atlases)
	clear(paths.animate_atlases)
	clear(paths.images)
	clear(paths.audio)
	clear(paths.fonts)
	clear(paths.skins)
	collectgarbage()
end

function paths.getMods(key)
	local root = Mods.root .. "/"
	if Mods.currentMod then
		return root .. Mods.currentMod .. "/" .. key
	end
	return "_"
end

function paths.getSaves(key)
	local root = getSavesRoot() .. "/"
	if key and key ~= "" then return root .. key end
	return root
end

function paths.getPath(key, allowMods, allowAddons, allowSaves)
	if allowMods == nil then allowMods = true end
	if allowAddons == nil then allowAddons = true end
	if allowSaves == nil then allowSaves = allowMods end

	if allowSaves then
		local savePath = getSavesRoot() .. "/" .. key
		if paths.exists(savePath) then return savePath end
	end
	if allowMods and Mods and Mods.currentMod then
		local modPath = Mods.root .. "/" .. Mods.currentMod .. "/" .. key
		if paths.exists(modPath) then return modPath end
	end
	if allowAddons and Addons and Addons.all then
		for _, addon in ipairs(Addons.all) do
			if addon.active then
				local addonPath = Addons.root .. "/" .. addon.path .. "/" .. key
				if paths.exists(addonPath) then return addonPath end
			end
		end
	end
	return "assets/" .. key
end

function paths.getItems(key, type, extension, excludeMods, excludeAddons, excludeAssets)
	type = type or "any"
	local files, seen, getItems = {}, {}, love.filesystem.getDirectoryItems

	local savesDir = getSavesRoot() .. "/" .. key .. "/"
	if not excludeMods and paths.exists(savesDir, "directory") then
		for _, v in ipairs(getItems(savesDir)) do
			if not seen[v] and (not extension or v:ext() == extension) then
				local before = #files
				insertFile(savesDir .. v, v, type, files)
				if #files > before then seen[v] = true end
			end
		end
	end

	if not excludeAddons and Addons and Addons.all then
		for _, addon in ipairs(Addons.all) do
			local addonPath = Addons.root .. "/" .. addon.path .. "/" .. key .. "/"
			if addon.active and paths.exists(addonPath, "directory") then
				for _, v in ipairs(getItems(addonPath)) do
					if not seen[v] and (not extension or v:ext() == extension) then
						local before = #files
						insertFile(addonPath .. v, v, type, files)
						if #files > before then seen[v] = true end
					end
				end
			end
		end
	end

	local mods, base = paths.getMods(key) .. "/", paths.getPath(key, false, false) .. "/"
	local hasMods = not excludeMods and Mods and Mods.currentMod and paths.exists(mods, "directory")
	local hasBase = not excludeAssets and paths.exists(base, "directory")
	if hasMods then
		for _, v in ipairs(getItems(mods)) do
			if not seen[v] and (not extension or v:ext() == extension) then
				local before = #files
				insertFile(mods .. v, v, type, files)
				if #files > before then seen[v] = true end
			end
		end
	end
	if hasBase then
		for _, v in ipairs(getItems(base)) do
			if not seen[v] and (not extension or v:ext() == extension) then
				local before = #files
				insertFile(base .. v, v, type, files)
				if #files > before then seen[v] = true end
			end
		end
	end

	return files
end

function paths.exists(path, type)
	local info = love.filesystem.getInfo(path)
	return info ~= nil and (not type or info.type == type:lower())
end

function paths.getText(key)
	local path = paths.getPath("data/" .. key .. ".txt")
	return readFile(path), path
end

function paths.getJSON(key)
	local path = paths.getPath(key .. ".json")
	local data = readFile(path)
	if data then
		local s, r = pcall(decodeJson, data)
		if not s then
			local err = r:gsub("^.-:%d+: ERROR: ", "")
			error(path .. ": " .. err)
			return
		end
		return r, path
	end
	return nil, path
end

function paths.getXML(key)
	local path = paths.getPath(key .. ".xml")
	local data = readFile(path)
	if data then
		return parseXml(data)
	end
	return nil
end

function paths.getSkin(key)
	if type(key) == "table" and type(key.getPath) == "function" and type(key.get) == "function" then
		return key
	end
	local resolvedName = (Skin and Skin.resolveName and Skin.resolveName(key))
		or (type(key) == "string" and key ~= "" and key)
		or "default"
	return generate(paths.skins, resolvedName, function() return Skin(resolvedName) end, "skin")
end

function paths.getFont(key, size, logError)
	size = size or 12
	local path = paths.getPath("fonts/" .. key)
	local pkey = path .. "_" .. size
	return generate(paths.fonts, pkey, function()
		if paths.exists(path, "file") then
			return love.graphics.newFont(path, size, "light")
		end
	end, not logError and "font" or nil)
end

function paths.getImage(key)
	if not paths.compressedSupport then initCompressedSupport() end
	local basePath = "images/" .. key .. "."
	local path

	if paths.compressedSupport.astc then
		path = paths.getPath(basePath .. "astc")
		if paths.images[path] or paths.exists(path, "file") then
			return generate(paths.images, path, function()
				return love.graphics.newImage(path)
			end, "image")
		end
	end

	if paths.compressedSupport.ktx then
		path = paths.getPath(basePath .. "ktx")
		if paths.images[path] or paths.exists(path, "file") then
			return generate(paths.images, path, function()
				return love.graphics.newImage(path)
			end, "image")
		end
	end

	if paths.compressedSupport.dds then
		path = paths.getPath(basePath .. "dds")
		if paths.images[path] or paths.exists(path, "file") then
			return generate(paths.images, path, function()
				return love.graphics.newImage(path)
			end, "image")
		end
	end

	path = paths.getPath(basePath .. "png")
	return generate(paths.images, path, function(exists)
		if exists then
			return love.graphics.newImage(path)
		end
	end, "image")
end

function paths.getAnimateAtlas(key)
	local path = paths.getPath("images/" .. key)
	return generate(paths.animate_atlases, path, function(y)
		if y then
			local lib = AnimateLibrary(path)
			lib:load()
			return lib
		end
	end, "animate atlas", true)
end

function paths.getAudio(key, stream, logError)
	local path = paths.getPath(key .. ".ogg")
	if not paths.audio[path] and not paths.exists(path, "file") then
		local alias = audioAliases[key .. ".ogg"] or audioAliases[key]
		if alias then
			local aliasClean = alias:gsub("%.ogg$", "")
			path = paths.getPath(aliasClean .. ".ogg")
		else
			for _, ext in ipairs({".wav", ".mp3"}) do
				local alt = paths.getPath(key .. ext)
				if paths.audio[alt] or paths.exists(alt, "file") then
					path = alt
					break
				end
			end
		end
	end
	local cacheKey = path .. (stream and ":stream" or ":static")
	local cached = paths.audio[path] or paths.audio[cacheKey]
	if cached then
		paths.audioPaths[cached] = path
		return cached
	end
	local created = generate(paths.audio, path, function(y)
		if y then return stream and love.audio.newSource(path, "stream") or
			love.sound.newSoundData(path) end
	end, not logError and "audio" or nil)
	if created then paths.audioPaths[created] = path end
	return created
end

function paths.getMusic(key) return paths.getAudio("music/" .. key, true) end

function paths.getSound(key) return paths.getAudio("sounds/" .. key, false) end

function paths.getInst(song, suffix, logError)
	return paths.getAudio("songs/"
		.. paths.formatToSongPath(song)
		.. "/Inst" .. (suffix and "-" .. suffix or ""), true, logError)
end

function paths.getVoices(song, suffix, logError)
	return paths.getAudio("songs/"
		.. paths.formatToSongPath(song)
		.. "/Voices" .. (suffix and "-" .. suffix or ""), true, logError)
end

function paths.getSparrowAtlas(key)
	local imgPath, xmlPath = key, paths.getPath("images/" .. key .. ".xml")
	local atlasPath = xmlPath:gsub("%.xml$", "")

	return generate(paths.atlases, atlasPath, function()
		local img = paths.getImage(imgPath)
		if img and paths.exists(xmlPath, "file") then
			return FrameCollection.fromSparrow(img, readFile(xmlPath))
		end
		return nil
	end)
end

function paths.getPackerAtlas(key)
	local imgPath, txtPath = key, paths.getPath("images/" .. key .. ".txt")
	local atlasPath = txtPath:gsub("%.txt$", "")

	return generate(paths.atlases, atlasPath, function()
		local img = paths.getImage(imgPath)
		if img and paths.exists(txtPath, "file") then
			return FrameCollection.fromPacker(img, readFile(txtPath))
		end
		return nil
	end)
end

function paths.getAtlas(key)
	if paths.exists(paths.getPath("images/" .. key .. ".xml"), "file") then
		return paths.getSparrowAtlas(key)
	end
	return paths.getPackerAtlas(key)
end

function paths.getLua(key)
	local path = paths.getPath(key .. ".lua")
	if paths.exists(path, "file") then return love.filesystem.load(path) end
end

local invalidChars = '[~&\\;:<>#]'
local hideChars = '[.,\'"%?!]'
function paths.formatToSongPath(path)
	return string.lower(string.gsub(string.gsub(path:gsub(" ", "-"),
			invalidChars, "-"), hideChars,
		""))
end

function paths.update(dt) paths.async.update(dt) end

return paths

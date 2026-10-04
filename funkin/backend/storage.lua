local lfs = love.filesystem
local packageName = Project.package or "com.zyn.lightengine"

local Storage = {
	available = false,
	mounted = false,
	initialized = false,
	mountPoint = "external",
	root = nil,
	savePath = nil,
	watchInterval = 0.75
}

local watchedDirectories = {}

local function addCandidate(candidates, path)
	if path and path ~= "" and not table.find(candidates, path) then
		table.insert(candidates, path)
	end
end

local function createDirectory(path)
	if love.system.getOS() == "Windows" then
		os.execute('mkdir "' .. path .. '" 2>nul')
	else
		os.execute('mkdir -p "' .. path .. '" 2>/dev/null')
	end
end

local function canWrite(path)
	createDirectory(path)
	local testPath = path .. "/.fnf-love-write-test"
	local file = io.open(testPath, "wb")
	if not file then return false end

	file:close()
	os.remove(testPath)
	return true
end

local function getAndroidCandidates()
	local candidates = {}
	local externalStorage = os.getenv("EXTERNAL_STORAGE")
	local relativePath = "/Android/media/" .. packageName

	addCandidate(candidates, externalStorage and externalStorage .. relativePath)
	addCandidate(candidates, "/sdcard" .. relativePath)
	addCandidate(candidates, "/storage/emulated/0" .. relativePath)

	return candidates
end

local function getDesktopCandidates()
	local candidates = {}
	local baseDir

	if love.system.getOS() == "Windows" then
		baseDir = os.getenv("APPDATA")
	else
		baseDir = os.getenv("HOME")
	end

	if baseDir then
		local company = Project.company or "Zyn"
		local file = Project.file or "Light Engine"
		local fullPath = baseDir .. "/" .. company .. "/" .. file
		addCandidate(candidates, fullPath)
	end

	return candidates
end

local function tryMount()
	if not Storage.available or Storage.mounted then return Storage.mounted end

	local mounted = lfs.mount(Storage.root, Storage.mountPoint)
	local mods = lfs.getInfo(Storage.mountPoint .. "/mods")
	local addons = lfs.getInfo(Storage.mountPoint .. "/addons")

	Storage.mounted = mounted and mods and mods.type == "directory"
		and addons and addons.type == "directory" or false
	return Storage.mounted
end

local function createDesktopDirs(path)
	if love.system.getOS() == "Windows" then
		os.execute('mkdir "' .. path .. '\\mods"')
		os.execute('mkdir "' .. path .. '\\addons"')
		os.execute('mkdir "' .. path .. '\\saves"')
	else
		os.execute('mkdir -p "' .. path .. '/mods"')
		os.execute('mkdir -p "' .. path .. '/addons"')
		os.execute('mkdir -p "' .. path .. '/saves"')
	end
end

local function excludeAndroidMedia(root)
	-- Android's media scanner honours this marker for the entire app folder.
	-- Append mode creates it without truncating an existing user-owned file.
	local ok, success, message = pcall(function()
		local file, openError = io.open(root .. "/.nomedia", "ab")
		if not file then return false, openError end
		return file:close()
	end)
	if not ok or not success then
		print("[Storage] Could not create .nomedia: " .. tostring(ok and message or success))
	end
end

function Storage.init()
	if Storage.initialized then return end
	Storage.initialized = true

	local candidates = {}
	if love.system.getOS() == "Android" then
		candidates = getAndroidCandidates()
	else
		candidates = getDesktopCandidates()
	end

	for _, root in ipairs(candidates) do
		if love.system.getOS() == "Android" then
			createDirectory(root)
			excludeAndroidMedia(root)
		end

		local modsPath = root .. "/mods"
		local addonsPath = root .. "/addons"
		local savesPath = root .. "/saves"
		
		if canWrite(modsPath) and canWrite(addonsPath) and canWrite(savesPath) then
			Storage.available = true
			Storage.root = root
			Storage.savePath = savesPath
			break
		elseif love.system.getOS() ~= "Android" then
			-- On desktop, create directories if they don't exist
			createDesktopDirs(root)
			if canWrite(modsPath) and canWrite(addonsPath) and canWrite(savesPath) then
				Storage.available = true
				Storage.root = root
				Storage.savePath = savesPath
				break
			end
		end
	end

	if not Storage.available then
		if love.system.getOS() == "Android" then
			print("[Storage] Android/media is unavailable; external mods and add-ons are disabled.")
		else
			print("[Storage] Could not set up external storage; mods and add-ons will use internal storage.")
		end
		return
	end

	if not tryMount() then
		print("[Storage] External storage is writable but could not be mounted.")
	end
end

local function pathSignature(path, kind)
	if kind == "file" then
		local info = lfs.getInfo(path)
		if not info then return "" end
		return table.concat({info.modtime or 0, info.size or 0}, ":")
	elseif kind == "root" then
		return tostring(lfs.getLastModified(path) or 0)
	end

	local success, items = pcall(lfs.getDirectoryItems, path)
	if not success then return "" end
	table.sort(items)

	local parts = {}
	for _, item in ipairs(items) do
		local child = path .. "/" .. item
		local info = lfs.getInfo(child)
		if info then
			parts[#parts + 1] = table.concat({
				item, info.type, info.modtime or 0
			}, ":")
		end
	end

	return table.concat(parts, "|")
end

local function addWatch(path, kind, name)
	for _, watch in ipairs(watchedDirectories) do
		if watch.path == path then return end
	end
	table.insert(watchedDirectories, {path = path, kind = kind, name = name})
end

function Storage.refreshWatchList()
	if not Storage.mounted then return end

	table.clear(watchedDirectories)
	addWatch(Storage.mountPoint .. "/mods", "root", "mods")
	addWatch(Storage.mountPoint .. "/addons", "root", "addons")
	addWatch(Storage.mountPoint .. "/saves/funkin.lox", "file", "funkin")

	if Mods and Mods.currentMod then
		addWatch(Storage.mountPoint .. "/mods/" .. Mods.currentMod, "tree", Mods.currentMod)
	end

	if Addons then
		for _, addon in ipairs(Addons.all) do
			if addon.active then
				addWatch(Storage.mountPoint .. "/addons/" .. addon.path, "tree", addon.path)
			end
		end
	end
end

local function inspectWatchedDirectories()
	local changed, contentChanged, saveChanged = false, false, false
	for _, watch in ipairs(watchedDirectories) do
		local signature = pathSignature(watch.path, watch.kind)
		if watch.signature == nil then
			watch.signature = signature
		elseif watch.signature ~= signature then
			watch.signature = signature
			changed = true
			if watch.kind == "file" and watch.name == "funkin" then
				saveChanged = true
			elseif watch.kind == "tree" then
				contentChanged = true
			end
		end
	end

	return changed, contentChanged, saveChanged
end

local watchTime = 0

local function clearContentCache()
	local state = game and game.getState and game.getState()
	if state and PlayState and state:is(PlayState) then return false end

	paths.clearCache()
	if Shader then Shader.clear() end
	return true
end

function Storage.refreshNow(clearCache)
	if not Storage.mounted and not tryMount() then return false end

	if Mods then Mods.reload() end
	if Addons then Addons.reload() end
	if clearCache ~= false then clearContentCache() end

	Storage.refreshWatchList()
	inspectWatchedDirectories()
	return true
end

function Storage.update(dt)
	watchTime = watchTime + dt
	if not Storage.mounted then
		if Storage.available and watchTime >= 2 then
			watchTime = 0
			if tryMount() then
				Storage.refreshNow(false)
			end
		end
		return
	end

	if watchTime < Storage.watchInterval then return end
	watchTime = 0

	local changed, contentChanged, saveChanged = inspectWatchedDirectories()
	if not changed then return end

	if saveChanged and Storage.reloadSave then Storage.reloadSave("funkin") end
	if Mods then Mods.reload() end
	if Addons then Addons.reload() end
	if contentChanged then clearContentCache() end

	Storage.refreshWatchList()
	inspectWatchedDirectories()
end

function Storage.getContentRoot(name)
	if Storage.mounted then return Storage.mountPoint .. "/" .. name end
	return name
end

function Storage.installSave(save)
	if save.externalStorageInstalled then return end
	save.externalStorageInstalled = true

	local json = loxreq "lib.json"
	local originalInit, originalBind = save.init, save.bind

	local function showCorruptSave()
		if Timer and Toast then
			Timer.wait(0.1, function() Toast.error("Save file is corrupt!") end)
		end
	end

	local function readExternalSave(name)
		local file = io.open(Storage.savePath .. "/" .. name .. ".lox", "rb")
		if not file then return end

		local encoded = file:read("a")
		file:close()

		local decodeSuccess, decoded = pcall(love.data.decode, "string", "hex", encoded)
		if not decodeSuccess then
			showCorruptSave()
			return
		end

		local success, data = pcall(json.decode, decoded)
		if not success or type(data) ~= "table" then
			showCorruptSave()
			return
		end

		return data
	end

	Storage.reloadSave = function(name)
		local data = readExternalSave(name)
		if not data then return false end

		save.data = data
		if ClientPrefs then
			pcall(table.merge, ClientPrefs.data, data.prefs)
			pcall(table.merge, ClientPrefs.controls, data.controls)
			if controls then controls:reset({controls = table.clone(ClientPrefs.controls)}) end
		end
		if Highscore then Highscore.scores = data.scores or {songs = {}, weeks = {}} end

		return true
	end

	Storage.noteSaveWrite = function(name)
		if not Storage.mounted then return end
		Storage.refreshWatchList()
		for _, watch in ipairs(watchedDirectories) do
			if watch.kind == "file" and watch.name == name then
				watch.signature = pathSignature(watch.path, watch.kind)
			end
		end
	end

	save.init = function(name)
		if not Storage.available then return originalInit(name) end
		if save.initialized then return end

		save.initialized = true
		save.path = Storage.savePath

		local data = readExternalSave(name)
		if data then save.data = data end
	end

	save.bind = function(name)
		if not Storage.available then return originalBind(name) end

		local encoded = love.data.encode("string", "hex", json.encode(save.data))
		local filePath = Storage.savePath .. "/" .. name .. ".lox"
		local function failed(message)
			local text = "[Storage] Could not write save file " .. filePath .. ": " .. tostring(message or "unknown write failure")
			local ok, reporter = pcall(require, "funkin.backend.recoverable-errors")
			local reported = ok and type(reporter.report) == "function" and
				pcall(reporter.report, text, debug.traceback("", 2), {source = "external-save"})
			if not reported then pcall(Logger and Logger.print or print, text) end
			return originalBind(name)
		end
		local file, err = io.open(filePath, "wb")
		if not file then return failed(err) end

		local success, result, writeError = pcall(file.write, file, encoded)
		local closed, closeResult, closeError = pcall(file.close, file)
		if not success then return failed(result) end
		if not result then return failed(writeError) end
		if not closed then return failed(closeResult) end
		if not closeResult then return failed(closeError) end

		Storage.noteSaveWrite(name)
		return true
	end
end

return Storage

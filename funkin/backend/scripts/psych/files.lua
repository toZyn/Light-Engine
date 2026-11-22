local Files = {}
local mountSerial = 0

local function absolute(path)
	return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil
end

local function hostPath(path)
	if absolute(path) then return path end
	local base = love.filesystem.getRealDirectory(path)
	local parent = path:match("^(.*)/[^/]*$")
	if not base and parent then base = love.filesystem.getRealDirectory(parent) end
	base = base or love.filesystem.getSource()
	if love.filesystem.getInfo(path) and base:match("%.love$") then return nil end
	return base .. "/" .. path
end

local function nativeDirectory(folder, action)
	for _, root in ipairs({love.filesystem.getSaveDirectory(), love.filesystem.getSource()}) do
		if folder == root then return action("") end
		if folder:sub(1, #root + 1) == root .. "/" then return action(folder:sub(#root + 2)) end
	end
	mountSerial = mountSerial + 1
	local point = "__psychDirectory" .. mountSerial
	if not love.filesystem.mount(folder, point, false) then return nil end
	local ok, result = pcall(action, point)
	love.filesystem.unmount(folder)
	if ok then return result end
end

local function info(path)
	if not absolute(path) then return love.filesystem.getInfo(path) end
	local folder, name = path:match("^(.*)[/\\]([^/\\]+)$")
	if folder then return nativeDirectory(folder, function(point) return love.filesystem.getInfo(point .. "/" .. name) end) end
end

function Files.install(compat, api)
	api.checkFileExists = function(filename, isAbsolute)
		compat:_active()
		return info(isAbsolute and filename or paths.getPath(filename, true, false)) ~= nil
	end
	api.getTextFromFile = function(path, ignoreMods)
		compat:_active()
		local resolved = paths.getPath(path, not ignoreMods, false)
		local host = hostPath(resolved)
		local file = host and io.open(host, "rb")
		if not file then
			local value = love.filesystem.read(resolved)
			return value
		end
		local value = file:read("*a")
		file:close()
		return value
	end
	api.saveFile = function(path, content, isAbsolute)
		compat:_active()
		local target = hostPath(isAbsolute and path or Mods.root .. "/" .. path)
		local file = target and io.open(target, "wb")
		if not file then return false end
		local ok, result = pcall(file.write, file, content)
		local closed = file:close()
		return ok and result ~= nil and closed ~= nil
	end
	api.deleteFile = function(path, ignoreMods, isAbsolute)
		compat:_active()
		local target = hostPath(isAbsolute and path or paths.getPath(path, not ignoreMods, false))
		return target ~= nil and info(target) ~= nil and info(target).type == "file" and os.remove(target) == true
	end
	api.directoryFileList = function(folder)
		compat:_active()
		local host = hostPath(folder)
		if not host then return {} end
		return nativeDirectory(host, love.filesystem.getDirectoryItems) or {}
	end
end

return Files

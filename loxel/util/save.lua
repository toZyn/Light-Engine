local json = loxreq("lib.json")

local Save = {
	data = {},
	path = '',
	initialized = false
}

local function reportIssue(message)
	local ok, reporter = pcall(require, "funkin.backend.recoverable-errors")
	local reported = ok and type(reporter.report) == "function" and
		pcall(reporter.report, message, debug.traceback("", 2), {source = "save"})
	if not reported then pcall(Logger and Logger.print or print, message) end
end

function Save.init(name)
	if Save.initialized then return end
	Save.initialized = true

	local encoded, filePath
	local function corrupt(message)
		reportIssue("[Save] Could not load save file " .. filePath .. ": " .. tostring(message))
	end
	if love.system.getDevice() == "Mobile" then
		Save.path = love.filesystem.getSaveDirectory()
		filePath = Save.path .. '/' .. name .. '.lox'
		local ok, data = pcall(love.filesystem.read, name .. '.lox')
		if not ok then corrupt(data); return end
		encoded = data
	else
		Save.path = love.filesystem.getAppdataDirectory() .. '/' .. Project.company .. '/' .. Project.file
		filePath = Save.path .. '/' .. name .. '.lox'
		local dataFile = io.open(filePath, "rb")
		if not dataFile then return end
		-- Close before decoding; corrupt data must not leak the reader.
		local ok, data, readError = pcall(dataFile.read, dataFile, "a")
		local closed, closeResult, closeError = pcall(dataFile.close, dataFile)
		if not ok then corrupt(data); return end
		if not data then corrupt(readError or "read failed"); return end
		if not closed then corrupt(closeResult); return end
		if not closeResult then corrupt(closeError or "close failed"); return end
		encoded = data
	end
	if not encoded then return end
	local decoded, data = pcall(love.data.decode, "string", "hex", encoded)
	if not decoded then corrupt(data); return end
	local valid, contents = pcall(json.decode, data)
	if not valid then corrupt(contents); return end
	if type(contents) ~= "table" then corrupt("save contents must be a JSON table"); return end
	Save.data = contents
end

function Save.bind(name)
	local encodeData = love.data.encode("string", "hex", json.encode(Save.data))
	local function failed(message)
		message = tostring(message or "unknown write failure")
		local directory = love.system.getDevice() == "Mobile" and love.filesystem.getSaveDirectory() or Save.path
		local filePath = directory .. '/' .. name .. '.lox'
		local text = "[Save] Could not write save file " .. filePath .. ": " .. message
		-- This I/O boundary already returns failure and preserves live data.
		-- Reporting must not turn that known nonfatal result into an exception.
		reportIssue(text)
		return false, message
	end
	if love.system.getDevice() == "Mobile" then
		local ok, result, message = pcall(love.filesystem.write, name .. '.lox', encodeData)
		if not ok then return failed(result) end
		if not result then return failed(message) end
		return true
	else
		local filePath = Save.path .. '/' .. name .. '.lox'
		local saveFile, openError = io.open(filePath, "wb")
		if not saveFile then
			local dirToMake = filePath:gsub('/' .. name .. '.lox', '')
			if love.system.getOS() == "Windows" then
				os.execute('mkdir "' .. dirToMake .. '"')
			else
				os.execute('mkdir -p "' .. dirToMake .. '"')
			end
			saveFile, openError = io.open(filePath, "wb")
		end
		if not saveFile then return failed(openError) end
		local ok, result, writeError = pcall(saveFile.write, saveFile, encodeData)
		local closed, closeResult, closeError = pcall(saveFile.close, saveFile)
		if not ok then return failed(result) end
		if not result then return failed(writeError) end
		if not closed then return failed(closeResult) end
		if not closeResult then return failed(closeError) end
		return true
	end
end

return Save

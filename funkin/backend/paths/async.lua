local async = {debug = true}
local mobile = love.system.getDevice and love.system.getDevice() == 'Mobile' or love.system.getOS() == 'Android' or love.system.getOS() == 'iOS'
local MAX_THREADS, MAX_UPLOADS = mobile and 2 or 4, mobile and 1 or 2
local THREAD_TIMEOUT = 10
local code = assert(love.filesystem.read('funkin/backend/paths/thread.lua'))
local queue = {tasks = {}, callbacks = {}}
local active, pending, retired = {}, {}, {}
local generation = 0
local session = tostring(love.timer.getTime()) .. '_' .. tostring({}):gsub('[^%w]', '')
local group
local stats = {queued = 0, completed = 0, failed = 0, lastError = nil}
local lastWork = love.timer.getTime()
local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local function isUrl(path) return path:sub(1, 7) == 'http://' or path:sub(1, 8) == 'https://' end
local function getCachePath(path) return isUrl(path) and ('online:' .. path) or path end
local function log(msg) if async.debug and Logger then Logger.log('warn', msg) end end
local function release(data)
 if type(data) == 'userdata' then pcall(function() data:release() end) end
end
local function failure(kind, path, message, trace)
 return {kind = kind, path = path, message = tostring(message), traceback = trace or '', generation = generation}
end
local function errorText(err)
 return string.format('Async %s failed for %s: %s\n%s', err.kind or 'load', err.path or '?', err.message or '?', err.traceback or '')
end
local function record(err)
 stats.failed, stats.lastError = stats.failed + 1, err
 local text = errorText(err); log(text)
 local diagnostics = package.loaded['funkin.backend.diagnostics']
 if diagnostics then diagnostics.report(text, err.traceback) end
 return text
end
local function newGroup()
 generation = generation + 1
 local prefix = 'async_' .. session .. '_' .. tostring(generation) .. '_'
 group = {generation = generation, threads = {}, tasks = love.thread.getChannel(prefix .. 'tasks'),
  results = love.thread.getChannel(prefix .. 'results'), cancel = love.thread.getChannel(prefix .. 'cancel'), prefix = prefix}
end
newGroup()
local function drain(g)
 while true do local result = g.results:pop(); if not result then break end; if result[1] then release(result[2]) end end
end
local function cleanupRetired()
 local live = 0
 for i = #retired, 1, -1 do
  local g, running = retired[i], false
  drain(g)
  for _, thread in ipairs(g.threads) do if thread:isRunning() then running = true; live = live + 1 end end
  if not running then drain(g); g.tasks:clear(); g.cancel:clear(); table.remove(retired, i) end
 end
 return live
end
local function ensureThreads()
 local retiredLive = cleanupRetired()
 for i = #group.threads, 1, -1 do
  local thread = group.threads[i]
  local err = thread:getError()
  if err then error('Async worker startup/runtime failed: ' .. err, 0) end
  if not thread:isRunning() then table.remove(group.threads, i) end
 end
 local needed = math.min(MAX_THREADS - retiredLive, #queue.tasks + count(active))
 while #group.threads < needed do
  local thread = love.thread.newThread(code)
  group.threads[#group.threads + 1] = thread
  thread:start(group.prefix .. 'tasks', group.prefix .. 'results', group.prefix .. 'cancel')
 end
end
local processors = {
 image = function(data, path) local key = getCachePath(path); local image = paths.images[key] or love.graphics.newImage(data); paths.images[key] = image; return image, isUrl(path) and path or nil end,
 sound = function(data, path) local key = getCachePath(path); local sound = paths.audio[key] or data; paths.audio[key] = sound; return sound, isUrl(path) and path or nil end,
 audio = function(data, path) local key = getCachePath(path); local source = paths.audio[key] or data; paths.audio[key] = source; return source, isUrl(path) and path or nil end,
 text = function(data, path) return data, path end
}
function async.processQueue()
 ensureThreads()
 while #queue.tasks > 0 and count(active) < #group.threads do
  local task = table.remove(queue.tasks, 1)
  active[task[3]] = task
  group.tasks:push(task)
  lastWork = love.timer.getTime()
 end
end
local function callbacks(id, data, err, taskGeneration, path)
 local list = queue.callbacks[id]; queue.callbacks[id] = nil
 if not list then return end
 for _, callback in ipairs(list) do
  -- A callback may change mods/clear cache; remaining callbacks belong to the
  -- cancelled generation and must not receive resources that it just released.
  if taskGeneration ~= generation then return end
  local ok, message = xpcall(function() callback(data, err) end, debug.traceback)
  if not ok then error('Async callback failed for ' .. path .. ': ' .. tostring(message), 0) end
 end
end
function async.update(dt)
 cleanupRetired()
 local processed = 0
 while processed < MAX_UPLOADS do
  local result = group.results:pop(); if not result then break end
  local success, data, id, kind, path, taskGeneration = unpack(result)
  local task = active[id]
  if taskGeneration ~= generation or not task then
   if success then release(data) end
  else
   active[id], pending[id] = nil, nil
   stats.completed = stats.completed + 1
   processed = processed + 1; lastWork = love.timer.getTime()
   local dispatch, err
   if success then
    local ok, output, extra = xpcall(function()
     assert(processors[kind], 'unknown result type ' .. tostring(kind))
     return processors[kind](data, path)
    end, debug.traceback)
    if ok then dispatch, err = output, extra; if output ~= data then release(data) end
    else release(data); err = record(failure('processor', path, output, output)) end
   else
    if type(data) ~= 'table' then data = failure('worker', path, data) end
    err = record(data)
   end
   callbacks(id, dispatch, err, taskGeneration, path)
  end
 end
 async.processQueue()
 if #queue.tasks == 0 and count(active) == 0 and #group.threads > 0 and love.timer.getTime() - lastWork > THREAD_TIMEOUT then async.stop() end
end
function async.queueTask(kind, path, callback)
 local id = kind .. ':' .. path
 if pending[id] then
  if callback then queue.callbacks[id] = queue.callbacks[id] or {}; table.insert(queue.callbacks[id], callback) end
  return id
 end
 if #queue.tasks == 0 and count(active) == 0 then stats.queued, stats.completed, stats.failed, stats.lastError = 0, 0, 0, nil end
 pending[id] = true
 if callback then queue.callbacks[id] = {callback} end
 queue.tasks[#queue.tasks + 1] = {kind, path, id, generation}
 stats.queued = stats.queued + 1
 async.processQueue()
 return id
end

local function findImagePath(key)
	local base = "images/" .. key .. "."
	local formats = {"astc", "ktx", "dds", "png"}
	local support = paths.compressedSupport or {}

	for _, fmt in ipairs(formats) do
		if fmt == "png" or support[fmt] then
			local path = paths.getPath(base .. fmt)
			if paths.exists(path, "file") then
				return path
			end
		end
	end
	return paths.getPath(base .. "png")
end

function async.getImage(key, callback)
	if isUrl(key) then
		local cache = "online:" .. key
		local obj = paths.images[cache]
		if obj then
			if callback then callback(obj, key) end
			return obj
		end
		async.queueTask("image", key, callback)
		return true
	else
		local path = findImagePath(key)
		local obj = paths.images[path]
		if obj then
			if callback then callback(obj) end
			return obj
		end
		if paths.exists(path, "file") then
			async.queueTask("image", path, callback)
			return true
		else
			log('image not found: ' .. key)
			if callback then callback(nil) end
		end
	end
	return nil
end

function async.getAudio(key, stream, callback)
	if isUrl(key) then
		local cache = "online:" .. key
		local obj = paths.audio[cache]
		if obj then
			if callback then callback(obj, key) end
			return obj
		end
		async.queueTask(stream and "audio" or "sound", key, callback)
		return true
	else
		local path = paths.getPath(key .. ".ogg")
		local obj = paths.audio[path]
		if obj then
			if callback then callback(obj) end
			return obj
		end
		if paths.exists(path, "file") then
			async.queueTask(stream and "audio" or "sound", path, callback)
			return true
		else
			log('audio not found: ' .. key)
			if callback then callback(nil) end
		end
	end
	return nil
end

function async.getTextFromURL(url, callback)
	if not isUrl(url) then
		log("Invalid URL: " .. url)
		if callback then callback(nil, "Invalid URL") end
		return nil
	end
	async.queueTask("text", url, callback)
	return true
end

function async.getMusic(key, callback)
	return async.getAudio("music/" .. key, true, callback)
end

function async.getSound(key, callback)
	return async.getAudio("sounds/" .. key, false, callback)
end

function async.getInst(song, suffix, callback)
	return async.getAudio("songs/" .. paths.formatToSongPath(song) .. "/Inst" ..
		(suffix and "-" .. suffix or ""), true, callback)
end

function async.getVoices(song, suffix, callback)
	return async.getAudio("songs/" .. paths.formatToSongPath(song) .. "/Voices" ..
		(suffix and "-" .. suffix or ""), true, callback)
end

local function loadAtlas(key, kind, callback)
	local imgPath = paths.getPath("images/" .. key .. ".png")
	local ext = kind == "sparrow" and ".xml" or ".txt"
	local dataPath = paths.getPath("images/" .. key .. ext)
	local cacheKey = paths.getPath("images/" .. key)
	local obj = paths.atlases[cacheKey]

	if obj then
		if callback then callback(obj) end
		return obj
	end

	if not paths.exists(dataPath, "file") then
		log((kind == "sparrow" and "XML" or "TXT") .. ' file not found for atlas: ' .. key)
		if callback then callback(nil) end
		return nil
	end

	local function processAtlas(img)
		if not img then
			if callback then callback(nil) end; return nil
		end
		local data = love.filesystem.read(dataPath)
		if not data then
			local type = kind == "sparrow" and "XML" or "TXT"
			if async.debug then print('failed to read ' .. type .. ' file: ' .. dataPath) end
			if callback then callback(nil) end
			return nil
		end

		local FrameCollection = loxreq "animation.frame.collection"
		obj = FrameCollection["from" .. kind:capitalize()](img, data)
		paths.atlases[cacheKey] = obj
		if callback then callback(obj) end
		return obj
	end

	local img = paths.images[imgPath]
	if img then
		return processAtlas(img)
	else
		async.getImage(key, processAtlas)
		return true
	end
end

function async.getSparrowAtlas(key, callback)
	return loadAtlas(key, "sparrow", callback)
end

function async.getPackerAtlas(key, callback)
	return loadAtlas(key, "packer", callback)
end

function async.getAtlas(key, callback)
	if paths.exists(paths.getPath("images/" .. key .. ".xml"), "file") then
		return async.getSparrowAtlas(key, callback)
	end
	return async.getPackerAtlas(key, callback)
end

function async.getAnimateAtlas(key, callback)
	local path = paths.getPath("images/" .. key)
	local obj = paths.animate_atlases[path]

	if obj then
		if callback then callback(obj) end
		return obj
	end

	if paths.exists(path, "directory") then
		local AnimateLibrary = require "funkin.backend.animatelibrary"
		local atlas = AnimateLibrary(path)
		atlas:loadAsync(function(loadedAtlas)
			paths.animate_atlases[path] = loadedAtlas
			if callback then callback(loadedAtlas) end
		end)
		return true
	else
		log('animate atlas not found: ' .. key)
		if callback then callback(nil) end
		return nil
	end
end

function async.loadBatch(files)
	local loaders = {
		image = function(path) async.getImage(path) end,
		sound = function(path) async.getSound(path) end,
		audio = function(path) async.getAudio(path, true) end,
		inst = function(path, suffix) async.getInst(path, suffix) end,
		voices = function(path, suffix) async.getVoices(path, suffix) end,
		animate = function(path) async.getAnimateAtlas(path) end
	}

	for _, file in ipairs(files) do
		local type, path, suffix = unpack(file)
		local loader = loaders[type]
		if loader then loader(path, suffix) end
	end
end

function async.getProgress()
 return stats.queued == 0 and 1 or math.min(1, stats.completed / stats.queued)
end
function async.getStats()
 local retiring = cleanupRetired()
 local lastError = stats.lastError
 local copy
 if lastError then copy = {}; for k, v in pairs(lastError) do copy[k] = v end end
 return {queued = stats.queued, completed = stats.completed, failed = stats.failed,
  pending = #queue.tasks, inFlight = count(active), workers = #group.threads,
  retiringWorkers = retiring, maxWorkers = MAX_THREADS, maxUploads = MAX_UPLOADS,
  ready = group.results:getCount(), generation = generation, lastError = copy}
end
function async.stop()
 -- Workers already inside a blocking transport finish asynchronously. They
 -- cannot publish into the next generation, and still occupy worker slots.
 group.cancel:push(true)
 group.tasks:clear()
 for _ = 1, #group.threads do group.tasks:push('exit') end
 drain(group)
 retired[#retired + 1] = group
 queue, active, pending = {tasks = {}, callbacks = {}}, {}, {}
 stats.queued, stats.completed, stats.failed, stats.lastError = 0, 0, 0, nil
 newGroup()
 cleanupRetired()
end
return async

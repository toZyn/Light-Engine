-- Reporting only: callers own the explicit safe fallback. Never resume an
-- arbitrary engine failure or change native Script callback isolation.
local Errors = {}
local queue, history = {}, {}
local MAX_PENDING, MAX_HISTORY, MAX_KEY_BYTES = 8, 32, 16384
local INTERVAL, DUPLICATE_WINDOW = 2, 10
local lastClipboard, lastNotification = -math.huge, -math.huge
local pendingClipboard
local totals = {total = 0, reported = 0, deduplicated = 0, dropped = 0, copied = 0, clipboardFailures = 0, notificationFailures = 0}
local function stringify(value)
 local ok, text = pcall(tostring, value)
 return ok and text or '<unprintable error>'
end
local function now() return love.timer and love.timer.getTime() or os.time() end
local function console(text)
 local output = Logger and Logger.print or print
 if type(output) == 'function' then pcall(output, text) end
end
local function diagnostics()
 local module = package.loaded['funkin.backend.diagnostics']
 if module then return module end
 local ok, loaded = pcall(require, 'funkin.backend.diagnostics')
 if ok then return loaded end
end
local function trim(text, length)
 local utf8 = require 'utf8'
 local output, count = {}, 0
 for character in text:gmatch(utf8.charpattern) do
  count = count + 1
  if count > length then output[#output + 1] = '...'; break end
  output[#output + 1] = character
 end
 return table.concat(output)
end
local function ready()
 return Toast and Toast.showErrors and Toast.font and Toast.bigfont
  and Toast.icons and Toast.icons.error and type(Toast.error) == 'function'
end
local function copyPending(time)
 if not pendingClipboard or time - lastClipboard < INTERVAL then return false end
 lastClipboard = time
 local fn = love.system and love.system.setClipboardText
 local ok, result = false, nil
 if type(fn) == 'function' then ok, result = pcall(fn, pendingClipboard) end
 -- LÖVE normally returns nil on success; an explicit false is rejection.
 if ok and result ~= false then
  totals.copied = totals.copied + 1
  pendingClipboard = nil
  return true
 end
 totals.clipboardFailures = totals.clipboardFailures + 1
 return false
end
function Errors.update()
 copyPending(now())
 if #queue == 0 or not ready() then return end
 local time = now()
 if time - lastNotification < INTERVAL then return end
 local item = table.remove(queue, 1)
 lastNotification = time
 local ok, err = pcall(Toast.error, item.text)
 if not ok then
  totals.notificationFailures = totals.notificationFailures + 1
  console('Recoverable notification unavailable; original report retained: ' .. stringify(err))
 end
end
function Errors.report(message, trace, options)
 options = type(options) == 'table' and options or {}
 message, trace = stringify(message), stringify(trace or debug.traceback('', 2))
 local source = stringify(options.source or 'reportable error')
 local time = now()
 totals.total = totals.total + 1
 local key
 if #message + #trace + #source <= MAX_KEY_BYTES then
  key = #source .. ':' .. source .. #message .. ':' .. message .. trace
  for _, entry in ipairs(history) do
   if entry.key == key and time - entry.time < DUPLICATE_WINDOW then
    entry.count = entry.count + 1
    totals.deduplicated = totals.deduplicated + 1
    return {message = message, trace = trace, source = source, duplicate = true, count = entry.count,
     reported = false, persisted = false, copied = false, queued = false}
   end
  end
 end
 if key then
  if #history >= MAX_HISTORY then table.remove(history, 1) end
  history[#history + 1] = {key = key, time = time, count = 1}
 end
 local record = {message = message, trace = trace, source = source, duplicate = false, count = 1,
  reported = false, persisted = false, copied = false, queued = false}
 local diagnostic = diagnostics()
 local report = message .. '\n' .. trace
 if diagnostic and type(diagnostic.report) == 'function' then
  local ok, result = pcall(diagnostic.report, message, trace)
  if ok and type(result) == 'string' then
   report, record.reported = result, true
   record.reportPath = result:match('\nReport: ([^\n]+)$')
   record.persisted = record.reportPath ~= nil
   totals.reported = totals.reported + 1
  else console('Original error could not be persisted: ' .. message .. '\n' .. trace .. '\nReporting failure: ' .. stringify(result)) end
 end
 if diagnostic and diagnostic.sanitize then report = diagnostic.sanitize(report) end
 record.report = report
 console(report)
 -- Clipboard and notifications are optional outputs. Their failures must not
 -- replace the original diagnostics or escape a known isolated boundary.
 -- Keep only the latest unique full report when writes are throttled or the
 -- clipboard provider is temporarily unavailable. update() retries it later.
 pendingClipboard = report
 record.copied = copyPending(time)
 local summary = message
 if diagnostic and diagnostic.sanitize then summary = diagnostic.sanitize(summary) end
 summary = trim(summary:gsub('[\r\n\t]+', ' '), 180)
 local status = record.persisted and 'Report saved.' or 'See console for full error.'
 if record.copied then status = status .. ' Copied to clipboard.' end
 if #queue < MAX_PENDING then
  queue[#queue + 1] = {text = summary .. '\n' .. status}
  record.queued = true
 else totals.dropped = totals.dropped + 1 end
 Errors.update()
 return record
end
function Errors.getStats()
 local result = {pending = #queue, pendingClipboard = pendingClipboard ~= nil, history = #history, maxPending = MAX_PENDING, maxHistory = MAX_HISTORY,
  notificationInterval = INTERVAL, duplicateWindow = DUPLICATE_WINDOW}
 for key, value in pairs(totals) do result[key] = value end
 return result
end
function Errors.bind(script)
 local reference = setmetatable({script}, {__mode = 'v'})
 script:set('reportRecoverableError', function(message, trace)
  local owner = reference[1]
  if not owner or owner.closed then error('Recoverable errors cannot be reported by a closed script', 2) end
  return Errors.report(message, trace, {source = owner.path})
 end)
end
return Errors

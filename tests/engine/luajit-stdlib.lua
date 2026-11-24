-- The engine runs on LuaJIT (Lua 5.1). loxel installs a `table` metatable whose
-- fallback returns a function for ANY missing key, so calling a Lua 5.2+ stdlib
-- function does not raise "attempt to call a nil value" -- it silently returns a
-- bogus value that then breaks downstream code (e.g. cameraFlash returning a
-- boolean instead of the real result). Guard the whole engine surface.
check('engine sources do not call Lua 5.2+ standard library functions',function()
 local banned={
  {pattern='table%.pack%s*%(', name='table.pack'},
  {pattern='table%.unpack%s*%(', name='table.unpack'},
  {pattern='table%.move%s*%(', name='table.move'},
  {pattern='math%.type%s*%(', name='math.type'},
  {pattern='math%.tointeger%s*%(', name='math.tointeger'},
  {pattern='math%.ult%s*%(', name='math.ult'},
  {pattern='string%.pack%s*%(', name='string.pack'},
  {pattern='string%.unpack%s*%(', name='string.unpack'},
 }
 local offenders={}
 local function scan(path)
  for _,name in ipairs(love.filesystem.getDirectoryItems(path)) do
   local file=path..'/'..name
   local info=love.filesystem.getInfo(file)
   if info.type=='directory' then scan(file)
   -- override.lua *defines* the 5.2+/5.3+ shims, so it legitimately contains
   -- these names. runtime.lua and shim.lua are generated Haxe output with their
   -- own shims (`_hx_table.unpack = table.unpack or unpack`).
   elseif name:match('%.lua$') and not file:match('psych/runtime%.lua$')
    and not file:match('psych/shim%.lua$')
    and not file:match('loxel/lib/override%.lua$') then
    local source=love.filesystem.read(file) or ''
    -- Strip comments and string literals so documentation and messages pass.
    local code=source:gsub('%-%-%[%[.-%]%]',''):gsub('%-%-[^\n]*','')
      :gsub('"[^"\n]*"','""'):gsub("'[^'\n]*'","''")
    for _,entry in ipairs(banned) do
     if code:find(entry.pattern) then offenders[#offenders+1]=file..': '..entry.name end
    end
   end
  end
 end
 scan('loxel'); scan('funkin')

 -- A regression here means a value silently became a function or a boolean.
 if #offenders>0 then
  error('Lua 5.2+ standard library used on a LuaJIT runtime:\n  '..table.concat(offenders,'\n  '),0)
 end
 print('LUAJIT STDLIB PASS: no 5.2+ standard library calls in engine sources')
end)

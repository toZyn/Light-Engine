check('all engine and example Lua sources compile in the native LuaJIT runtime',function()
 local count=0
 local function walk(path)
  for _,name in ipairs(love.filesystem.getDirectoryItems(path)) do
   local file=path..'/'..name;local info=love.filesystem.getInfo(file)
   if info.type=='directory' then walk(file)
   elseif name:match('%.lua$') then assert(love.filesystem.load(file));count=count+1 end
  end
 end
 walk('loxel');walk('funkin');walk('examples');walk('tests/engine')
 for _,file in ipairs({'main.lua','conf.lua','project.lua'}) do assert(love.filesystem.load(file));count=count+1 end
 print('Native LuaJIT compiled '..count..' files')
end)

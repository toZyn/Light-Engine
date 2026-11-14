local Preferences={}
local reported={}
local sources=setmetatable({}, {__mode="k"})
local function readonly(source,label)
 local proxy=setmetatable({}, {
  __index=function(_,key)
   local value=source[key]
   if type(value)=="table" then return readonly(value,label.."."..tostring(key)) end
   return value
  end,
  __newindex=function(_,key)
   local name=label.."."..tostring(key)
   if not reported[name] then
    reported[name]=true
    require("funkin.backend.recoverable-errors").report("A script attempted to overwrite user preference "..name,nil,{source="preferences"})
   end
  end,
  __metatable=false
 })
 sources[proxy]=source
 return proxy
end
function Preferences.bind(script)
 script:set("pairs",function(value)
  local source=sources[value]
  if not source then return pairs(value) end
  local function iterator(_,key)
   local nextKey=next(source,key)
   if nextKey~=nil then return nextKey,value[nextKey] end
  end
  return iterator,value,nil
 end)
 local proxy=readonly(ClientPrefs,"ClientPrefs")
 local wrapper={data=proxy.data,controls=proxy.controls}
 wrapper.saveData=function() return false,"Preferences are saved by the engine options menu" end
 script:set("ClientPrefs",setmetatable({}, {__index=function(_,key)return wrapper[key] or proxy[key]end,__newindex=function(_,key,value)proxy[key]=value end,__metatable=false}))
end
return Preferences

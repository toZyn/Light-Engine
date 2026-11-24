-- Run as main.lua in a temporary LÖVE checkout runner.
--
-- The compiled Psych layer talks to four Lua API modules: Lua_helper, Lua, LuaL
-- and Convert. This exercises the bridge that implements them, following the
-- exact call sequence FunkinLua.hx uses, so a change in the bridge shows up here
-- instead of as a silent dead callback in someone's mod.
require 'loxel'
require 'funkin'
function love.load()
 local ok,err=xpcall(function()
  local Bindings=require('funkin.backend.scripts.psych.bindings')
  local scope={}
  local bridge=Bindings.installLuaApi(scope)
  assert(type(scope.Lua_helper)=='table','Lua_helper not installed')
  assert(type(scope.LuaL.newstate)=='function','LuaL.newstate missing')
  assert(scope.Lua.LUA_TFUNCTION==6 and scope.Lua.LUA_OK==0,'Lua constants wrong')

  -- A script's state, as Psych creates one in FunkinLua.new.
  local state=scope.LuaL.newstate()
  local seen={}
  scope.Lua_helper.add_callback(state,'setProperty',function(path,value)
   seen.path,seen.value=path,value
   return 'ok'
  end)
  scope.Lua_helper.add_callback(state,'makeLuaSprite',function(tag)
   seen.tag=tag
   -- returning nothing is how most Psych callbacks answer
  end)

  -- call() as FunkinLua.hx performs it: getglobal, type check, Convert.toLua per
  -- argument, pcall, Convert.fromLua, pop.
  local function call(name,args)
   scope.Lua.getglobal(state,name)
   local kind=scope.Lua.type(state,-1)
   if kind~=scope.Lua.LUA_TFUNCTION then
    scope.Lua.pop(state,1)
    return nil,'not a function'
   end
   for _,value in ipairs(args or {}) do scope.Convert.toLua(state,value) end
   bridge.registryFor(state).pendingArgs=args or {}
   local status=scope.Lua.pcall(state,#(args or {}),1,0)
   if status~=scope.Lua.LUA_OK then
    return nil,bridge.registryFor(state).error
   end
   local result=scope.Convert.fromLua(state,-1)
   scope.Lua.pop(state,1)
   return result
  end

  -- Arguments reach the callback unchanged.
  assert(call('setProperty',{'boyfriend.alpha',0.5})=='ok','return value lost')
  assert(seen.path=='boyfriend.alpha' and seen.value==0.5,'arguments did not arrive')

  -- A callback that returns nothing answers nil, which Psych turns into
  -- Function_Continue rather than an error.
  assert(call('makeLuaSprite',{'spr'})==nil,'a nil return must stay nil')
  assert(seen.tag=='spr','argument lost on a nil-returning callback')

  -- An unregistered name is reported as a non-function, not raised. Psych's
  -- call() checks the type and warns; it must not abort the callback chain.
  local result,problem=call('notRegistered',{})
  assert(result==nil and problem=='not a function','missing callback not reported')

  -- The state is still usable afterwards: a lookup failure must not corrupt the
  -- stack it shares with the next call.
  assert(call('setProperty',{'x',1})=='ok','state unusable after a miss')
  assert(seen.path=='x','stale value after a miss')

  -- A callback that raises reports the error instead of taking the song down.
  scope.Lua_helper.add_callback(state,'explodes',function() error('boom') end)
  local _,failure=call('explodes',{})
  assert(failure and tostring(failure):find('boom',1,true),'raised callback not reported')
  assert(call('setProperty',{'y',2})=='ok','state unusable after a raise')

  -- Two states do not share registrations, which is the isolation a real Lua
  -- state gives Psych and the reason scripts cannot call each other's functions.
  local other=scope.LuaL.newstate()
  scope.Lua.getglobal(other,'setProperty')
  assert(scope.Lua.type(other,-1)==scope.Lua.LUA_TNIL,'states leaked callbacks')

  -- set/global round-trip, used by FunkinLua.set for song metadata.
  scope.Lua_helper.add_callback(state,'readGlobal',function()
   scope.Lua.getglobal(state,'songName')
   local value=scope.Convert.fromLua(state,-1)
   scope.Lua.pop(state,1)
   return value
  end)
  bridge.registryFor(state).globals.songName='Bopeebo'
  assert(call('readGlobal',{})=='Bopeebo','globals not readable from a callback')

  -- Lua.close discards the state's registry, so a stopped script leaves nothing.
  scope.Lua.close(state)
  assert(bridge.registryFor(state).callbacks.setProperty==nil,'close did not clear')
 end,debug.traceback)
 if not ok then print(err) love.event.quit(1) return end
 print('PSYCH BINDINGS PASSED:')
 love.event.quit(0)
end

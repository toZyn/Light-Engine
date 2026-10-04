-- Run as main.lua in a temporary LÖVE checkout runner.
require 'loxel'
require 'funkin'
local function contains(text,part) assert(tostring(text):find(part,1,true),tostring(text)) end
local function fails(fn,part) local ok,err=pcall(fn);assert(not ok,'expected addon import failure');contains(err,part) end
local function file(path,text)
 local parent=path:match('^(.*)/[^/]+$');if parent then assert(love.filesystem.createDirectory(parent)) end;assert(love.filesystem.write(path,text))
end
function love.load()
 local ok,err=xpcall(function()
  love.window.setMode(320,240,{vsync=0});game.width,game.height=320,240
  local root='tests-addon-libraries';Addons.root=root
  local function module(id,name,text) file(root..'/'..id..'/modules/'..name..'.lua',text) end
  module('lib-a','shared',[[state.loads.a=state.loads.a+1; return {id='a', count=state.loads.a, owner=script, nativeState=state, sandboxIo=io}]])
  module('lib-b','shared',[[state.loads.b=state.loads.b+1; return {id='b'}]])
  module('Library Tools.v1','shared',[[return {id='spaced'}]])
  module('مكتبة','shared',[[return {id='unicode'}]])
  module('disabled','shared',[[error('disabled addon executed')]])
  module('lib-a','nested/init',[[local value=require('addon:lib-a/shared');return {shared=value}]])
  module('lib-a','cycle_a',[[return requireAddon('lib-a','cycle_b')]])
  module('lib-a','cycle_b',[[return requireAddon('lib-a','cycle_a')]])
  module('lib-a','flaky',[[
state.flakyLoads=state.flakyLoads+1
local function nestedModuleFailure() error('addon retry failure') end
if state.failModule then nestedModuleFailure() end
return {attempt=state.flakyLoads}
]])
  module('lib-a','false_export',[[state.loads.falseExport=state.loads.falseExport+1;return false]])
  module('lib-a','nil_export',[[state.loads.nilExport=state.loads.nilExport+1]])
  module('lib-a','unexecuted',[[state.probeExecutions=(state.probeExecutions or 0)+1;return {}]])
  module('lib-a','isolated',[[modulePrivate=77;return function()return modulePrivate end]])
  file(root..'/lib-a/meta.json','{"name":"Library A","description":"test"}')
  game.save.data.addons={order={'lib-a','lib-b','Library Tools.v1','مكتبة','disabled'},active={['lib-a']=true,['lib-b']=true,['Library Tools.v1']=true,['مكتبة']=true,disabled=false}}
  Addons.reload()
  assert(type(Addons.has)=='function','missing reusable addon module API')
  assert(Addons.has('lib-a',true) and Addons.has('disabled') and not Addons.has('disabled',true))
  local list=Addons.list(true);assert(#list==4);list[1].path='changed';list[1].active=false
  assert(Addons.has('lib-a',true),'addon list leaked mutable registry entries')
  assert(Addons.getMetadata('lib-a').name=='Library A')
  assert(Addons.hasModule('lib-a','nested') and not Addons.hasModule('disabled','shared'))
  local state=Group();state.loads={a=0,b=0,falseExport=0,nilExport=0};state.flakyLoads=0;state.failModule=true;state.camHUD=Camera()
  require('loxel.lib.gamestate').stack[1]=state
  local listeners=#Script.messages.listeners
  local script=Script('tests/engine/compat-fixture.lua',false,true,true);local f=script.variables
  assert(type(f.requireAddon)=='function','native Script addon binding missing')
  assert(type(f.tryRequireAddon)=='function','safe optional addon import binding missing')
  local absent,absentError=f.tryRequireAddon('missing','shared')
  assert(absent==nil);contains(absentError,'not installed');assert(not script.closed and next(script.__failedfunc)==nil,'optional import disabled parent Script')
  local disabledExport,disabledError=f.tryRequireAddon('disabled','shared');assert(disabledExport==nil);contains(disabledError,'disabled')
  local malformed,malformedError=f.tryRequireAddon('../escape','shared');assert(malformed==nil);contains(malformedError,'identifier')
  local a=f.requireAddon('lib-a','shared')
  assert(a==f.requireAddon('lib-a','shared') and a==f.require('addon:lib-a/shared') and state.loads.a==1,'module was executed more than once')
  assert(a.owner==script and a.nativeState==state and a.sandboxIo~=io,'module environment lost native sandbox/state/script')
  assert(f.requireAddon('Library Tools.v1','shared')==f.require('addon:Library Tools.v1/shared'),'spaced addon identifier changed')
  assert(f.requireAddon('مكتبة','shared').id=='unicode','Unicode addon identifier rejected')
  local b=f.requireAddon('lib-b','shared');assert(a~=b and b.id=='b' and state.loads.b==1,'addon names collided')
  local nested=f.requireAddon('lib-a','nested');assert(nested.shared==a and nested==f.requireAddon('lib-a','nested.init'),'module file/init aliases executed twice')
  assert(f.requireAddon('lib-a','false_export')==false and f.requireAddon('lib-a','false_export')==false and state.loads.falseExport==1)
  assert(f.requireAddon('lib-a','nil_export')==true and f.requireAddon('lib-a','nil_export')==true and state.loads.nilExport==1)
  local optionalFalse,falseError=f.tryRequireAddon('lib-a','false_export');assert(optionalFalse==false and falseError==nil,'optional import lost false export')
  local optionalA,optionalError=f.tryRequireAddon('lib-a','shared');assert(optionalA==a and optionalError==nil and state.loads.a==1)
  assert(type(f.checkAddonDependencies)=='function','addon dependency checker missing')
  fails(function()f.checkAddonDependencies({id='missing'})end,'array')
  fails(function()f.checkAddonDependencies({[1]='lib-a',[3]='missing'})end,'array')
  local emptyReady,emptyIssues=f.checkAddonDependencies({});assert(emptyReady and #emptyIssues==0)
  local ready,issues=f.checkAddonDependencies({'lib-a',{id='lib-b',module='shared'},{id='lib-a',module='unexecuted'}});assert(ready and #issues==0)
  local notReady,missing=f.checkAddonDependencies({'missing','disabled',{id='lib-a',module='missing'}})
  assert(not notReady and #missing==3);contains(missing[1].message,'not installed');contains(missing[2].message,'disabled');contains(missing[3].message,'not found')
  assert(state.probeExecutions==nil,'dependency checking executed module code')
  local dependencyReport=love.filesystem.read('diagnostics/last-error.txt');contains(dependencyReport,'Addon dependencies unavailable');contains(dependencyReport,'missing');contains(dependencyReport,'disabled')
  local usage=f.getAddonImports();assert(#usage>=7,'successful addon imports not inspectable')
  local sharedUsage;for _,entry in ipairs(usage) do if entry.id=='lib-a' and entry.module=='shared' then sharedUsage=entry end end
  assert(sharedUsage and sharedUsage.path==root..'/lib-a/modules/shared.lua');sharedUsage.id='changed'
  local fresh=f.getAddonImports();for _,entry in ipairs(fresh) do assert(entry.id~='changed','import usage leaked mutable cache record') end
  local isolated=f.requireAddon('lib-a','isolated');assert(isolated()==77 and rawget(f,'modulePrivate')==nil,'module globals leaked to parent Script')
  assert(package.loaded['addon:lib-a/shared']==nil,'addon exports entered global package cache')
  fails(function() f.requireAddon('disabled','shared') end,'disabled')
  fails(function() f.requireAddon('missing','shared') end,'not installed')
  fails(function() f.requireAddon('lib-a','missing') end,'not found')
  for _,bad in ipairs({'','.','..','../lib-a','/absolute','lib\\a','C:escape','bad\nname','bad\0name'}) do fails(function() f.requireAddon(bad,'shared') end,'identifier') end
  for _,bad in ipairs({'..','x..y','../shared','/shared','x\\shared','C:shared','x.'}) do fails(function() f.requireAddon('lib-a',bad) end,'module name') end
  fails(function() f.require('addon:lib-a/') end,'namespace')
  local optionalCycle,cycleError=f.tryRequireAddon('lib-a','cycle_a');assert(optionalCycle==nil);contains(cycleError,'cyclic')
  fails(function() f.requireAddon('lib-a','cycle_a') end,'cyclic')
  fails(function() f.requireAddon('lib-a','cycle_a') end,'cyclic') -- Error rollback must clear loading guards.
  script:set('moduleFailure',function() f.requireAddon('lib-a','flaky') end)
  script:call('moduleFailure');assert(script.__failedfunc.moduleFailure and not script.closed)
  local saved=love.filesystem.read('diagnostics/last-error.txt');contains(saved,'flaky.lua');contains(saved,'nestedModuleFailure')
  state.failModule=false
  local retried=f.requireAddon('lib-a','flaky');assert(retried.attempt==2,'failed import was cached or could not retry')
  local addon
  for _,item in ipairs(Addons.all) do if item.path=='lib-a' then addon=item end end
  Addons.setState(addon,false);fails(function() f.requireAddon('lib-a','shared') end,'disabled');Addons.setState(addon,true)
  file('tests-addon-required.lua',[[return requireAddon('missing','shared')]])
  local required=Script('tests-addon-required.lua',false,true,true)
  assert(required.closed and not script.closed,'missing required addon escaped its parent Script boundary')
  local second=Script('tests/engine/compat-fixture.lua',false,true,true)
  local secondA=second.variables.requireAddon('lib-a','shared');assert(secondA~=a and state.loads.a==2 and secondA.owner==second,'exports leaked across Scripts')
  assert(#Script.messages.listeners==listeners+2,'module imports added message listeners')
  local optionalImport=f.tryRequireAddon
  local import=f.requireAddon;local scopedRequire=f.require
  script:close();second:close()
  assert(#Script.messages.listeners==listeners,'script close leaked module/message listeners')
  local stale,staleError=optionalImport('lib-a','shared');assert(stale==nil);contains(staleError,'closed')
  fails(function() import('lib-a','shared') end,'closed')
  fails(function() scopedRequire('addon:lib-a/shared') end,'closed')
  fails(isolated,'closed')
  assert(script._addonModules==nil,'closed Script retained addon cache')
  -- A complete consumer imports the real example library from active addon files.
  local exampleRoot='tests-addon-examples';love.filesystem.createDirectory(exampleRoot..'/library-addon/modules')
  for _,name in ipairs({'scene','timing'}) do
   file(exampleRoot..'/library-addon/modules/'..name..'.lua',assert(love.filesystem.read('examples/library-addon/modules/'..name..'.lua')))
  end
  Addons.root=exampleRoot;Addons.all={{path='library-addon',active=true}}
  local example=Script('examples/addon-consumer-mod/data/scripts/library-scene.lua',false,true,true)
  assert(example.chunk and not example.closed,'addon consumer failed to load')
  example:call('create');example:call('update',.1);example:call('beat',2);example:call('leave')
  assert(next(example.__failedfunc)==nil,'addon consumer callback failed');example:close()
  assert(#state.members==0,'addon consumer left scene objects behind')
  Addons.all={}
  local absentExample=Script('examples/addon-consumer-mod/data/scripts/library-scene.lua',false,true,true)
  assert(absentExample.chunk and not absentExample.closed,'dependency-check example failed instead of skipping unavailable scene')
  absentExample:call('create');absentExample:call('update',.1);assert(next(absentExample.__failedfunc)==nil and #state.members==0);absentExample:close()
  paths.async.stop()
  print('ADDON MODULES PASS: real registry/files/Script; scoped cache and sandbox; nested/init imports; collisions; cyclic/error rollback and trace; disabled/traversal; cleanup; reusable scene example')
 end,debug.traceback)
 if not ok then print('ADDON MODULES FAIL '..err) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(err) print(err);return function()return 1 end end

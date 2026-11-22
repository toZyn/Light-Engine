local function fixture(source, psych)
 local path='psych-lua-environment-'..tostring(love.math.random(1,1000000000))..'.lua'
 assert(love.filesystem.write(path,source))
 local script=Script(path,true,true,true,psych and function(instance) instance._psych={} end or nil)
 love.filesystem.remove(path)
 return script
end

check('Psych scripts extend private math table and os libraries',function()
 local hostClamp,hostFind,hostClear,hostClock=math.psychFixtureClamp,table.psychFixtureFind,table.clear,os.clock
 local script=fixture([[
function math.psychFixtureClamp(value,lower,upper) return math.max(lower,math.min(value,upper)) end
function table.psychFixtureFind(values,target) for key,value in pairs(values) do if value==target then return key end end end
function table.clear(values) for key in pairs(values) do rawset(values,key,nil) end end
function os.clock() return 12.5 end
local values={7,8,9}
mathResult=math.psychFixtureClamp(20,0,10)
findResult=table.psychFixtureFind(values,8)
table.clear(values)
remaining=next(values)
clockResult=os.clock()
]],true)
 assert(not script.closed,'Psych library extension failed to load')
 assert(script.variables.mathResult==10 and script.variables.findResult==2)
 assert(script.variables.remaining==nil and script.variables.clockResult==12.5)
 assert(math.psychFixtureClamp==hostClamp and table.psychFixtureFind==hostFind and table.clear==hostClear and os.clock==hostClock,'Psych script mutated host libraries')
 local peer=fixture('peerClamp=math.psychFixtureClamp; peerClock=os.clock()',true)
 assert(peer.variables.peerClamp==nil and peer.variables.peerClock~=12.5,'extensions leaked between scripts')
 script:close();peer:close()
end)

check('Psych getfenv and raw access operate on the current script environment',function()
 local script=fixture([[
local function remember(value)
 local env=getfenv()
 env.things=env.things or {}
 rawset(env.things,'value',value)
 return rawget(getfenv(remember).things,'value')
end
remembered=remember(42)
sameEnvironment=getfenv()==_G and getfenv(0)==_G
local dynamic=assert(loadstring('return things.value + 1'))
dynamicResult=dynamic()
]],true)
 assert(not script.closed,'Psych environment helpers failed to load')
 assert(script.variables.remembered==42 and script.variables.sameEnvironment and script.variables.dynamicResult==43)
 assert(rawget(_G,'things')==nil,'script environment leaked into host globals')
 script:close()
end)

check('Psych environment access does not expose host function environments',function()
 local hostClock=os.clock
 local script=fixture([[
blockedHostEnvironment=not pcall(getfenv,math.sin)
blockedHostMutation=not pcall(setfenv,math.sin,{})
local own=function() return 7 end
local ownEnvironment=getfenv(own)
ownEnvironment.value=9
ownEnvironmentResult=ownEnvironment==_G and ownEnvironment.value
blockedExecute=os.execute('psych-fixture-must-not-execute')
]],true)
 assert(not script.closed)
 assert(script.variables.blockedHostEnvironment and script.variables.blockedHostMutation)
 assert(script.variables.ownEnvironmentResult==9 and script.variables.blockedExecute==false)
 assert(os.clock==hostClock)
 script:close()
end)

local Shader = Classic:extend("Shader")
Shader.instances = {}

local function fileExists(path)
	if type(path) == "userdata" then return path, false end
	path = paths.getPath("shaders/" .. path)
	return path, paths.exists(path, "file")
end

-- Sanitize common desktop GLSL / OpenGL ES 3.0 precision conflicts before compiling
-- so LÖVE's forward-declared `vec4 effect(vec4, Image, vec2, vec2)` never hits S0023.
function Shader.sanitizeGLSL(code)
	if type(code) ~= "string" then return code end
	code = code:gsub("(#pragma%s+language%s+glsl3)%s*;", "%1")
	-- Remove file-scope `precision highp float;` if `effect(` uses unqualified or mediump params
	if code:find("precision%s+highp%s+float%s*;") and code:find("effect%s*%(") then
		code = code:gsub("precision%s+highp%s+float%s*;", "")
	end
	-- Normalize `highp vec4 effect(mediump vec4 ...)` -> `vec4 effect(vec4 ...)`
	code = code:gsub("[lhm][ieo][dgpu][ihm]?p?%s+(vec4%s+effect%s*%()", "%1")
	code = code:gsub("(vec4%s+effect%s*%()([^%)]+)%)", function(prefix, params)
		local cleaned = params
			:gsub("%f[%w]lowp%s+", "")
			:gsub("%f[%w]mediump%s+", "")
			:gsub("%f[%w]highp%s+", "")
		return prefix .. cleaned .. ")"
	end)
	return code
end

local function readOrIdentity(path, exists)
	if not exists then return nil end
	local content = love.filesystem.read(path)
	if type(content) == "string" then
		return Shader.sanitizeGLSL(content)
	end
	return path
end

local prepared, failures = {}, {}
local SceneJob = require "funkin.backend.scenejob"

local function enabled()
 return not ClientPrefs or ClientPrefs.data.shader ~= false
end

local function sourceKey(source)
 local frag,hasFrag=fileExists(tostring(source)..".frag")
 local vert,hasVert=fileExists(tostring(source)..".vert")
 return hasFrag and frag or (hasVert and vert or tostring(source))
end

local function compile(source)
 local key=sourceKey(source)
 if failures[key] then return nil,failures[key] end
 local fragPath,fragExists=fileExists(tostring(source)..".frag")
 local vertPath,vertExists=fileExists(tostring(source)..".vert")
 local args={}
 if fragExists then args[#args+1]=readOrIdentity(fragPath,true) end
 if vertExists then args[#args+1]=readOrIdentity(vertPath,true) end
 if #args==0 then args[1]=type(source)=="string" and Shader.sanitizeGLSL(source) or source end
 local mobile=love.system.getOS()=="Android" or love.system.getOS()=="iOS"
 local ok,compiled=pcall(function()
  if love.graphics.validateShader then
   local valid,message=love.graphics.validateShader(mobile,unpack(args))
   if not valid then error(message,0) end
  end
  return love.graphics.newShader(unpack(args))
 end)
 if ok then return compiled end
 local renderer,version,vendor,device=love.graphics.getRendererInfo()
 local message="Shader unavailable: "..key.." ["..love.system.getOS().."; "..tostring(renderer).." "..tostring(version).."; "..tostring(vendor).."; "..tostring(device).."]\n"..tostring(compiled)
 failures[key]=message
 if Logger then Logger.log("warn",message) end
 local diagnostics=package.loaded["funkin.backend.diagnostics"]
 if diagnostics then diagnostics.report(message,debug.traceback()) end
 return nil,message
end

function Shader.prepare(source,copies)
 if not enabled() then return true end
 local key=sourceKey(source)
 prepared[key]=prepared[key] or {}
 copies=math.max(1,math.min(32,math.floor(tonumber(copies) or 1)))
 while #prepared[key]<copies do
  SceneJob.checkpoint("Shader: "..tostring(source))
  local compiled,err=compile(source)
  if not compiled then return false,err end
  prepared[key][#prepared[key]+1]=compiled
 end
 return true
end

function Shader:new(source)
 rawset(self,"uniforms",{})
 if not enabled() then return end
 local pool=prepared[sourceKey(source)]
 local compiled=pool and table.remove(pool) or compile(source)
 if not compiled then return end
 rawset(self,"__shader",compiled)
 if compiled:hasUniform("time") then rawset(self,"__time",0) end
 table.insert(Shader.instances,self)
end

function Shader:update(dt)
	local sh = rawget(self, "__shader")
	if sh and rawget(self, "__time") then
		rawset(self, "__time", self.__time + dt)
		self:set("time", self.__time)
	end
end

function Shader:__newindex(key, value)
	if type(value) == "function" then
		rawset(self, key, value)
	else
		local sh = rawget(self, "__shader")
		if not sh then return false end
		if not sh:hasUniform(key) then
			return false
		end
		self:set(key, value)
	end
end

function Shader:set(name, value)
	local sh = rawget(self, "__shader")
	if not sh or not sh:hasUniform(name) then return end
	if self.uniforms[name] == value then return end
	rawset(self.uniforms, name, value)
	pcall(sh.send, sh, name, value)
end

function Shader:get() return rawget(self, "__shader") end

function Shader:destroy()
	local sh = rawget(self, "__shader")
	if sh then
		pcall(sh.release, sh)
		rawset(self, "__shader", nil)
	end
	table.delete(Shader.instances, self)
end

function Shader.updateTime(dt)
	for i = 1, #Shader.instances do
		Shader.instances[i]:update(dt)
	end
end

function Shader.clear()
 for _,pool in pairs(prepared) do
  for _,shader in ipairs(pool) do shader:release() end
 end
 prepared,failures={},{}
	for i = #Shader.instances, 1, -1 do
		Shader.instances[i]:destroy()
	end
	table.clear(Shader.instances)
end

return Shader

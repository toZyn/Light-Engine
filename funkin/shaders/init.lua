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

Shader.prepared={}
local failures={}
local function compile(source)
 local fragPath,fragExists=fileExists(tostring(source)..".frag")
 local vertPath,vertExists=fileExists(tostring(source)..".vert")
 local frag=fragExists and readOrIdentity(fragPath,true) or nil
 local vert=vertExists and readOrIdentity(vertPath,true) or nil
 if not frag and not vert then frag=type(source)=="string" and Shader.sanitizeGLSL(source) or source end
 local ok,valid,message=pcall(love.graphics.validateShader,true,frag or vert,frag and vert or nil)
 if not ok or not valid then return nil,tostring(message or valid) end
 local success,result=pcall(love.graphics.newShader,frag or vert,frag and vert or nil)
 if not success then return nil,tostring(result) end
 return result
end
local function failure(source,message)
 if failures[source] then return end
 failures[source]=message
 require("funkin.backend.recoverable-errors").report("Shader unavailable: "..tostring(source)..". The effect was disabled. "..tostring(message),nil,{source="shader"})
end
function Shader.prepare(sources)
 local results={}
 if ClientPrefs and ClientPrefs.data.shader==false then return results end
 for index,source in ipairs(sources) do
  require("funkin.backend.loading").checkpoint("Preparing shaders",index-1,#sources)
  if type(source)=="string" then
   local pool=Shader.prepared[source] or {}
   local program,err
   if not failures[source] then program,err=compile(source) end
   if program then pool[#pool+1]=program;Shader.prepared[source]=pool elseif err then failure(source,err) end
   results[source]=#pool>0
  end
 end
 return results
end
function Shader:new(source)
 rawset(self,"uniforms",{})
 if ClientPrefs and ClientPrefs.data.shader==false then return end
 local pool=Shader.prepared[source]
 local compiled=pool and table.remove(pool)
 if pool and #pool==0 then Shader.prepared[source]=nil end
 local err
 if not compiled and not failures[source] then compiled,err=compile(source) end
 if compiled then
  rawset(self,"__shader",compiled)
  if compiled:hasUniform("time") then rawset(self,"__time",0) end
  table.insert(Shader.instances,self)
 else
  rawset(self,"__shader",nil)
  if err then failure(source,err) end
 end
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

function Shader:get()
 if ClientPrefs and ClientPrefs.data.shader==false then return nil end
 return rawget(self,"__shader")
end

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
 for _,pool in pairs(Shader.prepared) do for _,program in ipairs(pool) do program:release() end end
 Shader.prepared={}
 failures={}
	for i = #Shader.instances, 1, -1 do
		Shader.instances[i]:destroy()
	end
	table.clear(Shader.instances)
end

return Shader

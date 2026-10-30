local Shader = Classic:extend("Shader")
Shader.instances = {}

local function fileExists(path)
	if type(path) == "userdata" then return path, false end
	path = paths.getPath("shaders/" .. path)
	return path, paths.exists(path, "file")
end

function Shader:new(source)
	rawset(self, "uniforms", {})

	local fragPath, fragExists = fileExists(source .. ".frag")
	local vertPath, vertExists = fileExists(source .. ".vert")

	if fragExists or vertExists then
		rawset(self, "__shader", love.graphics.newShader(
			fragExists and fragPath or nil,
			vertExists and vertPath or nil))
	else
		rawset(self, "__shader", love.graphics.newShader(source))
	end

	local haveTime = self.__shader:hasUniform("time")
	if haveTime then
		rawset(self, "__time", 0)
	end

	table.insert(Shader.instances, self)
end

function Shader:update(dt)
	if self.__time then
		rawset(self, "__time", self.__time + dt)
		self:set("time", self.__time)
	end
end

function Shader:__newindex(key, value)
	if type(value) == "function" then
		rawset(self, key, value)
	else
		if not rawget(self, "__shader") or not self.__shader:hasUniform(key) then
			print("Shader uniform " .. key .. " is not defined")
			return false
		end
		self:set(key, value)
	end
end

function Shader:set(name, value)
	if self.uniforms[name] == value then return end
	rawset(self.uniforms, name, value)
	self.__shader:send(name, value)
end

function Shader:get() return rawget(self, "__shader") end

function Shader:destroy()
	if rawget(self, "__shader") then
		self.__shader:release()
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
	for i = #Shader.instances, 1, -1 do
		Shader.instances[i]:destroy()
	end
	table.clear(Shader.instances)
end

return Shader

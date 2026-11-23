local Shaders = {}
local attachments = setmetatable({}, {__mode = "k"})

-- love's shader prelude already defines the GLSL2/GLSL3 compatibility macros
-- (texture, texture2D, attribute, varying, ...). Psych mods ship their own
-- copies, which makes the driver abort with
--   ERROR: '#define' : Macro redefined; different substitutions: texture
-- Dropping the duplicates and rewriting the call sites to love's `Texel` keeps
-- the shader compiling with identical behaviour.
local PRELUDE_MACROS = {
	texture = true, texture2D = true, textureLod = true, textureProj = true,
	attribute = true, varying = true, gl_FragColor = true, gl_FragData = true,
}

local function stripDuplicateMacros(source)
	local seen, kept = {}, {}
	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local macro = line:match("^%s*#%s*define%s+([%w_]+)")
		local duplicate = macro and (seen[macro] or PRELUDE_MACROS[macro])
		if not duplicate then
			if macro then seen[macro] = true end
			kept[#kept + 1] = line
		end
	end
	return table.concat(kept, "\n")
end

local function translate(source, vertex)
	if source:find("vec4%s+effect%s*%(") then return source end
	source = source:gsub("#pragma%s+header[^\n]*", "")
	source = source:gsub("#version[^\n]*", "")
	source = stripDuplicateMacros(source)
	source = source:gsub("%f[%w_]flixel_texture2D%f[^%w_]", "Texel")
	source = source:gsub("%f[%w_]texture2D%f[^%w_]", "Texel")
	-- A bare `texture(...)` call (GLSL3 spelling) must reach love's Texel too.
	source = source:gsub("%f[%w_]texture%s*%(", "Texel(")
	source = source:gsub("%f[%w_]gl_FragColor%f[^%w_]", "psychOutput")
	local rewritten, mains = source:gsub("void%s+main%s*%(%s*%)%s*{", "void psychMain() {")
	if mains ~= 1 then error("Psych fragment shader must declare one void main()", 2) end
	local declaration = vertex and "varying vec2 psychUV;\n" or ""
	return declaration .. [[
extern vec2 openfl_TextureSize;
vec2 openfl_TextureCoordv;
vec4 psychOutput;
]] .. rewritten .. [[

vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
	openfl_TextureCoordv = ]] .. (vertex and "psychUV" or "uv") .. [[;
	psychOutput = vec4(0.0);
	psychMain();
	return psychOutput * color;
}
]]
end

local function translateVertex(source)
	if source:find("vec4%s+position%s*%(") then return source, false end
	source = source:gsub("#pragma%s+header[^\n]*", "")
	source = source:gsub("#version[^\n]*", "")
	source = source:gsub("#pragma%s+body[^\n]*",
		"psychPosition = openfl_Matrix * openfl_Position; psychUV = VertexTexCoord.xy;")
	source = source:gsub("%f[%w_]gl_Position%f[^%w_]", "psychPosition")
	source = source:gsub("%f[%w_]openfl_TextureCoordv%f[^%w_]", "psychUV")
	local rewritten, mains = source:gsub("void%s+main%s*%(%s*%)%s*{", "void psychVertexMain() {")
	if mains ~= 1 then error("Psych vertex shader must declare one void main()", 2) end
	return [[
varying vec2 psychUV;
vec4 psychPosition;
mat4 openfl_Matrix;
vec4 openfl_Position;
#define openfl_TextureCoord VertexTexCoord.xy
]] .. rewritten .. [[

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
	openfl_Matrix = transformProjection;
	openfl_Position = vertexPosition;
	psychPosition = transformProjection * vertexPosition;
	psychUV = VertexTexCoord.xy;
	psychVertexMain();
	return psychPosition;
}
]], true
end

function Shaders.install(compat, api)
	local sources, targets, loose = {}, {}, {}
	local function remove(tag)
		local entry = targets[tag]
		if not entry then return end
		if entry.object.shader == entry.shader then
			entry.object.shader = entry.previous
			entry.object.psychPrefilters = entry.previousFilters
			if not entry.previousFilters and entry.object.clearPsychFilterBuffers then
				entry.object:clearPsychFilterBuffers()
			end
		end
		local active = attachments[entry.object]
		active[entry] = nil
		for other in pairs(active) do
			if other.previous == entry.shader then
				other.previous, other.previousFilters = entry.previous, entry.previousFilters
			end
		end
		if not next(active) then attachments[entry.object] = nil end
		targets[tag] = nil
		if entry.owned then entry.shader:release() end
	end

	api.initLuaShader = function(name)
		compat:_active()
		if type(name) ~= "string" or not name:match("^[%w_%-]+$") then
			require("funkin.backend.scripts.psych.reflection").warn(
				"initLuaShader skipped: invalid shader name " .. tostring(name))
			return false
		end
		if ClientPrefs.data.shader == false then return false end
		local fragment = paths.getMods("shaders/" .. name .. ".frag")
		local vertex = paths.getMods("shaders/" .. name .. ".vert")
		local vertexSource, useVarying
		if love.filesystem.getInfo(vertex, "file") then
			vertexSource, useVarying = translateVertex(assert(love.filesystem.read(vertex)))
		end
		local source, message = love.filesystem.read(fragment)
		if not source and vertexSource then
			source = "void main() { gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv); }"
		end
		if not source then
			require("funkin.backend.scripts.psych.reflection").warn(
				"Cannot read Psych shader " .. tostring(name) .. ": " .. tostring(message))
			return false
		end
		sources[name] = {pixel = translate(source, useVarying), vertex = vertexSource}
		return true
	end

	local function compile(name)
		if ClientPrefs.data.shader == false then return end
		if not sources[name] then api.initLuaShader(name) end
		local source = assert(sources[name])
		if source.vertex then return love.graphics.newShader(source.pixel, source.vertex) end
		return love.graphics.newShader(source.pixel)
	end

	local function attach(tag, object, shader, owned, filters)
		if shader:hasUniform("openfl_TextureSize") then
			local texture = object.texture or object.canvas
			local width, height = object.width or game.width, object.height or game.height
			if texture and texture.getDimensions then width, height = texture:getDimensions() end
			shader:send("openfl_TextureSize", {width, height})
		end
		remove(tag)
		local entry = {
			object = object, shader = shader, previous = object.shader, previousFilters = object.psychPrefilters,
			uniforms = {}, owned = owned
		}
		targets[tag] = entry
		local active = attachments[object] or {}
		active[entry], attachments[object] = true, active
		object.shader, object.psychPrefilters = shader, filters
	end

	api.setSpriteShader = function(tag, name)
		compat:_active()
		local object = compat:_object(tag)
		if not object then return false end
		-- A shader that fails to compile must not take the whole script with it:
		-- Psych mods attach optional effects and only need the sprite to keep drawing.
		local ok, shader = pcall(compile, name)
		if not ok then
			require("funkin.backend.scripts.psych.reflection").warn(
				"shader " .. tostring(name) .. " skipped: " .. tostring(shader))
			return false
		end
		if not shader then return false end
		attach(tag, object, shader, true)
		return true
	end
	compat.psychShaderBindings = {
		create = function(name)
			local shader = compile(name)
			if shader then loose[shader] = true end
			return shader
		end,
		attach = function(tag, object, shader)
			assert(loose[shader], "HScript shader is not owned by this script")
			attach(tag, object, shader, false)
		end,
		filters = function(tag, object, list)
			for _, shader in ipairs(list) do
				assert(loose[shader], "HScript shader is not owned by this script")
			end
			local last = table.remove(list)
			attach(tag, object, last, false, #list > 0 and list or nil)
		end,
		remove = remove
	}
	api.removeSpriteShader = function(tag) compat:_active(); remove(tag) end

	local function send(tag, uniform, ...)
		compat:_active()
		local entry = assert(targets[tag], "No Psych shader attached to " .. tostring(tag))
		assert(entry.shader:hasUniform(uniform), "Unknown Psych shader uniform " .. tostring(uniform))
		entry.shader:send(uniform, ...)
		entry.uniforms[uniform] = select(1, ...)
	end
	api.setShaderFloat = function(tag, uniform, value) send(tag, uniform, value) end
	api.setShaderBool = api.setShaderFloat
	api.setShaderInt = api.setShaderFloat
	local function sendArray(tag, uniform, values)
		assert(type(values) == "table", "Expected a shader uniform array")
		if values.length then
			send(tag, uniform, unpack(values, 0, values.length - 1))
		else
			send(tag, uniform, unpack(values))
		end
	end
	api.setShaderFloatArray, api.setShaderIntArray, api.setShaderBoolArray = sendArray, sendArray, sendArray
	api.setShaderSampler2D = function(tag, uniform, image)
		local texture = assert(paths.getImage(image), "Missing Psych shader image: " .. tostring(image))
		send(tag, uniform, texture)
	end
	local function getUniform(tag, uniform)
		local entry = targets[tag]
		if entry then return entry.uniforms[uniform] end
	end
	api.getShaderFloat, api.getShaderInt, api.getShaderBool = getUniform, getUniform, getUniform

	local removeObject = compat._remove
	compat._remove = function(self, tag, destroy)
		if destroy then remove(tag) end
		return removeObject(self, tag, destroy)
	end
	compat.disposePsychShaders = function()
		for tag in pairs(targets) do remove(tag) end
		for shader in pairs(loose) do shader:release() end
		loose = {}
	end
end

return Shaders

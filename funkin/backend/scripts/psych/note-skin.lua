local PsychSkin = {}
local colors = {"purple", "blue", "green", "red"}
local directions = {"left", "down", "up", "right"}

local function entry(original, animations, atlas)
	local byDirection = {}
	for direction, specs in ipairs(animations) do
		if #atlas:getFramesByPrefix(specs[1][2]) > 0 then
			local variant = {}
			for key, value in pairs(original) do variant[key] = value end
			variant.atlas, variant.animations, variant.isPixel = atlas, {}, false
			for _, spec in ipairs(specs) do
				local name, prefix, fps, looped = unpack(spec)
				if #atlas:getFramesByPrefix(prefix) == 0 then prefix = specs[1][2] end
				variant.animations[#variant.animations + 1] = {name, prefix, fps, looped}
			end
			byDirection[direction] = variant
		end
	end
	if not next(byDirection) then return original end
	return setmetatable({byDirection = byDirection}, {__index = original})
end

function PsychSkin.postfix()
	local prefs = ClientPrefs and ClientPrefs.data
	if not prefs or not prefs.noteSkin or prefs.noteSkin == "Default" then return "" end
	return "-" .. prefs.noteSkin:match("^%s*(.-)%s*$"):lower():gsub(" ", "_")
end

PsychSkin.default = "noteSkins/NOTE_assets"

function PsychSkin.nameFor(state, texture)
	local name = texture or ""
	if name == "" then
		local song = state and state.psychArrowSkin or (state and state.SONG and state.SONG.arrowSkin)
		if song and #song > 1 then return song end
		return PsychSkin.default .. PsychSkin.postfix()
	end
	local custom = name .. PsychSkin.postfix()
	if paths.hasSheetAtlas(custom) then return custom end
	return name
end

function PsychSkin.wanted(state, texture)
	local name = texture or (state and state.psychArrowSkin) or ""
	if name == "" then return PsychSkin.postfix() ~= "" end
	return true
end

function PsychSkin.resolve(state, base, texture)
	local key = texture or ""
	if key == "" and PsychSkin.postfix() == "" then return base end
	if texture ~= nil and type(texture) ~= "string" then return nil end
	state.psychNoteSkins = state.psychNoteSkins or {}
	local variants = state.psychNoteSkins[base]
	if not variants then
		variants = {}
		state.psychNoteSkins[base] = variants
	end
	if variants[key] ~= nil then return variants[key] or nil end
	local name = PsychSkin.nameFor(state, key)
	local atlas = paths.hasSheetAtlas(name) and paths.getAtlas(name)
	if not atlas then
		variants[key] = key ~= "" and false or nil
		return key == "" and base or nil
	end
	local skin = setmetatable({psychTexture = name}, {__index = base})
	local notes, sustains, ends, receptors = {}, {}, {}, {}
	for i, color in ipairs(colors) do
		local suffix = "-note" .. (i - 1)
		local dir = directions[i]
		notes[i] = {{"note" .. suffix, color .. "0", 24, false}}
		sustains[i] = {{"hold" .. suffix, color .. " hold piece", 24, false}}
		ends[i] = {{"end" .. suffix, color .. " hold end", 24, false}}
		receptors[i] = {
			{"static" .. suffix, "arrow" .. dir:upper(), 24, false},
			{"pressed" .. suffix, dir .. " press", 24, false},
			{"confirm" .. suffix, dir .. " confirm", 24, false}
		}
	end
	skin.notes = entry(base.notes, notes, atlas)
	skin.sustains = entry(base.sustains, sustains, atlas)
	skin.sustainends = entry(base.sustainends, ends, atlas)
	skin.receptors = entry(base.receptors, receptors, atlas)
	variants[key] = skin
	return skin
end

function PsychSkin.withoutRgb(state, skin)
	if skin.psychDisableRgb then return skin end
	state.psychNoRgbSkins = state.psychNoRgbSkins or {}
	local variants = state.psychNoRgbSkins
	if not variants[skin] then
		variants[skin] = setmetatable({psychDisableRgb = true}, {__index = skin})
	end
	return variants[skin]
end

return PsychSkin

local MenuAssets = {}

function MenuAssets.introLines()
 local result, seen = {}, {}
 local candidates = {paths.getPath('data/introText.txt', false, false, false)}
 if Mods and Mods.currentMod then candidates[#candidates + 1] = paths.getMods('data/introText.txt') end
 for _, path in ipairs(candidates) do
  local text = love.filesystem.read(path)
  if text then
   for line in (text .. '\n'):gmatch('(.-)\n') do
    line = line:match('^%s*(.-)%s*$')
    if line ~= '' and not seen[line] then
     seen[line] = true
     local fields, start = {}, 1
     while true do
      local first, last = line:find('--', start, true)
      fields[#fields + 1] = line:sub(start, first and first - 1 or #line)
      if not first then break end
      start = last + 1
     end
     result[#result + 1] = fields
    end
   end
  end
 end
 return result
end

function MenuAssets.character(name)
 local basePath = paths.getPath('data/weeks/characters/bf.json', false, false, false)
 local base = assert(love.filesystem.read(basePath))
 local decode = (loxreq 'lib.json').decode
 local defaults = decode(base)
 local path = paths.getPath('data/weeks/characters/' .. name .. '.json')
 local source = love.filesystem.read(path)
 local ok, data = pcall(decode, source or '')
 if not ok or type(data) ~= 'table' then data = {} end
 local psychImage = type(data.image) == 'string' and data.image ~= '' and data.image
 local image = psychImage or (type(data.sprite) == 'string' and data.sprite ~= '' and data.sprite)
 local fallback = not image
 data.sprite = image or defaults.sprite
 for _, key in ipairs({'idle_anim', 'confirm_anim', 'scale', 'flipX'}) do
  if type(data[key]) ~= type(defaults[key]) then data[key] = defaults[key] end
 end
 if type(data.position) ~= 'table' then data.position = {} end
 for i = 1, 2 do
  if type(data.position[i]) ~= 'number' then data.position[i] = defaults.position[i] end
 end
 return data, psychImage and 'menucharacters/' or 'menus/storymenu/characters/', fallback
end

return MenuAssets

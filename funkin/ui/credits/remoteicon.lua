local RemoteIcon = {}
local available, placeholder

function RemoteIcon.load(url, callback)
 if available == nil then
  available = false
  for _, name in ipairs({'https', 'lib.https'}) do
   local ok, module = pcall(require, name)
   if ok and type(module) == 'table' and type(module.request) == 'function' then available = true; break end
  end
 end
 if not available then
  callback(nil, url, 'HTTPS unavailable on this device')
  return false
 end
 return paths.async.getImage(url, function(image, result)
  callback(image, url, image and nil or result)
 end)
end

function RemoteIcon.placeholder()
 if placeholder and pcall(placeholder.getDimensions, placeholder) then return placeholder end
 local data = love.image.newImageData(64, 64)
 for y = 0, 63 do
  for x = 0, 63 do
   local head = (x-32)^2 + (y-21)^2 <= 100
   local shoulders = ((x-32)/23)^2 + ((y-60)/23)^2 <= 1 and y >= 36
   data:setPixel(x, y, head and 0.7 or shoulders and 0.55 or 0.16,
    head and 0.7 or shoulders and 0.55 or 0.17,
    head and 0.75 or shoulders and 0.6 or 0.22, 1)
  end
 end
 placeholder = love.graphics.newImage(data)
 data:release()
 return placeholder
end

return RemoteIcon

local BackgroundDancer = require "backgrounddancer"

local grpLimoDancers
local fastCarCanDrive = true
local fastCarSpeed = 170

local shader = Shader("wave")
shader.intensity = 2.68
shader.speed = 6.22

shader.position = {0.484756097561, 0.351104341203}
shader.radius = 0.13532459616
local timeThreshold = math.rad(360 / 6.22)

local function resetFastCar()
	fastCarSpeed = love.math.random(170, 220)
	fastCar.x = -12600 - (fastCarSpeed * 32)
	fastCar.y = love.math.random(140, 250)
	fastCar.velocity.x = 0
	fastCarCanDrive = true
end

local function fastCarDrive()
	util.playSfx(paths.getSound('gameplay/carPass' .. love.math.random(0, 1)))

	fastCar.velocity.x = fastCarSpeed / game.dt
	fastCarCanDrive = false
	Timer.wait(2, function() resetFastCar() end)
end

function create()
	dadCam.y = -100
	boyfriendPos = {x = 1078, y = -156}
	boyfriendCam.x = boyfriendCam.x - 200
	camZoom = 0.9
end

function postCreate()
	grpLimoDancers = Group()
	self:insert(self:indexOf(bgLimo) + 1, grpLimoDancers)
	for i = 0, 4 do
		local dancer = BackgroundDancer((370 * i) + 230, bgLimo.y - 380)
		dancer:setScrollFactor(0.4, 0.4)
		grpLimoDancers:add(dancer)
	end
	skyBG.shader = shader:get()

	fastCar.moves = true
	resetFastCar()
end

local bgLimoTime = 0
local cameraOffset = {0, 0}
local offsetTime = 0
function update(dt)
	bgLimoTime = bgLimoTime + dt / 2
	bgLimo.x = -200 + 120 * math.sin(bgLimoTime)
	for i = 0, 4 do
		grpLimoDancers.members[i + 1].x = ((370 * i) + 230) + 120 * math.sin(bgLimoTime)
	end

	offsetTime = offsetTime + dt
	cameraOffset[1] = 14 * math.sin(offsetTime * 1.5)
	cameraOffset[2] = 14 * math.cos(offsetTime * 2.5)

	shader.__time = shader.__time % timeThreshold
end

function onCameraMove(event)
	event.offset.x, event.offset.y =
		event.offset.x + cameraOffset[1], event.offset.y + cameraOffset[2]
end

function beat()
	for _, spr in pairs(grpLimoDancers.members) do
		spr:dance()
	end
	if love.math.randomBool(10) and fastCarCanDrive then
		fastCarDrive()
	end
end

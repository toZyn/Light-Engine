local BackgroundGirls = require "backgroundgirls"

local bgGirls, cam
local floor = math.floor

function preload()
	return {
	    {"image", SCRIPT_PATH .. "weebSky"},
	    {"image", SCRIPT_PATH .. "bgFreaks"},
	    {"image", SCRIPT_PATH .. "weebSchool"},
	    {"image", SCRIPT_PATH .. "weebStreet"},
	    {"image", SCRIPT_PATH .. "weebTreesBack"},
	    {"image", SCRIPT_PATH .. "weebTrees"},
	    {"image", SCRIPT_PATH .. "petals"}
	}
end

function create()
	camZoom = 1

	local pixW = math.min(floor(game.width / 6), 311)
	local pixH = floor(game.height / 6)
	local hudPixW = math.min(floor(game.width / 4), 466)
	local hudPixH = floor(game.height / 4)

	game.camera.pixelPerfect = true
	game.camera.antialiasing = false
	game.camera:resize(pixW, pixH, 1, 1, true)

	cam = Camera()
	cam.pixelPerfect = true
	cam.antialiasing = false
	cam:resize(hudPixW, hudPixH, 1, 1, true)
	table.insert(game.cameras.list, 2, cam)

	boyfriendPos:set(1080, 60)
	gfPos:set(580, 90)
	dadPos:set(0, -400)

	boyfriendCam:set(-20, 0)
	dadCam:set(80, 50)
	gfCam:set(gfCam.x + 8, gfCam.y)

	local bgSky = Sprite()
	bgSky:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebSky'))
	bgSky:setScrollFactor(0.1, 0.1)
	add(bgSky)
	bgSky.antialiasing = false

	local bgSchool = Sprite(-12, 0)
	bgSchool:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebSchool'))
	bgSchool:setScrollFactor(0.6, 0.90)
	add(bgSchool)
	bgSchool.antialiasing = false

	local bgStreet = Sprite(0, -1)
	bgStreet:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebStreet'))
	add(bgStreet)
	bgStreet.antialiasing = false

	local fgTrees = Sprite(5, 0)
	fgTrees:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebTreesBack'))
	fgTrees:updateHitbox()
	add(fgTrees)
	fgTrees.antialiasing = false

	local bgTrees = Sprite(-100, -168)
	bgTrees:setFrames(paths.getPackerAtlas(SCRIPT_PATH .. 'weebTrees'))
	bgTrees:addAnim('treeLoop', {
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
	}, 12)
	bgTrees:play('treeLoop')
	bgTrees:setScrollFactor(0.85, 0.85)
	bgTrees:updateHitbox()
	add(bgTrees)
	bgTrees.antialiasing = false

	local treeLeaves = Sprite(-20, 10)
	treeLeaves:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'petals'))
	treeLeaves:setScrollFactor(0.85, 0.85)
	treeLeaves:addAnimByPrefix('PETALS ALL', 'PETALS ALL', 24, true)
	treeLeaves:play('PETALS ALL')
	treeLeaves:updateHitbox()
	add(treeLeaves)
	treeLeaves.antialiasing = false

	bgGirls = BackgroundGirls(0, 26, paths.formatToSongPath(PlayState.SONG.song) == "roses")
	bgGirls:updateHitbox()
	bgGirls.antialiasing = false
	add(bgGirls)

	refresh()
end

local function rescalePixelCharacter(m, scaledSet)
	if not m or scaledSet[m] then return end
	scaledSet[m] = true
	m.scale.x, m.scale.y = 1, 1
	m:updateHitbox()
	m.x, m.y = floor(m.x / 6), floor(m.y / 6)
	if m.cameraPosition then
		m.cameraPosition.x, m.cameraPosition.y =
			floor(m.cameraPosition.x / 6), floor(m.cameraPosition.y / 6)
	end
	if m.anim and m.anim.getList then
		for _, anim in pairs(m.anim:getList()) do
			anim.offset:set(floor(anim.offset.x / 6), floor(anim.offset.y / 6))
		end
	end
end

function postCreate()
	local scaledSet = {}
	for _, nf in ipairs(notefields) do
		rescalePixelCharacter(nf.character, scaledSet)
	end
	rescalePixelCharacter(gf, scaledSet)
	rescalePixelCharacter(boyfriend, scaledSet)
	rescalePixelCharacter(dad, scaledSet)

	dad:dance()
	dad:finish()
	cameraMovement(getCameraPosition(camTarget))
	game.camera:follow(camFollow, nil)

	judgeSprites.cameras = {cam}
	judgeSprites:setPosition(cam.width / 4, 264 / 4)
	judgeSprites.area = {width = 135, height = 30}
end

function postGameOverCreate()
	game.cameras.remove(cam)
	local m = game.getState(true).boyfriend
	m.scale:set(1, 1)
	m:updateHitbox()
	m.x, m.y = floor(m.x / 6), floor(m.y / 6)
	if m.cameraPosition then
		m.cameraPosition.x, m.cameraPosition.y =
			floor(m.cameraPosition.x / 6), floor(m.cameraPosition.y / 6)
	end
	local x, y = m:getGraphicMidpoint()
	game.getState(true).camFollow = Point(x - 30, y - 9)
	for _, anim in pairs(m.animation:getList()) do
		anim.offset:set(floor(anim.offset.x / 6), floor(anim.offset.y / 6))
	end
end

function postGameOverUpdate()
	game.camera.zoom = 1
end

function postUpdate()
	game.camera.zoom = math.truncate(game.camera.zoom, 3)
	if cam and camHUD then
		cam.zoom = math.truncate(camHUD.zoom, 3)
	end
end

function beat(b) bgGirls:dance() end

function close()
	if cam then
		game.cameras.remove(cam)
		cam = nil
	end
	if game.camera then
		game.camera.pixelPerfect = false
		game.camera.antialiasing = true
		game.camera:resize(game.width, game.height)
	end
end

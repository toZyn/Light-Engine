local shader = Shader("wiggle")

local floor = math.floor

function create()
	camZoom = 1

	local pixW = math.min(floor(game.width / 6), 311)
	local pixH = floor(game.height / 6)
	local hudPixW = math.min(floor(game.width / 4), 466)
	local hudPixH = floor(game.height / 4)

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

	game.camera.pixelPerfect = true
	game.camera.antialiasing = false
	game.camera:resize(pixW, pixH, 1, 1, true)

	local bg = Sprite(-24, 0, paths.getImage(SCRIPT_PATH .. 'evilSchoolBG'))
	bg:setScrollFactor(0.6, 1)
	bg:updateHitbox()
	bg.antialiasing = false
	bg.shader = shader:get()
	add(bg)

	local floor = Sprite(0, 0)
	floor:loadTexture(paths.getImage(SCRIPT_PATH .. 'evilSchoolFG'))
	floor:updateHitbox()
	floor.antialiasing = false
	floor.shader = shader:get()
	add(floor)
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
	if gf then gf.visible = false end

	if dad then
		stage:insert(stage:indexOf(dad), Trail(dad, 4, 24, 0.3, 0.069))
	end

	dad:dance()
	dad:finish()
	cameraMovement(getCameraPosition(camTarget))
	game.camera:follow(camFollow, nil)

	judgeSprites.cameras = {cam}
	judgeSprites:setPosition(cam.width / 4, 264 / 4)
	judgeSprites.area = {width = 135, height = 30}
end

function postUpdate(dt)
	shader.__time = shader.__time % (2 * math.pi)
	game.camera.zoom = math.truncate(game.camera.zoom, 3)
	if cam and camHUD then cam.zoom = math.truncate(camHUD.zoom, 3) end
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

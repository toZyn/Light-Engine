check('Story Mode automatic difficulties stay below the character backdrop', function()
 local state=StoryMenuState()
 state:enter()
 assert(#state.weeksData>0)
 local week=state.weeksData[state.weekList.curSelected]
 assert(not week.noPlayableDifficulty and #week.difficulties>=3)
 assert(state.sprDifficulty.visible or state.txtDifficulty.visible)
 assert(state.leftArrow.y==state.weekList.members[1].yAdd)
 assert(state.leftArrow.y>442,'difficulty selector is covered by the character backdrop')
 state:leave()
end)

check('mobile difficulty rows stay separated for short and long lists', function()
 for _,count in ipairs({1,2,3,12}) do
  local list=MenuList(nil,false,'mobile')
  list.mobileTop=140
  for i=1,count do list:add(AtlasText(0,0,'Difficulty '..i,'bold')) end
  for _,selected in ipairs({1,count}) do
   list:setSelection(selected,true)
   list:updatePositions(0,0)
   for i=2,count do
    local previous,current=list.members[i-1],list.members[i]
    assert(current.y>=previous.y+previous.height+20,'mobile rows overlap')
   end
   local item=list:getSelected()
   assert(item.y>=140 and item.y+item.height<=game.height-80,'selected difficulty is outside the usable area')
  end
  list:destroy()
 end
end)

check('translated difficulty lists use visible glyph bounds for touch', function()
 local list=MenuList(nil,false,'mobile')
 list.x,list.y=120,35
 local item=AtlasText(0,0,'Hard','bold')
 list:add(item)
 list:updatePositions(0,0)
 local x,y,w,h,sx,sy=item:_getBoundary()
 local tx,ty=list.x+x+w*sx/2,list.y+y+h*sy/2
 assert(list:touchOverObj(tx,ty,item),'visible difficulty does not accept touch')
 assert(not list:touchOverObj(tx-w*sx-1,ty,item),'touch outside difficulty hits')
 list:destroy()
end)

check('pause difficulties open separated on desktop and permit returning', function()
 local savedSong,savedDifficulty=PlayState.SONG,PlayState.songDifficulty
 local savedDevice=love.system.getDevice
 PlayState.SONG={song='bopeebo',difficulties={'Easy','Normal','Hard'}}
 PlayState.songDifficulty='Normal'
 love.system.getDevice=function() return 'Desktop' end
 local pause=PauseSubstate()
 love.system.getDevice=savedDevice
 pause:openDifficultyMenu()
 local first,second=pause.diffList.members[1],pause.diffList.members[2]
 assert(second.y>=first.y+first.height,'desktop difficulty rows start stacked')
 Tween.update(0.5)
 assert(pause.diffList.open and not pause.blockInput,'difficulty menu blocks the back action')
 pause:closeDifficultyMenu()
 assert(pause.diffList.lock and not pause.menuList.lock)
 Tween.update(0.5)
 pause:close()
 PlayState.SONG,PlayState.songDifficulty=savedSong,savedDifficulty
end)

check("a second finger opens pause options on the first tap", function()
	local getDevice = love.system.getDevice
	love.system.getDevice = function() return "Mobile" end
	local pause = PauseSubstate()
	love.system.getDevice = getDevice
	local list = pause.menuList
	local option
	for _, item in ipairs(list.members) do
		if tostring(item) == "Options" then option = item; break end
	end
	assert(option)
	list:updatePositions(0, 0)

	local x, y, w, h, sx, sy = option:_getBoundary()
	local windowWidth, windowHeight = love.graphics.getDimensions()
	local scale = math.min(windowWidth / game.width, windowHeight / game.height)
	local tx = (x + w * sx / 2) * scale + (windowWidth - game.width * scale) / 2
	local ty = (y + h * sy / 2) * scale + (windowHeight - game.height * scale) / 2
	local touch = game.touch
	touch.onPressed("held", 0, 0)
	touch.onPressed("tap", 0, 0)
	touch.onReleased("tap", tx, ty)
	list:handleTouch(0)
	touch.onReleased("held", 0, 0)
	touch.reset()

	assert(pause.optionsUI and pause.blockInput)
	pause:remove(pause.optionsUI)
	assert(not pause.blockInput and not list.lock)
	pause:close()
end)

check("a translated pause camera accepts taps across the visible option row", function()
	local getDevice = love.system.getDevice
	love.system.getDevice = function() return "Mobile" end
	local pause = PauseSubstate()
	pause.cameras = {Camera()}
	pause.cameras[1].zoom = 0.85
	pause.cameras[1].x = 48
	pause:enter()
	love.system.getDevice = getDevice
	pause:update(0)
	local list = pause.menuList
	local option = list.members[#list.members - 1]
	assert(tostring(option) == "Options")
	local _, y, _, h, _, sy = option:_getBoundary()
	local tx, ty = pause.cameras[1]:worldToScreen(game.width * 0.6, y + h * sy / 2)
	local w, height = love.graphics.getDimensions()
	local scale = math.min(w / game.width, height / game.height)
	tx = tx * scale + math.floor((w - game.width * scale) / 2)
	ty = ty * scale + math.floor((height - game.height * scale) / 2)
	game.touchpressed("pause-row", tx, ty, 0, 0, 1, 0)
	game.touchreleased("pause-row", tx, ty, 0, 0, 1, 0)
	pause:update(0)
	game.touch.reset()
	assert(pause.optionsUI and pause.blockInput)
	assert(game.touch.idMap["pause-row"] == nil)
	pause:remove(pause.optionsUI)
	pause:close()
end)

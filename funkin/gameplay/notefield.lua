local Notefield = ActorGroup:extend("Notefield")

local TimeIndex = require "funkin.backend.timeindex"

local EMPTY_NOTES = {}
local function sortActiveNotes(a, b) return a.time < b.time end

function Notefield:new(x, y, keys, skin, character, vocals, speed)
	if keys == nil then keys = 4 end
	if skin == nil then skin = "default" end
	if type(skin) ~= "table" or type(skin.getPath) ~= "function" then
		skin = (paths and paths.getSkin and paths.getSkin(skin)) or Skin(skin)
	end
	if speed == nil then speed = 1 end

	Notefield.super.new(self, x, y)

	self.__offsetX = 0
	self.noteWidth = 160 * 0.7
	self.height = 514
	self.keys = keys
	self.skin = skin and skin.data or Skin("default").data

	self.time, self.beat = 0, 0
	self.offsetTime = 0
	self.speed = speed
	self.drawSize = game.height * 2 + self.noteWidth
	self.drawSizeOffset = 0
	self.downscroll = ClientPrefs and ClientPrefs.data.downScroll or false
	self.canSpawnSplash = true

	self.character, self.vocals = character, vocals
	self.bot = false
	self.lastSustain = nil
	self.recentPresses = {}

	self.modifiers = {}

	self.lanes = {}
	self.receptors = {}

	self.chartNotes = {}
	self.activeNotes = {}
	self.removedNotes = {}
	self.chartIndex = 1
	self.spawnBuffer = 2.0
	self.lastSpawnTime = -math.huge

	self.noNoteRender = false

	self.state = game.getState()

	self.__topSprites = Group()
	for i = 1, keys do self:makeLane(i) end
	self:add(self.__topSprites)

	self.groupScale = Point(1, 1)
	self.groupOrigin = Point(0, 0)

	self:setWidth()
	self.groupOrigin:set(0, self.noteWidth / 2)
end

function Notefield:hideNotes(bool)
	self.noNoteRender = bool
	if not bool and not table.find(self.members, self.__topSprites) then
		self:add(self.__topSprites)
	elseif bool and table.find(self.members, self.__topSprites) then
		self:remove(self.__topSprites)
	end

	local pos = bool and -self.noteWidth / 2 or -self.height / 2
	for _, lane in pairs(self.lanes) do lane.receptor.y = pos end
end

function Notefield:setWidth(width, nwidth)
	nwidth = nwidth or (160 * 0.7)
	width = width or nwidth * self.keys
	self.width = width

	local half = math.floor(self.keys / 2)
	local lw, rw = nwidth * half, nwidth * (self.keys - half)
	local rx = width - rw

	for i = 1, self.keys do
		local sx, idx = i > half and rx or 0, i > half and i - half or i
		self.lanes[i].x = sx + nwidth * (idx - 1) + nwidth / 2
	end
end

function Notefield:makeLane(direction, y)
	local lane = ActorGroup(0, 0, 0, false)
	lane.receptor = Receptor(0, y or -self.height / 2, direction - 1, self.skin)
	lane.renderedNotes, lane.renderedNotesI = {}, {}
	lane.renderCandidates = {}
	lane.drawSize, lane.drawSizeOffset = 1, 0
	lane.speed = 1

	lane:add(lane.receptor)
	lane.receptor.lane = lane
	lane.receptor.parent = self

	self.receptors[direction] = lane.receptor
	self.lanes[direction] = lane
	self:add(lane)
	self.__topSprites:add(lane.receptor.covers)
	self.__topSprites:add(lane.receptor.splashes)
	return lane
end

function Notefield:makeNotesFromChart(notes)
	self:flushRemovedNotes()
	self.chartNotes = notes
	self.chartIndex = 1
	self.lastSpawnTime = -math.huge
	TimeIndex.sort(self.chartNotes)

	for _, note in ipairs(self.activeNotes) do
		if not self.removedNotes[note] and note.group then
			local lane = note.group
			table.delete(lane.renderedNotes, note)
			lane.renderedNotesI[note] = nil
		end
		if not self.removedNotes[note] then note:destroy() end
	end
	self.activeNotes = {}
	self.removedNotes = {}

	for _, lane in ipairs(self.lanes) do
		table.clear(lane.renderedNotes)
		table.clear(lane.renderedNotesI)
	end
end

function Notefield:seekTo(timeSec)
	timeSec = timeSec or 0
	local targetMs = timeSec * 1000
	self.chartIndex = 1
	self.lastSpawnTime = -math.huge
	if self.chartNotes then
		self.chartIndex = TimeIndex.lowerBound(self.chartNotes, targetMs - 5)
	end
	if self.activeNotes then
		for i = #self.activeNotes, 1, -1 do
			local note = self.activeNotes[i]
			if note.time < timeSec - 0.005 then
				self:removeNoteFromIndex(i)
				note:destroy()
			end
		end
	end
	self.time = timeSec or 0
end

function Notefield:getNotes(time, direction, sustainLoop, outBuffer)
	local notes = self.activeNotes
	if not notes or #notes == 0 then
		if outBuffer then table.clear(outBuffer); return outBuffer, false end
		return EMPTY_NOTES, false
	end

	local hitNotes = outBuffer
	if hitNotes then
		table.clear(hitNotes)
	else
		hitNotes = {}
	end

	local safeZoneOffset, i, started, hasSustain,
	forceHit, noteTime, prev, prevIdx = Note.safeZoneOffset, 1
	for _, note in ipairs(notes) do
		noteTime = note.time
		if not self.removedNotes[note] and not note.tooLate
			and (not note.ignoreNote or (note.psychIgnoreNote and not sustainLoop))
			and (direction == nil or note.direction == direction)
			and (note.lastPress
				or (sustainLoop and noteTime <= time)
				or (noteTime > time - safeZoneOffset * note.lateHitMult
					and noteTime < time + safeZoneOffset * note.earlyHitMult)) then
			forceHit = sustainLoop and not note.wasGoodSustainHit and note.sustain
			if forceHit then hasSustain = true end
			if forceHit or not note.wasGoodHit then
				prevIdx = i - 1
				prev = hitNotes[prevIdx]
				if prev and noteTime - prev.time <= 0.001 and note.sustainTime > prev.sustainTime then
					hitNotes[i] = prev
					hitNotes[prevIdx] = note
				else
					hitNotes[i] = note
				end
				i = i + 1
				started = true
			elseif started and not sustainLoop then
				break
			end
		end
	end

	return hitNotes, hasSustain
end

function Notefield:addNote(note)
	note.parent = self
	table.insert(self.activeNotes, note)
	return note
end

function Notefield:detachNote(note)
	if self.lastSustain == note then
		self.lastSustain = nil
	end
	note.lastPress = nil

	local lane = note.group
	if lane then
		note.group, lane.renderedNotesI[note] = nil
		lane:remove(note)
		table.delete(lane.renderedNotes, note)
	end
end

function Notefield:removeNoteFromIndex(idx)
	local note = self.activeNotes[idx]
	if note then return self:removeNote(note) end
end

function Notefield:removeNote(note)
	if note.parent == self and not self.removedNotes[note] then
		if self.lastSustain == note then self.lastSustain = nil end
		note.lastPress = nil
		self.removedNotes[note] = true
		return note
	end
end

function Notefield:flushRemovedNotes()
	local removed = self.removedNotes
	if not next(removed) then return end
	for _, lane in ipairs(self.lanes) do
		local members, write = lane.members, 1
		local count = #members
		for i = 1, count do
			local member = members[i]
			if removed[member] then
				if member.leave then member:leave(lane.group) end
			else
				members[write], write = member, write + 1
			end
		end
		for i = write, count do members[i] = nil end
		local rendered = lane.renderedNotes
		write, count = 1, #rendered
		for i = 1, count do
			local note = rendered[i]
			if removed[note] then
				note.group, lane.renderedNotesI[note] = nil, nil
			else
				rendered[write], write = note, write + 1
			end
		end
		for i = write, count do rendered[i] = nil end
	end
end

function Notefield:copyNotesFromNotefield(notefield)
	if notefield.chartNotes and #notefield.chartNotes > 0 then
		self.chartNotes = {}
		for i, chartNote in ipairs(notefield.chartNotes) do
			self.chartNotes[i] = {
				t = chartNote.t,
				d = chartNote.d,
				l = chartNote.l,
				k = chartNote.k,
				gf = chartNote.gf,
				character = chartNote.character
			}
		end
		self.chartIndex = 1
	else
		for i, note in ipairs(notefield.activeNotes) do
			local noteClone = note:clone()
			noteClone.parent = self
			table.insert(self.activeNotes, noteClone)
		end
	end

	table.sort(self.activeNotes, Conductor.sortByTime)
end

function Notefield:setSkin(skin)
	if self.skin == skin then return end

	self.skin = skin.data

	for _, receptor in ipairs(self.receptors) do
		receptor:setSkin(skin.data)
	end
	for _, note in ipairs(self.activeNotes) do
		note:setSkin(skin.data)
	end
end

function Notefield:fadeInReceptors(tween)
	for i = 1, #self.lanes do
		local receptor = self.lanes[i].receptor
		receptor.y = receptor.y - 10
		receptor.alpha = 0

		local func = function(...) return tween and tween:tween(...) or Tween.tween(...) end
		func(receptor, {y = receptor.y + 10, alpha = 1}, 1, {
			ease = "circOut",
			startDelay = 0.16 + (0.2 * i)
		})
	end
end

function Notefield:update(dt)
	if not self.lanes or not self.activeNotes then return end
	self:flushRemovedNotes()
	Notefield.super.update(self, dt)

	local horizon = Note.safeZoneOffset + 0.1
	for _, lane in ipairs(self.lanes) do
		local speed = self.speed * lane.speed
		local extent = self.drawSize * (lane.drawSize or 1) / 2
		local center = self.drawSizeOffset + (lane.drawSizeOffset or 0) - lane.receptor.y
		if speed == 0 then
			if center - extent <= 0 and center + extent >= 0 then horizon = math.huge end
		else
			local edge = speed > 0 and center + extent or center - extent
			horizon = math.max(horizon, edge / (450 * speed) + 0.1)
		end
	end
	self.spawnBuffer = horizon

	if #self.chartNotes > 0 and self.chartIndex <= #self.chartNotes then
		local currentTime = (self.time - self.offsetTime) * 1000
		local spawnTime = currentTime + self.spawnBuffer * 1000

		do
			self.lastSpawnTime = spawnTime
			local needsSort = false
			local prevMaxTime = #self.activeNotes > 0 and self.activeNotes[#self.activeNotes].time or -math.huge

			while self.chartIndex <= #self.chartNotes do
				local chartNote = self.chartNotes[self.chartIndex]
				if chartNote.t > spawnTime then break end

				local sustainTime = chartNote.l or 0
				if sustainTime ~= 0 then
					sustainTime = math.max(sustainTime / 1000, 0.125)
				end

				local note = Note(chartNote.t / 1000, chartNote.d % 4, sustainTime, chartNote.k, self.skin)
				note.parent = self
				note.gf = chartNote.gf

				table.insert(self.activeNotes, note)
				self.chartIndex = self.chartIndex + 1

				if self.state and self.state.scripts then
					self.state.scripts:call("noteSpawn", note)
				end

				if note.time < prevMaxTime then
					needsSort = true
				else
					prevMaxTime = note.time
				end
			end

			if needsSort and #self.activeNotes > 1 then
				table.sort(self.activeNotes, sortActiveNotes)
			end
		end
	end

	local timeNow = self.time - self.offsetTime
	local notes, count, write = self.activeNotes, #self.activeNotes, 1
	for read = 1, count do
		local note = notes[read]
		local ignored = note.psychIgnoreNote and note.ignoreNote
			and note.time + (note.sustainTime or 0) + Note.safeZoneOffset <= timeNow
		local consumed = ignored or note.tooLate or (note.wasGoodHit and (not note.sustain or note.wasGoodSustainHit))
		local lane = self.lanes[note.direction + 1]
		local passed = false
		if consumed and lane then
			local speed = self.speed * lane.speed * (note.speed or 1)
			local extent = self.drawSize * (lane.drawSize or 1) / 2 + 150
			local center = self.drawSizeOffset + (lane.drawSizeOffset or 0) - lane.receptor.y
			local ending = Note.toPos(note.time + (note.sustainTime or 0) - timeNow, speed)
			passed = speed > 0 and ending < center - extent or speed < 0 and ending > center + extent
		end
		if self.removedNotes[note] or passed or (ignored and lane and self.speed * lane.speed * (note.speed or 1) == 0) then
			if not self.removedNotes[note] then self:removeNote(note) end
		else
			notes[write] = note
			write = write + 1
		end
	end
	for i = write, count do notes[i] = nil end
	self:flushRemovedNotes()
	table.clear(self.removedNotes)

	for _, mod in pairs(self.modifiers) do mod:update(self.beat) end
end

function Notefield:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.width) / 2 end
	if axes:find("y") then self.y = game.height / 2 end
	if axes:find("z") then self.z = 0 end
	return self
end

function Notefield:getWidth()
	return self.width
end

function Notefield:getHeight()
	return self.noNoteRender and self.noteWidth or self.height
end

function Notefield:destroy()
	self:flushRemovedNotes()
	if self.activeNotes then
		for _, n in ipairs(self.activeNotes) do if not self.removedNotes[n] then n:destroy() end end
		self.activeNotes = nil
	end

	if self.lanes then
		for _, l in ipairs(self.lanes) do
			if l.renderedNotes then table.clear(l.renderedNotes) end
			l.renderedNotes, l.renderedNotesI, l.renderCandidates, l.receptor = nil, nil, nil, nil
		end
	end

	Notefield.super.destroy(self)

	self.modifiers = nil
	self.receptors = nil
	self.lanes = nil
	self.chartNotes = nil
end

local function compactRendered(lane, keep)
 local rendered, departed = lane.renderedNotes, lane._departedNotes or {}
 lane._departedNotes = departed
 local write, count = 1, #rendered
 for i = 1, count do
  local note = rendered[i]
  if keep and keep[note] then
   rendered[write], write = note, write + 1
  elseif note.group == lane then
   note.group = nil
   departed[note] = true
  end
 end
 for i = write, count do rendered[i] = nil end
 if next(departed) then
  local members = lane.members
  write, count = 1, #members
  for i = 1, count do
   local member = members[i]
   if departed[member] then
    if member.leave then member:leave(lane.group) end
   else
    members[write], write = member, write + 1
   end
  end
  for i = write, count do members[i] = nil end
  table.clear(departed)
 end
end

function Notefield:prepareGraphics(camera)
 local SceneJob = require "funkin.backend.scenejob"
 local canvas = love.graphics.newCanvas(8, 8)
 for direction = 0, self.keys - 1 do
  local note = Note(0, direction, 1, nil, self.skin)
  note.parent, note.group = self, self.lanes[direction + 1]
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  local ok, err = pcall(note.__render, note, camera or game.camera)
  love.graphics.pop()
  note:destroy()
  if not ok then canvas:release();error(err, 0) end
  SceneJob.checkpoint("Preparing note graphics")
 end
 canvas:release()
end

function Notefield:__prepareLane(direction, lane, time, candidates)
	if self.noNoteRender then
		compactRendered(lane)
		return
	end

	if not self.activeNotes then return end
	local notes, receptor, speed, drawSize, drawSizeOffset =
		candidates or self.activeNotes, lane.receptor,
		self.speed * lane.speed,
		self.drawSize * (lane.drawSize or 1),
		self.drawSizeOffset + (lane.drawSizeOffset or 0)

	local size, renderedNotes, renderedNotesI = #notes, lane.renderedNotes, lane.renderedNotesI
	table.clear(renderedNotesI)

	if size == 0 then
		compactRendered(lane)
		return
	end

	local repy = receptor.y
	local offset = -drawSize / 2 - repy + drawSizeOffset
	local farEdge = drawSize / 2 - repy + drawSizeOffset

	for noteI = 1, size do
		local note = notes[noteI]
		if not self.removedNotes[note] and note.direction == direction then
			local noteSpeed = (note.speed or 1) * speed
			local head = Note.toPos(note.time - time, noteSpeed)
			local tail = Note.toPos(note.time + (note.sustainTime or 0) - time, noteSpeed)
			if math.max(head, tail) >= offset and math.min(head, tail) <= farEdge then
				renderedNotesI[note] = true
				local prevlane = note.group
				if prevlane ~= lane then
					if prevlane then prevlane:remove(note) end
					table.insert(renderedNotes, note)
					lane:add(note)
					note.group = lane
				end

			end
		end
	end

	compactRendered(lane, renderedNotesI)
end

function Notefield:_prepareCameraDraw(camera, force)
	if not self.lanes or not self.activeNotes then return EMPTY_NOTES end
	if not force and self.__cameraRenderQueue[camera] then return self.__cameraRenderQueue[camera] end
	self:flushRemovedNotes()
	local time = self.time - self.offsetTime
	if not self.noNoteRender then
		for _, note in ipairs(self.activeNotes) do
			local lane = self.lanes[note.direction + 1]
			if lane then
				local candidates = lane.renderCandidates
				candidates[#candidates + 1] = note
			end
		end
	end
	for i, lane in ipairs(self.lanes) do
		self:__prepareLane(i - 1, lane, time, lane.renderCandidates)
		table.clear(lane.renderCandidates)
	end
	return Notefield.super._prepareCameraDraw(self, camera, force)
end

function Notefield:__render(camera)
	if not self.lanes or not self.activeNotes then return end
	self:_prepareCameraDraw(camera)
	local time = self.time - self.offsetTime
	for _, lane in ipairs(self.lanes) do
		lane._drawSize, lane._drawSizeOffset = lane.drawSize, lane.drawSizeOffset
		lane.drawSize = self.drawSize * (lane.drawSize or 1)
		lane.drawSizeOffset = self.drawSizeOffset + (lane.drawSizeOffset or 0)
		local rotations = lane.receptor.noteRotations
		local speed = self.speed * lane.speed
		for _, note in ipairs(lane.renderedNotes) do
			note._rx, note._ry, note._rz, note._speed = note.rotation.x, note.rotation.y, note.rotation.z, note.speed
			note._targetTime, note.speed = time, note._speed * speed
			note.rotation.x, note.rotation.y, note.rotation.z = note._rx + rotations.x,
				note._ry + rotations.y, note._rz + rotations.z
		end
	end
	love.graphics.push()
	love.graphics.translate(self.groupOrigin.x, self.groupOrigin.y)
	love.graphics.scale(self.groupScale.x, self.groupScale.y)
	love.graphics.translate(-self.groupOrigin.x, -self.groupOrigin.y)

	for _, mod in pairs(self.modifiers) do if mod.apply then mod:apply(self) end end
	if self.downscroll then self.scale.y = -self.scale.y end
	self.x = self.x - self.__offsetX
	Notefield.super.__render(self, camera)
	self.x = self.x + self.__offsetX
	if self.downscroll then self.scale.y = -self.scale.y end
	NoteModifier.discard()

	for _, lane in ipairs(self.lanes) do
		lane.drawSize, lane.drawSizeOffset = lane._drawSize, lane._drawSizeOffset
		for _, note in ipairs(lane.renderedNotes) do
			note.speed, note.rotation.x, note.rotation.y, note.rotation.z = note._speed, note._rx, note._ry, note._rz
		end
	end
	love.graphics.pop()
end

return Notefield

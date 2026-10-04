local Signal = Basic:extend("Signal")

function Signal:new()
	self.listeners = {}
	self.onceCalls = {}
end

function Signal:add(listener, once)
	table.insert(self.listeners, listener)
	if once then self.onceCalls[listener] = true end
end

function Signal:addOnce(listener)
	self:add(listener, true)
end

function Signal:remove(listener)
	table.delete(self.listeners, listener)
	if listener ~= nil then self.onceCalls[listener] = nil end
end

function Signal:dispatch(...)
	-- Callbacks may change subscriptions. New listeners wait for the next event.
	local listeners = {}
	for i, listener in ipairs(self.listeners) do listeners[i] = listener end
	for _, listener in ipairs(listeners) do
		if table.find(self.listeners, listener) then
			if self.onceCalls[listener] then self:remove(listener) end
			local ok, err = pcall(listener, ...)
			if not ok then print(err) end
		end
	end
end

function Signal:destroy()
	table.clear(self.listeners)
	table.clear(self.onceCalls)
	Signal.super.destroy(self)
end

return Signal

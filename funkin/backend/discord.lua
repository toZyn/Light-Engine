local success, DiscordActivity = pcall(require, "lib.discord")

---@class Discord
local Discord = {}

Discord.isInitialized = false
Discord.clientID = "1098761843956273304"

local _options = {
	details = "Starting",
	state = nil,

	assets = {
		large_image = "icon",
		large_text = "FNF LÖVE"
	}
}

function Discord.init()
	if success then
		DiscordActivity.start(Discord.clientID, true, function()
			DiscordActivity.setActivity(_options)
		end)

		Logger.log("debug", "Discord Activity started")
		Discord.isInitialized = true
	end
end

function Discord.shutdown()
	if success then
		DiscordActivity.shutdown()
	end
end

function Discord.changePresence(options)
	if success then
		if not Discord.isInitialized then return end
		_options = options or {}
		_options.assets = options.assets or {}
		_options.assets.large_image = options.assets.large_image or "icon"
		_options.assets.large_text = options.assets.large_text or "FNF LÖVE"

		DiscordActivity.setActivity(_options)
	end
end

function Discord.update()
	if success then
		DiscordActivity.update()
	end
end

return Discord

local statusLabel

local function formatStatus(enabled)
	return "Bonus Bop: " .. (enabled and "ON" or "OFF")
end

function postCreate()
	local enabled = Mod.loadData("bonusBop", true)
	statusLabel = Mod.text("bonus_status", formatStatus(enabled), 16, game.height - 44, {
		size = 18,
		color = "#38BDF8",
		scroll = 0
	})

	Mod.addMenuButton("bonusbop", "bonus bop", function()
		enabled = not Mod.loadData("bonusBop", true)
		Mod.saveData("bonusBop", enabled)
		if statusLabel then
			statusLabel.content = formatStatus(enabled)
		end
		return true
	end, {stay = true})
end

function leave()
	Mod.remove("bonus_status")
	statusLabel = nil
end

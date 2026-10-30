local GlobalScripts = {scripts = {}}

local function setIdentity(title, icon)
	if title then love.window.setTitle(tostring(title)) end
	if icon then
		local iconPath = paths.getPath(icon)
		if paths.exists(iconPath, "file") then
			local ok, imgData = pcall(love.image.newImageData, iconPath)
			if ok and imgData then
				love.window.setIcon(imgData)
			end
		end
	end
end

function GlobalScripts.reload()
	local oldScripts = {}
	for _, scr in pairs(GlobalScripts.scripts) do
		oldScripts[scr.path] = scr
	end
	table.clear(GlobalScripts.scripts)

	local sameMod = Mods.currentMod == GlobalScripts.currentMod
	local addonsUnchanged = true
	local newScripts = {}

	if Addons and Addons.all then
		for _, addon in ipairs(Addons.all) do
			local path = Addons.root .. "/" .. addon.path .. "/global.lua"
			local scriptLoaded = oldScripts[path] ~= nil

			if addon.active then
				if paths.exists(path, "file") then
					if not scriptLoaded then
						local script = Script(path, false, true, true)
						table.insert(GlobalScripts.scripts, script)
						table.insert(newScripts, script)
						addonsUnchanged = false
					else
						table.insert(GlobalScripts.scripts, oldScripts[path])
						oldScripts[path] = nil
					end
				end
			else
				if scriptLoaded then
					oldScripts[path]:close()
					addonsUnchanged = false
				end
			end
		end
	end

	if Mods and Mods.currentMod then
		local path = Mods.root .. "/" .. Mods.currentMod .. "/global.lua"
		if paths.exists(path, "file") then
			if not sameMod or not oldScripts[path] then
				local script = Script(path, false, true, true)
				table.insert(GlobalScripts.scripts, script)
				table.insert(newScripts, script)
				addonsUnchanged = false
			else
				table.insert(GlobalScripts.scripts, oldScripts[path])
				oldScripts[path] = nil
			end
		end
	end

	for _, scr in pairs(oldScripts) do
		scr:close()
		addonsUnchanged = false
	end
	if sameMod and addonsUnchanged then return end

	if not sameMod and Project and Project.title then
		pcall(love.window.setTitle, Project.title)
	end

	GlobalScripts.set("setIdentity", setIdentity)
	GlobalScripts.currentMod = Mods and Mods.currentMod or nil

	for _, script in ipairs(newScripts) do
		script:call("init")
	end
end

function GlobalScripts.call(func, ...)
	for _, s in ipairs(GlobalScripts.scripts) do
		s:call(func, ...)
	end
end

function GlobalScripts.set(var, value)
	for _, s in ipairs(GlobalScripts.scripts) do
		s:set(var, value)
	end
end

return GlobalScripts

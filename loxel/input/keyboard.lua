local Keyboard = {
	---@class Keys
	keys = {
		ANY = nil,
		A = "a",
		B = "b",
		C = "c",
		D = "d",
		E = "e",
		F = "f",
		G = "g",
		H = "h",
		I = "i",
		J = "j",
		K = "k",
		L = "l",
		M = "m",
		N = "n",
		O = "o",
		P = "p",
		Q = "q",
		R = "r",
		S = "s",
		T = "t",
		U = "u",
		V = "v",
		W = "w",
		X = "x",
		Y = "y",
		Z = "z",
		ZERO = "0",
		ONE = "1",
		TWO = "2",
		THREE = "3",
		FOUR = "4",
		FIVE = "5",
		SIX = "6",
		SEVEN = "7",
		EIGHT = "8",
		NINE = "9",
		PAGEUP = "pageup",
		PAGEDOWN = "pagedown",
		HOME = "home",
		END = "end",
		INSERT = "insert",
		ESCAPE = "escape",
		MINUS = "-",
		PLUS = "+",
		EQUAL = "=",
		DELETE = "delete",
		BACKSPACE = "backspace",
		LBRACKET = "[",
		RBRACKET = "]",
		BACKSLASH = "\\",
		CAPSLOCK = "capslock",
		SCROLL_LOCK = "scrolllock",
		NUMLOCK = "numlock",
		SEMICOLON = ";",
		QUOTE = "\'",
		ENTER = "return",
		SHIFT = "shift",
		COMMA = ",",
		PERIOD = ".",
		SLASH = "/",
		GRAVEACCENT = "`",
		CONTROL = "ctrl",
		ALT = "alt",
		SPACE = "space",
		UP = "up",
		DOWN = "down",
		LEFT = "left",
		RIGHT = "right",
		TAB = "tab",
		WINDOWS = "windows",
		MENU = "menu",
		PRINTSCREEN = "printscreen",
		BREAK = "pause",
		F1 = "f1",
		F2 = "f2",
		F3 = "f3",
		F4 = "f4",
		F5 = "f5",
		F6 = "f6",
		F7 = "f7",
		F8 = "f8",
		F9 = "f9",
		F10 = "f10",
		F11 = "f11",
		F12 = "f12",
		NUMPADZERO = "kp0",
		NUMPADONE = "kp1",
		NUMPADTWO = "kp2",
		NUMPADTHREE = "kp3",
		NUMPADFOUR = "kp4",
		NUMPADFIVE = "kp5",
		NUMPADSIX = "kp6",
		NUMPADSEVEN = "kp7",
		NUMPADEIGHT = "kp8",
		NUMPADNINE = "kp9",
		NUMPADMINUS = "kp-",
		NUMPADPLUS = "kp+",
		NUMPADPERIOD = "kp.",
		NUMPADMULTIPLY = "kp*",
		NUMPADSLASH = "kp/",
		MODE = "mode"
	},

	---@class {Key}
	keyValues = {},

	---@class justPressed:Keys
	justPressed = {},

	---@class pressed:Keys
	pressed = {},

	---@class justReleased:Keys
	justReleased = {},

	---@class released:Keys
	released = {},

	---@class modifierActive:Keys
	modifierActive = {
		CAPSLOCK = false,
		SCROLL_LOCK = false,
		NUMLOCK = false,
		MODE = false
	},

	---@type {}
	input = {
		---@class {string}
		justPressed = {},

		---@class {string}
		pressed = {},

		---@class {string}
		justReleased = {},

		---@class {string}
		released = {},
	},

	---@type {}
	loveInput = {
		---@class {string}
		justPressed = {},

		---@class {string}
		pressed = {},

		---@class {string}
		justReleased = {},

		---@class {string}
		released = {},
	}
}

local invalidKeys = {
	escape = true, shift = true, windows = true, alt = true, ctrl = true,
	pageup = true, pagedown = true, home = true, ["end"] = true, insert = true,
	delete = true, backspace = true, capslock = true, scrolllock = true,
	numlock = true, ["return"] = true, left = true, down = true, up = true,
	right = true, tab = true, menu = true, printscreen = true, pause = true,
	f1 = true, f2 = true, f3 = true, f4 = true, f5 = true, f6 = true,
	f7 = true, f8 = true, f9 = true, f10 = true, f11 = true, f12 = true
}
local shiftKeys = {
	["0"] = "!",
	["1"] = "@",
	["2"] = "#",
	["3"] = "$",
	["4"] = "%",
	["5"] = "^",
	["6"] = "&",
	["7"] = "*",
	["8"] = "(",
	["9"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	[";"] = ":",
	["'"] = '"',
	["`"] = "~",
	[","] = "<",
	["."] = ">",
	["/"] = "?",
	["\""] = "|"
}

for key, value in pairs(Keyboard.keys) do
	Keyboard.keyValues[value] = key
	Keyboard.released[key] = true
end


-- since key presses are asynchronous, those signals
-- can track them immediately, different from table checking,
-- that doesnt works at all on faster keypresses.
Keyboard.onPress = Signal()
Keyboard.onRelease = Signal()

function Keyboard.reset()
	table.clear(Keyboard.justPressed)
	table.clear(Keyboard.justReleased)
	table.clear(Keyboard.input.justPressed)
	table.clear(Keyboard.input.justReleased)
	table.clear(Keyboard.loveInput.justPressed)
	table.clear(Keyboard.loveInput.justReleased)

	if love.keyboard.isModifierActive then
		for key in pairs(Keyboard.modifierActive) do
			Keyboard.modifierActive[key] = love.keyboard.isModifierActive(Keyboard.keys[key])
		end
	end
end

local function normalizeKey(key)
	if key == 'kpenter' then return 'return' end
	if key == 'lshift' or key == 'rshift' then return 'shift' end
	if key == 'lgui' or key == 'rgui' then return 'windows' end
	if key == 'lalt' or key == 'ralt' then return 'alt' end
	if key == 'lctrl' or key == 'rctrl' then return 'ctrl' end
	return key
end

function Keyboard.onPressed(key)
	Keyboard.loveInput.justPressed[key] = true
	Keyboard.loveInput.pressed[key] = true
	Keyboard.loveInput.released[key] = nil

	local normKey = normalizeKey(key)
	if not invalidKeys[normKey] then
		local inputKey = normKey
		if inputKey == 'space' then
			inputKey = ' '
		elseif inputKey:startsWith('kp') and not Keyboard.modifierActive.NUMLOCK then
			inputKey = inputKey:gsub('kp', '')
		end
		if Keyboard.pressed.SHIFT and shiftKeys[inputKey] then
			inputKey = shiftKeys[inputKey]
		end

		Keyboard.input.justPressed[inputKey] = true
		Keyboard.input.pressed[inputKey] = true
		Keyboard.input.released[inputKey] = nil
	end

	key = normKey
	if key == "=" then key = "+" end

	local value = Keyboard.keyValues[key]
	if not value then return end
	Keyboard.justPressed[value] = true
	Keyboard.pressed[value] = true
	Keyboard.released[value] = nil

	Keyboard.onPress:dispatch(value)

	Keyboard.justPressed.ANY = true
	Keyboard.pressed.ANY = true
	Keyboard.released.ANY = nil
end

function Keyboard.onReleased(key)
	Keyboard.loveInput.justReleased[key] = true
	Keyboard.loveInput.released[key] = true
	Keyboard.loveInput.pressed[key] = nil

	local normKey = normalizeKey(key)
	if not invalidKeys[normKey] then
		local inputKey = normKey
		if inputKey == 'space' then
			inputKey = ' '
		elseif inputKey:startsWith('kp') and not Keyboard.modifierActive.NUMLOCK then
			inputKey = inputKey:gsub('kp', '')
		end
		if Keyboard.pressed.SHIFT and shiftKeys[inputKey] then
			inputKey = shiftKeys[inputKey]
		end

		Keyboard.input.justReleased[inputKey] = true
		Keyboard.input.released[inputKey] = true
		Keyboard.input.pressed[inputKey] = nil
	end

	key = normKey
	if key == "=" then key = "+" end

	local value = Keyboard.keyValues[key]
	if not value then return end
	Keyboard.pressed[value] = nil
	Keyboard.justReleased[value] = true
	Keyboard.released[value] = true

	Keyboard.onRelease:dispatch(value)

	Keyboard.pressed.ANY = nil
	Keyboard.justReleased.ANY = true
	Keyboard.released.ANY = true
end

return Keyboard

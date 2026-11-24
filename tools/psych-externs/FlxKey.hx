/**
 * Keyboard scancodes. Psych maps a script's `'left'`/`'a'` string to one of these
 * before reading FlxG.keys.
 */
extern enum abstract FlxKey(Int) {
	public var A; public var B; public var C; public var D; public var E; public var F;
	public var G; public var H; public var I; public var J; public var K; public var L;
	public var M; public var N; public var O; public var P; public var Q; public var R;
	public var S; public var T; public var U; public var V; public var W; public var X;
	public var Y; public var Z;
	public var ZERO; public var ONE; public var TWO; public var THREE; public var FOUR;
	public var FIVE; public var SIX; public var SEVEN; public var EIGHT; public var NINE;
	public var LEFT; public var RIGHT; public var UP; public var DOWN;
	public var SPACE; public var ENTER; public var ESCAPE; public var BACKSPACE;
	public var TAB; public var SHIFT; public var CONTROL; public var ALT;
	public var NUMPADONE; public var NUMPADTWO;
	public static function fromString(key:String):FlxKey;
}

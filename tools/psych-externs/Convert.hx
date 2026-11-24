/**
 * The Haxe-to-Lua bridge. `toLua` pushes a Haxe value onto the Lua stack and
 * `fromLua` reads one back.
 *
 * Everything else in Psych's Lua layer passes plain Haxe values around, so this
 * is the only place where the two worlds actually meet.
 */
extern class Convert {
	public static function toLua(lua:State, val:Dynamic):Void;
	public static function fromLua(lua:State, index:Int):Dynamic;
	public static function cToLua(lua:State):Void;
}

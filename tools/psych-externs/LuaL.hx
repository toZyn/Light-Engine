/**
 * The Lua auxiliary library. Psych uses it to open a state, load the standard
 * libraries and run a script by name.
 *
 * `dostring`/`dofile` return a status code that Psych turns into an error
 * message, so the variants that throw are not needed here.
 */
extern class LuaL {
	public static function newstate():State;
	public static function openlibs(lua:State):Void;
	public static function dostring(lua:State, str:String):Int;
	public static function dofile(lua:State, filename:String):Int;
	public static function loadstring(lua:State, str:String):Int;
	public static function loadfile(lua:State, filename:String):Int;
}

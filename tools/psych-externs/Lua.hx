/**
 * The Lua C API's value-type tags. Psych switches on them when it reports a
 * value's type back to a script.
 *
 * These are inline constants in Haxe's own Lua externs, which is also why they
 * can be used as switch patterns.
 */
extern class Lua {
	public static inline var LUA_TNONE:Int = -1;
	public static inline var LUA_TNIL:Int = 0;
	public static inline var LUA_TBOOLEAN:Int = 1;
	public static inline var LUA_TLIGHTUSERDATA:Int = 2;
	public static inline var LUA_TNUMBER:Int = 3;
	public static inline var LUA_TSTRING:Int = 4;
	public static inline var LUA_TTABLE:Int = 5;
	public static inline var LUA_TFUNCTION:Int = 6;
	public static inline var LUA_TUSERDATA:Int = 7;
	public static inline var LUA_TTHREAD:Int = 8;
}

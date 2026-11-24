/**
 * Psych's `FunkinLua` instance, as the per-file `implement(funk:FunkinLua)`
 * helpers actually use it: it owns the Lua state and the shader cache, and it
 * is where every callback is registered.
 *
 * Declared from the call sites in `source/psychlua/*.hx`, which touch exactly
 * these five members.
 */
extern class FunkinLua {
	public var lua:State;
	public var runtimeShaders:Map<String, Array<String>>;
	public function addLocalCallback(name:String, myFunction:Dynamic):Void;
	public function initLuaShader(name:String):Bool;
	public static function luaTrace(text:String, ?ignoreCheck:Bool = false, ?ignoreDisabled:Bool = false, ?color:Int = 0):Void;
}

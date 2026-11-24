package psychlua;

/**
 * Psych's Haxe-script host. A Lua script can spawn one, so FunkinLua holds a
 * reference and destroys it when it stops.
 */
extern class HScript {
	public var origin:String;
	public var modFolder:String;
	public function new(?path:String, ?name:String):Void;
	public function destroy():Void;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic;
	public function set(variable:String, data:Dynamic):Void;
}

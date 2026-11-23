/**
 * The outside world Psych's Lua layer expects.
 *
 * Derived mechanically from ShadowMario/FNF-PsychEngine 1.0.4
 * `source/psychlua/*.hx` (see tools/build_psych_lua.py, which regenerates the
 * member list). Members are declared exactly as Psych calls them; anything not
 * listed here is something Psych does not use from that class.
 *
 * These are `extern` classes: Haxe emits `Paths.image(...)`, `FlxG.width`, ...
 * as calls into Lua globals of the same name, which the engine bridges.
 */

/* ------------------------------------------------------------------ paths */
extern class Paths {
	public static function image(key:String, ?allowGPU:Bool = true):Dynamic;
	public static function sound(key:String, ?logError:Bool = true):Dynamic;
	public static function music(key:String, ?logError:Bool = true):Dynamic;
	public static function video(key:String, ?library:String):Dynamic;
	public static function font(key:String):String;
	public static function getPath(file:String, ?library:String, ?modsAllowed:Bool = true):String;
	public static function getSharedPath(file:String):String;
	public static function mods(key:String):String;
	public static function formatToSongPath(path:String):String;
	public static function getSparrowAtlas(key:String, ?library:String):Dynamic;
	public static function getPackerAtlas(key:String, ?library:String):Dynamic;
	public static function getAsepriteAtlas(key:String, ?library:String):Dynamic;
	public static function getAtlas(key:String, ?library:String):Dynamic;
	public static function getMultiAtlas(keys:Array<String>, ?library:String):Dynamic;
	public static function loadAnimateAtlas(sprite:Dynamic, folder:String, ?sprite:String, ?animation:String):Dynamic;
	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false, ?ignoredFolders:Array<String> = null):String;
}

/* ---------------------------------------------------------------- flixel */
extern class FlxG {
	public static var width:Int;
	public static var height:Int;
	public static var camera:FlxCamera;
	public static var state:Dynamic;
	public static var keys:Dynamic;
	public static var mouse:Dynamic;
	public static var gamepads:Dynamic;
	public static var sound:Dynamic;
	public static var save:Dynamic;
	public static function log(data:Dynamic):Void;
	public static function random(?min:Int, ?max:Int):Float;
	public static function overlap(?object1:Dynamic, ?object2:Dynamic, ?notifyCallback:Dynamic):Bool;
}

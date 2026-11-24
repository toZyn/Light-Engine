extern class FlxG {
	public static var width:Int;
	public static var height:Int;
	public static var camera:FlxCamera;
	public static var state:Dynamic;
	public static var keys:Dynamic;
	public static var mouse:Dynamic;
	public static var gamepads:Dynamic;
	public static var sound:FlxSoundManager;
	public static var save:FlxSave;
	public static function log(data:Dynamic):Void;
	public static var random:FlxRandom;
	public static function overlap(?object1:Dynamic, ?object2:Dynamic, ?notifyCallback:Dynamic):Bool;
}

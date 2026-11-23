/**
 * Psych's resource resolver. Every asset a Lua script names goes through here,
 * which is why the engine only has to answer "where is this file" once.
 */
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

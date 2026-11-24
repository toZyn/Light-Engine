/**
 * Psych's resource resolver. Every asset a Lua script names goes through here,
 * which is why the engine only has to answer "where is this file" once.
 *
 * Signatures copied from Psych 1.0.4 `source/backend/Paths.hx`. The second
 * argument is a *parent folder*, and `getPath`'s is an asset type — not a
 * library name, which is the easy mistake to make from the call sites.
 */
extern class Paths {
	public static function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):Dynamic;
	public static function sound(key:String, ?modsAllowed:Bool = true):Dynamic;
	public static function music(key:String, ?modsAllowed:Bool = true):Dynamic;
	public static function video(key:String):Dynamic;
	public static function font(key:String):String;
	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String;
	public static function getSharedPath(file:String = ''):String;
	public static function getFolderPath(file:String, folder:String = 'shared'):String;
	public static function mods(key:String = ''):String;
	public static function modsJson(key:String):String;
	public static function modsImages(key:String):String;
	public static function modsSounds(path:String, key:String):String;
	public static function modsTxt(key:String):String;
	public static function formatToSongPath(path:String):String;
	public static function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):Dynamic;
	public static function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):Dynamic;
	public static function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):Dynamic;
	public static function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):Dynamic;
	public static function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):Dynamic;
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, ?spriteJson:Dynamic = null, ?animationJson:Dynamic = null):Void;
	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false):String;
	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null):Bool;
}

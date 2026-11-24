/**
 * Psych's difficulty list. A script reads the current one by name and by file
 * path, which are different strings.
 */
extern class Difficulty {
	public static function getString(?translated:Bool = false):String;
	public static function getFilePath():String;
	public static function listFromString(?string:String):Int;
	public static var list:Array<Dynamic>;
}

/**
 * Psych's small formatting helpers, used whenever a script passes a colour or a
 * border style as a string.
 */
extern class CoolUtil {
	public static function colorFromString(color:String):Int;
	public static function setTextBorderFromString(text:FlxText, border:String):Void;
	public static function parseSpeed(speed:Float):String;
	public static function dashToSpace(string:String):String;
	public static function sortByHighestNumber(a:Dynamic, b:Dynamic):Int;
}

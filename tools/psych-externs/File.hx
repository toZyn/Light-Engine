/**
 * File reads and writes, as Psych uses them for save files and mod data.
 */
extern class File {
	public static function getContent(path:String):String;
	public static function saveContent(path:String, content:String):Void;
	public static function getBytes(path:String):haxe.io.Bytes;
}

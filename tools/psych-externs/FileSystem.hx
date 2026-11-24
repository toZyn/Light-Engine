/**
 * Directory and file queries. Psych asks these before touching a mod file, so a
 * missing one is reported as false instead of throwing.
 */
extern class FileSystem {
	public static function exists(path:String):Bool;
	public static function deleteFile(path:String):Bool;
	public static function readDirectory(path:String):Array<String>;
	public static function createDirectory(path:String):Void;
}

/**
 * openfl's runtime entry point. Psych reads the current frame rate from it.
 */
extern class Lib {
	public static var current:Lib;
	public var stage:Dynamic;
	public static var application:Application;
	public static function getTimer():Int;
}

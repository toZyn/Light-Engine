/**
 * The splash that plays when a note is hit. The skin name is split into a
 * prefix and a postfix a script can read.
 */
extern class NoteSplash extends FlxSprite {
	public static var defaultNoteSplash:String;
	public static function getSplashSkinPostfix():String;
	public static function getSplashSkin(?texture:String):String;
	public function setupNoteSplash(x:Float, y:Float, noteData:Int, ?texture:String = '', ?hueColor:Int, ?note:Note):Void;
}

/**
 * The splash that plays when a note is hit.
 */
extern class NoteSplash extends FlxSprite {
	public static var defaultNoteSplash:String;
	public function setupNoteSplash(x:Float, y:Float, noteData:Int, ?texture:String, ?hueColor:Int, ?note:Note):Void;
}

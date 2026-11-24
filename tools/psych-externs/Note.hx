/**
 * A note in the chart. Psych reads and writes its fields when a script changes
 * a note mid-song, which is what note skins and RGB notes do.
 */
extern class Note extends FlxSprite {
	public function new(?strumTime:Float = 0, ?noteData:Int = 0, ?mustPress:Bool = false, ?sustainLength:Float = 0, ?altAnim:Bool = false, ?susLength:Float = 0, ?isSustainNote:Bool = false);
	public var strumTime:Float;
	public var noteData:Int;
	public var mustPress:Bool;
	public var sustainLength:Float;
	public var isSustainNote:Bool;
	public var noteType:String;
	public var noteSpeed:Float;
	public var offsetX:Float;
	public var offsetY:Float;
	public var prevNote:Note;
	public var nextNote:Note;
	public static var swagWidth:Float;
	public static function getNoteSkinPostfix():String;
}

/**
 * A receptor. Scripts address these by index, so Psych needs their direction and
 * animation state.
 */
extern class StrumNote extends FlxSprite {
	public var noteData:Int;
	public var player:Int;
	public function playAnim(anim:String, ?force:Bool = false):Void;
	public function resetX():Void;
}

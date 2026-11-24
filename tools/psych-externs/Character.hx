/**
 * A character sprite. Scripts change its animations and offsets all the time,
 * so its animation controller and holding state are part of the surface.
 */
extern class Character extends FlxSprite {
	public var curCharacter:String;
	public var animationsArray:Array<Dynamic>;
	public var holdTimer:Float;
	public var debugMode:Bool;
	public function playAnim(animName:String, ?force:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void;
	public function dance(?ignoreDance:Bool = false):Void;
	public function hasAnimation(anim:String):Bool;
}

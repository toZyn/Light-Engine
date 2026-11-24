/**
 * flxanimate's sprite, which plays Aseprite animations instead of sparrow
 * frames.
 */
extern class FlxAnimate extends FlxSprite {
	public var anim:Dynamic;
	public function loadAtlas(path:String, ?sprite:String, ?animation:String):Void;
	public function playAnimation(name:String, ?loop:Bool = true, ?restart:Bool = false):Void;
}

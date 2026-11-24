/**
 * The cutscene video sprite. Psych assigns the result of PlayState.startVideo to
 * it, so the two types have to agree.
 */
extern class VideoSprite extends FlxSprite {
	public var videoSprite:Dynamic;
	public var finished:Bool;
	public var bitrate:Float;
	public var time:Float;
	public var length:Float;
	public function stopVideo():Void;
	public function playVideo():Void;
}

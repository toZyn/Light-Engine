/**
 * The cutscene video sprite. A script reads whether one is playing and can set
 * its playback rate.
 */
extern class VideoSprite extends FlxSprite {
	public var videoSprite:Dynamic;
	public var finished:Bool;
	public var bitrate:Float;
	public function stopVideo():Void;
}

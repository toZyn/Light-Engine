/**
 * A sprite's animation controller. Psych walks `frames` to read the sheet's
 * frame count and to add animations by index.
 */
extern class FlxAnimationController {
	public var frames:Int;
	public var name:String;
	public var curAnim:Dynamic;
	public var paused:Bool;
	public var finished:Bool;
	public function add(name:String, frames:Array<Int>, ?frameRate:Float = 30, ?looped:Bool = true, ?flipX:Bool = false, ?flipY:Bool = false):Void;
	public function addByPrefix(name:String, prefix:String, ?frameRate:Float = 30, ?looped:Bool = true, ?flipX:Bool = false, ?flipY:Bool = false):Void;
	public function play(name:String, ?force:Bool = true, ?reversed:Bool = false, ?frame:Int = -1):Void;
	public function stop():Void;
	public function exists(name:String):Bool;
}

/**
 * An animation registered on that controller.
 */
extern class FlxAnimation {
	public var name:String;
	public var numFrames:Int;
	public var curFrame:Int;
	public var frameRate:Float;
	public var looped:Bool;
	public var paused:Bool;
}

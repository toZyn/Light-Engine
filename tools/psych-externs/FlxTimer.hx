/**
 * A repeating timer. A script reads how many loops are left and whether it has
 * finished, which is how `timerFinished` style checks work.
 */
extern class FlxTimer extends FlxBasic {
	public function new();
	public static var globalManager:Dynamic;
	public var finished:Bool;
	public var loops:Int;
	public var loopsLeft:Int;
	public var time:Float;
	public function start(?time:Float = 1, ?loops:Int = 1, ?onComplete:Dynamic):Void;
	public function cancel():Void;
}

/**
 * A cutscene video. Scripts start one and read how far it got.
 */
extern class Video extends FlxSprite {
	public function new(?x:Float = 0, ?y:Float = 0):Void;
	public var time:Float;
	public var length:Float;
	public var finished:Bool;
	public function play():Void;
	public function pause():Void;
	public function stop():Void;
}

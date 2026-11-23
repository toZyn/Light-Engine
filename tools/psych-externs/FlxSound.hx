extern class FlxSound {
	public var time:Float;
	public var pitch:Float;
	public var volume:Float;
	public var length:Float;
	public var playing:Bool;
	public function play(?forceRestart:Bool = true):Void;
	public function pause():Void;
	public function resume():Void;
	public function stop():Void;
	public function fadeIn(?duration:Float, ?from:Float, ?to:Float):Void;
	public function fadeOut(?duration:Float, ?to:Float):Void;
	public function cancelFade():Void;
}

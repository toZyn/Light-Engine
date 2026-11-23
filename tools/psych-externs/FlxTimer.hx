extern class FlxTimer {
	public function new();
	public static function globalManager:Dynamic;
	public function start(?time:Float = 1, ?onComplete:Dynamic):Void;
	public function cancel():Void;
}

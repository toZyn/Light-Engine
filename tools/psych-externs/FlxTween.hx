extern class FlxTween extends FlxBasic {
	public static function tween(object:Dynamic, values:Dynamic, duration:Float, ?options:Dynamic):FlxTween;
	public static function color(object:Dynamic, values:Dynamic, duration:Float, ?options:Dynamic):FlxTween;
	public static function cancel(tween:FlxTween, ?field:String, ?complete:Bool):Void;
	public var active:Bool;
	public function cancel():Void;
}

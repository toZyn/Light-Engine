/**
 * flixel's tweens. Psych creates these by hand from a script's option table and
 * reads `type` back to decide whether to keep them.
 */
extern class FlxTween extends FlxBasic {
	public static function tween(object:Dynamic, values:Dynamic, duration:Float, ?options:Dynamic):FlxTween;
	public static function color(object:Dynamic, duration:Float, fromColor:FlxColor, toColor:FlxColor, ?options:Dynamic):FlxTween;
	public static function angle(object:Dynamic, duration:Float, fromAngle:Float, toAngle:Float, ?options:Dynamic):FlxTween;
	public static function num(object:Dynamic, field:String, duration:Float, fromValue:Float, toValue:Float, ?options:Dynamic):FlxTween;
	public static function cancel(tween:FlxTween, ?field:String, ?complete:Bool):Void;
	public static function complete(tween:FlxTween, ?field:String):Void;
	public var type:FlxTweenType;
	public var duration:Float;
	public var ease:EaseFunction;
	public function cancel():Void;
}

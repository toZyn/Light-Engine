/**
 * flixel's numeric helpers. Only the bounds Psych clamps with.
 */
extern class FlxMath {
	public static var MAX_VALUE_FLOAT:Float;
	public static var MIN_VALUE_FLOAT:Float;
	public static inline var MAX_VALUE_INT:Int = 0x7FFFFFFF;
	public static inline var MIN_VALUE_INT:Int = -0x80000000;
	public static function bound(?value:Float, ?min:Float, ?max:Float):Float;
	public static function boundInt(?value:Int, ?min:Int, ?max:Int):Int;
	public static function roundDecimal(value:Float, precision:Int):Float;
	public static function isBetween(?value:Float, ?min:Float, ?max:Float):Bool;
}

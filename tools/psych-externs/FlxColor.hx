/**
 * flixel's colour: an abstract over Int with implicit conversion both ways.
 *
 * Modelling it as an abstract matters. Psych passes raw hex numbers
 * (`0xFFFFFFFF`) *and* `FlxColor` constants to the same parameters, which only
 * compiles if the type converts from Int.
 */
extern abstract FlxColor(Int) from Int to Int {
	public static function fromString(color:String):FlxColor;
	public static function fromRGB(red:Int, green:Int, blue:Int):FlxColor;
	public static function fromHSV(hue:Float, saturation:Float, brightness:Float):FlxColor;
	public static function getColor32(alpha:Int, red:Int, green:Int, blue:Int):FlxColor;

	// Declared as plain fields: an extern abstract cannot carry accessor bodies,
	// and these are only ever read or assigned by Psych.
	public var red:Int;
	public var green:Int;
	public var blue:Int;
	public var alpha:Int;
	public var alphaFloat:Float;

	public static inline var WHITE:FlxColor = 0xFFFFFFFF;
	public static inline var BLACK:FlxColor = 0xFF000000;
	public static inline var RED:FlxColor = 0xFFFF0000;
	public static inline var GREEN:FlxColor = 0xFF00FF00;
	public static inline var BLUE:FlxColor = 0xFF0000FF;
	public static inline var YELLOW:FlxColor = 0xFFFFFF00;
	public static inline var PURPLE:FlxColor = 0xFFFF00FF;
	public static inline var ORANGE:FlxColor = 0xFFFFA500;
	public static inline var GRAY:FlxColor = 0xFF808080;
	public static inline var PINK:FlxColor = 0xFFFFC0CB;
	public static inline var CYAN:FlxColor = 0xFF00FFFF;
	public static inline var TRANSPARENT:FlxColor = 0x00000000;
}

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

	public var red(get, never):Int;
	public var green(get, never):Int;
	public var blue(get, never):Int;
	public var alpha(get, never):Int;
	public var alphaFloat(get, never):Float;

	public static var WHITE(default, never):FlxColor;
	public static var BLACK(default, never):FlxColor;
	public static var RED(default, never):FlxColor;
	public static var GREEN(default, never):FlxColor;
	public static var BLUE(default, never):FlxColor;
	public static var YELLOW(default, never):FlxColor;
	public static var PURPLE(default, never):FlxColor;
	public static var ORANGE(default, never):FlxColor;
	public static var GRAY(default, never):FlxColor;
	public static var PINK(default, never):FlxColor;
	public static var CYAN(default, never):FlxColor;
	public static var TRANSPARENT(default, never):FlxColor;
}

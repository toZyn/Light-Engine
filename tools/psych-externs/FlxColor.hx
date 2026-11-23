extern class FlxColor {
	public static function fromString(color:String):Int;
	public static function fromRGB(red:Int, green:Int, blue:Int):Int;
	public static function fromHSV(hue:Float, saturation:Float, brightness:Float):Int;
	public static var WHITE:Int; public static var BLACK:Int; public static var RED:Int;
	public static var GREEN:Int; public static var BLUE:Int; public static var TRANSPARENT:Int;
	public static var YELLOW:Int; public static var PURPLE:Int; public static var ORANGE:Int;
}

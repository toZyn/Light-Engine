/**
 * flixel's colour.
 *
 * Psych passes raw hex numbers (`0xFFFFFFFF`) and `FlxColor` constants to the
 * same parameters and assigns channels (`curColor.alphaFloat = ...`), so this has
 * to be an abstract that converts from Int *and* exposes fields. Haxe forbids
 * declaring fields on an abstract, hence the `@:forward` companion: conversion
 * happens through the explicit @:from/@:to below.
 */
@:forward
extern abstract FlxColor(FlxColorChannels) {
	@:from public static function fromInt(value:Int):FlxColor;
	@:to public function toInt():Int;

	public static function fromString(color:String):FlxColor;
	public static function fromRGB(red:Int, green:Int, blue:Int):FlxColor;
	public static function fromHSV(hue:Float, saturation:Float, brightness:Float):FlxColor;
	public static function getColor32(alpha:Int, red:Int, green:Int, blue:Int):FlxColor;

	public static inline var WHITE:FlxColor = cast 0xFFFFFFFF;
	public static inline var BLACK:FlxColor = cast 0xFF000000;
	public static inline var RED:FlxColor = cast 0xFFFF0000;
	public static inline var GREEN:FlxColor = cast 0xFF00FF00;
	public static inline var BLUE:FlxColor = cast 0xFF0000FF;
	public static inline var YELLOW:FlxColor = cast 0xFFFFFF00;
	public static inline var PURPLE:FlxColor = cast 0xFFFF00FF;
	public static inline var ORANGE:FlxColor = cast 0xFFFFA500;
	public static inline var GRAY:FlxColor = cast 0xFF808080;
	public static inline var PINK:FlxColor = cast 0xFFFFC0CB;
	public static inline var CYAN:FlxColor = cast 0xFF00FFFF;
	public static inline var TRANSPARENT:FlxColor = cast 0x00000000;
}

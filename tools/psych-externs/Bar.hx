/**
 * A HUD bar. Scripts recolour and resize these, so the fields they touch are
 * part of the surface.
 */
extern class Bar extends FlxSprite {
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var percent:Float;
	public function setColors(left:FlxColor, right:FlxColor):Void;
	public function updateBar():Void;
}

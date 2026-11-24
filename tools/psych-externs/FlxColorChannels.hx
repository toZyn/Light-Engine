/**
 * The channel view behind FlxColor. An abstract cannot declare fields, so this
 * carries them and FlxColor forwards to them.
 */
extern class FlxColorChannels {
	public var red:Int;
	public var green:Int;
	public var blue:Int;
	public var alpha:Int;
	public var alphaFloat:Float;
}

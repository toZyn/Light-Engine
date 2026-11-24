/**
 * The channel view of a colour. Kept separate because Haxe abstracts cannot
 * declare fields, and Psych reads and assigns these directly.
 */
extern class FlxColorChannels {
	public var red:Int;
	public var green:Int;
	public var blue:Int;
	public var alpha:Int;
	public var alphaFloat:Float;
}

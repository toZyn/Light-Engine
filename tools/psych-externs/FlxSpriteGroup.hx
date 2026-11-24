/**
 * flixel's sprite group. Scripts treat it as one object with per-member offsets,
 * which is why Psych asks for its lowest member and rewrites all of them.
 */
extern class FlxSpriteGroup extends FlxSprite {
	public var length:Int;
	public var members:Array<FlxSprite>;
	public function add(sprite:FlxSprite):FlxSprite;
	public function remove(sprite:FlxSprite, ?splice:Bool = false):FlxSprite;
	public function clear():Void;
	public function forEach(func:FlxSprite->Void):Void;
	public function getFirstAlive():FlxSprite;
}

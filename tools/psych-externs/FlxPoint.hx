/**
 * An (x, y) pair. A sprite's scale, offset and origin are these, not loose
 * numbers, which is why scripts say `sprite.offset.x`.
 */
extern class FlxPoint {
	public var x:Float;
	public var y:Float;
	public function new(?x:Float = 0, ?y:Float = 0):Void;
	public function set(?x:Float, ?y:Float):FlxPoint;
}

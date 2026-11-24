/**
 * An (x, y) pair. A sprite's scale, offset, origin and a camera's scroll are
 * these, which is why scripts say `sprite.offset.x` and `camera.scroll.add(x, y)`.
 */
extern class FlxPoint {
	public var x:Float;
	public var y:Float;
	public function new(?x:Float = 0, ?y:Float = 0):Void;
	public function set(?x:Float = 0, ?y:Float = 0):FlxPoint;
	public function add(x:Float = 0, y:Float = 0):FlxPoint;
	public function subtract(x:Float = 0, y:Float = 0):FlxPoint;
	public function copyFrom(point:FlxPoint):FlxPoint;
	public function copyTo(point:FlxPoint):FlxPoint;
}

/**
 * flixel's typed sprite group. Scripts address members by index and the group
 * helpers iterate them.
 */
extern class FlxTypedGroup<T> {
	public var members:Array<T>;
	public var length:Int;
	public function add(object:T):T;
	public function remove(object:T, ?splice:Bool = false):T;
	public function clear():Void;
	public function forEach(func:T->Void):Void;
	public function countLiving():Int;
}

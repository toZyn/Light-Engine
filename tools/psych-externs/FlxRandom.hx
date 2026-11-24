/**
 * flixel's random helper. `FlxG.random` is an instance, not a function.
 */
extern class FlxRandom {
	public function int(?min:Int, ?max:Int, ?excludes:Array<Int>):Int;
	public function float(?min:Float, ?max:Float, ?excludes:Array<Float>):Float;
	public function bool(?chance:Float = 0.5):Bool;
}

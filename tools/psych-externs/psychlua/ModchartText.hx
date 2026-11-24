package psychlua;

/**
 * The text object Psych creates for a script's `makeLuaText`.
 */
extern class ModchartText extends FlxText {
	public var wasAdded:Bool;
	public function new(?x:Float = 0, ?y:Float = 0, ?width:Int = 0, ?text:String = ''):Void;
}

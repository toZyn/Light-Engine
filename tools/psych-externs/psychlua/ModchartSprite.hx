package psychlua;

/**
 * The sprite Psych creates for a script's `makeLuaSprite`, with its own fade
 * helper so a modchart sprite can disappear independently.
 */
extern class ModchartSprite extends FlxSprite {
	public var wasAdded:Bool;
	public function new(?x:Float = 0, ?y:Float = 0):Void;
	public function playAnim(name:String, ?force:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void;
	public function dance(?ignoreMiss:Bool = false):Void;
}

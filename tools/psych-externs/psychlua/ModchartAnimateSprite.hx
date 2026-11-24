package psychlua;

/**
 * A sprite driven by FlxAnimate (Aseprite files) rather than a sparrow sheet,
 * which is what makeFlxAnimateSprite creates.
 */
extern class ModchartAnimateSprite extends FlxAnimate {
	public var wasAdded:Bool;
	public function new(?x:Float = 0, ?y:Float = 0):Void;
	public function playAnim(name:String, ?force:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void;
	public function loadAnimateAtlas(folder:String, ?sprite:String, ?animation:String):Void;
	public function addAnimationBySymbol(name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0):Void;
	public function addAnimationBySymbolIndices(name:String, symbol:String, indices:Array<Int>, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0):Void;
}

extern class FlxSprite extends FlxBasic {
	public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:Dynamic);
	public var color:Int;
	public var antialiasing:Bool;
	public var animation:FlxAnimationController;
	public var shader:Dynamic;
	public var graphic:Dynamic;
	public var frames:Dynamic;
	public var pixels:Dynamic;
	public var blend:Dynamic;
	public var scale:FlxPoint;
	public var offset:FlxPoint;
	public var origin:FlxPoint;
	public function loadGraphic(graphic:Dynamic, ?animated:Bool, ?frameWidth:Int, ?frameHeight:Int):Void;
	public function loadFrames(frames:Dynamic, ?destroy:Bool):Void;
	public function makeGraphic(width:Int, height:Int, ?color:Int):Void;
	public function setGraphicSize(?width:Int, ?height:Int):Void;
	public function updateHitbox():Void;
	public function setPosition(x:Float, y:Float):Void;
	public function setBlendMode(mode:Dynamic):Void;
	public function screenCenter(?axes:Dynamic):Void;
	public function getGraphicMidpoint(?point:Dynamic):FlxPoint;
	public function isSimple:Bool;
}

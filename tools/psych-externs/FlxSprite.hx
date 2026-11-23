extern class FlxSprite extends FlxBasic {
	public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:Dynamic);
	public var scale:Dynamic;
	public var offset:Dynamic;
	public var origin:Dynamic;
	public var color:Int;
	public var antialiasing:Bool;
	public var animation:Dynamic;
	public var shader:Dynamic;
	public var graphic:Dynamic;
	public function loadGraphic(graphic:Dynamic, ?animated:Bool, ?frameWidth:Int, ?frameHeight:Int):Void;
	public function loadFrames(frames:Dynamic, ?destroy:Bool):Void;
	public function makeGraphic(width:Int, height:Int, ?color:Int):Void;
	public function setGraphicSize(?width:Int, ?height:Int):Void;
	public function updateHitbox():Void;
	public function setPosition(x:Float, y:Float):Void;
	public function setBlendMode(mode:Dynamic):Void;
}

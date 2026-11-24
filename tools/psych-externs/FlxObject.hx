extern class FlxObject {
	public var x:Float;
	public var y:Float;
	public var angle:Float;
	public var alpha:Float;
	public var visible:Bool;
	public var active:Bool;
	public var scrollFactor:Dynamic;
	public var cameras:Array<FlxCamera>;
	public function getMidpoint():Dynamic;
	public function getScreenPosition(?camera:FlxCamera):Dynamic;
	public function isOnScreen(?camera:FlxCamera):Bool;
	public var width:Float;
	public var height:Float;
	public function screenCenter(?axes:FlxAxes = FlxAxes.XY):Void;
	public function getGraphicMidpoint(?point:Dynamic):FlxPoint;
	public function setSize(width:Float, height:Float):Void;
}

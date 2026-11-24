extern class FlxCamera {
	public var zoom:Float;
	public var alpha:Float;
	public var x:Float;
	public var y:Float;
	public var scroll:FlxPoint;
	public var followLerp:Float;
	public var target:Dynamic;
	public var width:Int;
	public var height:Int;
	public function shake(?intensity:Float, ?duration:Float):Void;
	public function flash(?color:Int, ?duration:Float, ?force:Bool):Void;
	public function fade(?color:Int, ?duration:Float, ?fadeIn:Bool, ?force:Bool):Void;
	public function setScroll(x:Float, y:Float):Void;
}

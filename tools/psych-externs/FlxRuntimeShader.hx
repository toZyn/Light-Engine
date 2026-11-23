extern class FlxRuntimeShader {
	public function new(?fragmentSource:String, ?vertexSource:String);
	public function setFloat(name:String, value:Float):Bool;
	public function setInt(name:String, value:Int):Bool;
	public function setBool(name:String, value:Bool):Bool;
	public function setFloatArray(name:String, values:Array<Float>):Bool;
	public function getFloat(name:String):Float;
	public function getInt(name:String):Int;
}

/**
 * A runtime shader. Psych's ShaderFunctions reads and writes individual
 * uniforms by name, so the accessors come in pairs and arrays.
 */
extern class FlxRuntimeShader {
	public function new(?fragmentSource:String, ?vertexSource:String);
	public function setFloat(name:String, value:Float):Bool;
	public function setInt(name:String, value:Int):Bool;
	public function setBool(name:String, value:Bool):Bool;
	public function setFloatArray(name:String, values:Array<Float>):Bool;
	public function setIntArray(name:String, values:Array<Int>):Bool;
	public function setBoolArray(name:String, values:Array<Bool>):Bool;
	public function setSampler2D(name:String, value:Dynamic):Bool;
	public function getFloat(name:String):Float;
	public function getInt(name:String):Int;
	public function getBool(name:String):Bool;
	public function getFloatArray(name:String):Array<Float>;
	public function getIntArray(name:String):Array<Int>;
	public function getBoolArray(name:String):Array<Bool>;
}

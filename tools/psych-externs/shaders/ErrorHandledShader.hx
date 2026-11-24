package shaders;

/**
 * Psych's shader that reports compile errors instead of failing silently. Scripts
 * assign it to a sprite when they call setSpriteShader.
 */
extern class ErrorHandledShader {
	public static var error:String;
}

extern class ErrorHandledRuntimeShader extends FlxRuntimeShader {
	public function new(name:String, fragmentSource:String, vertexSource:String);
}

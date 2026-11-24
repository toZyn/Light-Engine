package;

/**
 * Entry point for the compiled Psych Lua layer.
 *
 * `install` is what the engine calls once per script. Psych registers each
 * callback through `funk.addLocalCallback`, so whatever object is passed as
 * `funk` collects the entire `setX`/`getX` surface the engine has to bind to.
 *
 * This mirrors what `crowplexus.iris.Iris` exposes in `runtime.lua`, but for the
 * Psych side: no interpreter, just Psych's real functions.
 */
class PsychBridge {
	public static function install(host:Dynamic):Dynamic {
		#if lua
		final funk:Dynamic = host;
		psychlua.TextFunctions.implement(funk);
		psychlua.ExtraFunctions.implement(funk);
		psychlua.ReflectionFunctions.implement(funk);
		psychlua.ShaderFunctions.implement(funk);
		psychlua.FlxAnimateFunctions.implement(funk);
		psychlua.DeprecatedFunctions.implement(funk);
		#end
		return host;
	}

	public static function main():Void {
		#if lua
		untyped __lua__("_G.lightPsychInstall = {0}", install);
		#end
	}
}

package;

/**
 * Entry point for the compiled Psych Lua layer.
 *
 * `install` is what the engine calls once per script. It hands Psych's own
 * callback registrations (`Lua_helper.add_callback`) a table standing in for the
 * Lua state, so every `setX`/`getX` Psych defines lands in one place that the
 * engine can bind to its objects.
 *
 * This mirrors what `crowplexus.iris.Iris` exposes in `runtime.lua`, but for the
 * Psych side: no interpreter, just Psych's real functions.
 */
class PsychBridge {
	public static function install(host:Dynamic):Dynamic {
		final funk:Dynamic = {
			lua: host,
			ModchartSprites: {},
			ModchartTexts: {},
			ModchartShaders: {}
		};
		TextFunctions.implement(funk);
		ExtraFunctions.implement(funk);
		ReflectionFunctions.implement(funk);
		ShaderFunctions.implement(funk);
		DeprecatedFunctions.implement(funk);
		return host;
	}

	public static function main():Void {
		untyped __lua__("_G.lightPsychInstall = {0}", install);
	}
}

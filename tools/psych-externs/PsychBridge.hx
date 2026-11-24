package;

/**
 * Entry point for the compiled Psych Lua layer.
 *
 * `install` builds a real `psychlua.FunkinLua` for the host and calls each
 * `implement`, so the callbacks are registered by Psych's own code.
 *
 * `FunkinLua` is Psych's host class rather than a helper, and it is the reason
 * this compiles at all: 123 of its 128 callbacks never touch the Lua stack. They
 * only need the engine objects the externs declare.
 */
class PsychBridge {
	public static function install(host:Dynamic):Dynamic {
		#if lua
		final funk:psychlua.FunkinLua = narrow(host);
		psychlua.FunkinLua.customFunctions = funk.callbacks;
		psychlua.TextFunctions.implement(funk);
		psychlua.ExtraFunctions.implement(funk);
		psychlua.ReflectionFunctions.implement(funk);
		psychlua.ShaderFunctions.implement(funk);
		psychlua.FlxAnimateFunctions.implement(funk);
		psychlua.DeprecatedFunctions.implement(funk);
		#end
		return host;
	}

	#if lua
	static inline function narrow(host:Dynamic):psychlua.FunkinLua
		return cast host;
	#end

	public static function main():Void {
		#if lua
		untyped __lua__("_G.lightPsychInstall = {0}", install);
		#end
	}
}

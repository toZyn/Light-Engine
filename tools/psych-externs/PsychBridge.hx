package;

/**
 * Entry point for the compiled Psych Lua layer.
 *
 * Psych registers its callback surface from two places, and they are not
 * interchangeable:
 *
 * `install` covers the six helper classes (`TextFunctions`, `ExtraFunctions`,
 *  `ReflectionFunctions`, `ShaderFunctions`, `FlxAnimateFunctions`,
 *  `DeprecatedFunctions`): 94 registrations. It works anywhere, because those
 *  classes only need the `FunkinLua` object, not a running song.
 *
 * `createScript` covers everything, because the other 128 registrations live in
 * `FunkinLua.new()` -- Psych has no `register()` method. Constructing the object
 * *is* the registration, and it is also what loads the script: `new()` calls
 * `Lua_helper.add_callback` 128 times, calls every helper's `implement`, then
 * runs the script through `LuaL.dofile`/`LuaL.dostring`. That path reads a live
 * song (`PlayState.SONG`, `Conductor`, `FlxG.sound.music`), which is why it is
 * separate rather than folded into `install` -- a Psych script only ever runs
 * during a song anyway.
 *
 * Passing the script's *source* to `createScript` rather than a path is
 * deliberate: `new()` tests `FileSystem.exists` and treats a non-path as Lua
 * source, which is the branch that fits a script the engine has already read.
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

	/**
	 * Registers Psych's full 222-callback surface and runs `source`.
	 *
	 * Returns the `FunkinLua` Psych built. The engine keeps it so `call`,
	 * `set` and `stop` reach the same object the callbacks were registered on;
	 * dropping it would leave the registry pointing at a dead script.
	 *
	 * Song-time only, for the reason in the class comment.
	 */
	public static function createScript(source:String):Dynamic {
		#if lua
		return new psychlua.FunkinLua(source);
		#end
		return null;
	}

	#if lua
	static inline function narrow(host:Dynamic):psychlua.FunkinLua
		return cast host;
	#end

	public static function main():Void {
		#if lua
		untyped __lua__("_G.lightPsychInstall = {0}", install);
		untyped __lua__("_G.lightPsychCreateScript = {0}", createScript);
		#end
	}
}

/**
 * The pause menu. Scripts read whether the game is paused and can open or close
 * it.
 */
extern class PauseSubState extends FlxSubState {
	public static var instance:PauseSubState;
	public static var songPosition:Float;
	public static function resetSubState():Void;
}

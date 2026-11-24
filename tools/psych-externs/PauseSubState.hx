/**
 * The pause menu. A script calls restartSong through it, which is why the
 * restart callback does not live on PlayState.
 */
extern class PauseSubState extends FlxSubState {
	public function new():Void;
	public static var instance:PauseSubState;
	public static var songPosition:Float;
	public static function restartSong(?skipTransition:Bool = false):Void;
	public static function resetSubState():Void;
}

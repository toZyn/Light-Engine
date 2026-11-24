/**
 * The loading screen a song passes through. Psych hands it the next state to
 * switch to, not a name.
 */
extern class LoadingState extends MusicBeatState {
	public function new():Void;
	public static var nextState:FlxState;
	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false, intrusive:Bool = true):Void;
}

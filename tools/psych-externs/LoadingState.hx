/**
 * The loading screen a song passes through. Scripts can replace the next state.
 */
extern class LoadingState extends MusicBeatState {
	public static var nextState:Dynamic;
	public static function loadAndSwitchState(target:String, ?stopMusic:Bool = true):Void;
}

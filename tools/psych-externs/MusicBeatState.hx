/**
 * The base state. It owns the shared variable map scripts read objects from, and
 * the debug console output goes through it.
 */
extern class MusicBeatState extends FlxState {
	public static function getState():FlxState;
	public static function getVariables():Map<String, Dynamic>;
	public static function switchState(state:Dynamic):Void;
	public function addTextToDebug(text:String, ?color:Int = 0xFFFFFFFF):Void;
}

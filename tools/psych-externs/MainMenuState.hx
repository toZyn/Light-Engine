/**
 * The main menu. Psych reads its version string so a script can ask what engine
 * it is running on.
 */
extern class MainMenuState extends MusicBeatState {
	public function new():Void;
	public static var psychEngineVersion:String;
	public static var gameVersion:String;
	public static function openSubState(subState:FlxState):Void;
}

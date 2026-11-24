/**
 * The song list. Scripts can open it and read the current selection.
 */
extern class FreeplayState extends MusicBeatState {
	public static var curSelected:Int;
	public static var instance:FreeplayState;
	public static function resetScore():Void;
}

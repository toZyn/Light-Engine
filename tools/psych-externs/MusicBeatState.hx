/**
 * The base state. It owns the beat clock every callback reads and the controls
 * accessor, which is why PlayState inherits both.
 */
extern class MusicBeatState extends FlxState {
	public function new():Void;
	public static function getState():FlxState;
	public static function getVariables():Map<String, Dynamic>;
	public static function switchState(state:Dynamic):Void;
	public function addTextToDebug(text:String, ?color:Int = 0xFFFFFFFF):Void;

	public var curSection:Int;
	public var curStep:Int;
	public var curBeat:Int;
	public var curDecStep:Float;
	public var curDecBeat:Float;
	public var controls:Controls;
}

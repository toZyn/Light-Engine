/**
 * Psych's user-defined substate, opened by a script. It is a state, so it can
 * take the same sprites the play state does.
 */
extern class CustomSubstate extends FlxState {
	public static var instance:CustomSubstate;
	public static var name:String;
	public static function implement(funk:Dynamic):Void;
}

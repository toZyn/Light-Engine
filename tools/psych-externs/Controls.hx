/**
 * The control bindings. Psych resolves a script's 'left'/'a' string to one of
 * these, so each note key is an accessor rather than a field.
 */
extern class Controls {
	public static var instance:Controls;
	public var NOTE_LEFT:Bool;
	public var NOTE_DOWN:Bool;
	public var NOTE_UP:Bool;
	public var NOTE_RIGHT:Bool;
	public var NOTE_LEFT_P:Bool;
	public var NOTE_DOWN_P:Bool;
	public var NOTE_UP_P:Bool;
	public var NOTE_RIGHT_P:Bool;
	public var NOTE_LEFT_R:Bool;
	public var NOTE_DOWN_R:Bool;
	public var NOTE_UP_R:Bool;
	public var NOTE_RIGHT_R:Bool;
	public var RESET:Bool;
	public var PAUSE:Bool;
	public var BACK:Bool;
	public var ACCEPT:Bool;
	public function justPressed(button:String):Bool;
	public function pressed(button:String):Bool;
	public function justReleased(button:String):Bool;
}

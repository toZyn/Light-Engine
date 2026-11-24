/**
 * flixel's substate, drawn over a running state. It carries the parent link and
 * the close callback.
 */
extern class FlxSubState extends FlxState {
	public var _parentState:Dynamic;
	public function close():Void;
}

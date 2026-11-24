/**
 * The game-over screen, a substate of the play state. Both it and PlayState
 * resolve to a FlxState, which is what lets LuaUtils.getTargetInstance return
 * whichever is current.
 */
extern class GameOverSubstate extends FlxSubState {
	public function new():Void;
	public static var instance:GameOverSubstate;
	public static var characterName:String;
	public static var loopSoundName:String;
	public static var endSoundName:String;
	public var boyfriend:Dynamic;
}

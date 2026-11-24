/**
 * The game-over screen. It is a state like PlayState, which is why
 * LuaUtils.getTargetInstance can return either of them.
 */
extern class GameOverSubstate extends FlxState {
	public static var instance:GameOverSubstate;
	public static var characterName:String;
	public static var loopSoundName:String;
	public static var endSoundName:String;
	public var boyfriend:Dynamic;
}

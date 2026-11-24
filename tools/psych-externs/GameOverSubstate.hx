/**
 * The game-over screen. Psych reads it to know which character died.
 */
extern class GameOverSubstate {
	public static var characterName:String;
	public static var instance:FlxState;
	public static var loopSoundName:String;
	public static var endSoundName:String;
}

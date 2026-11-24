/**
 * The game-over screen. Psych reads it to know which character died.
 */
extern class GameOverSubstate {
	public static var characterName:String;
	public static var instance:GameOverSubstate;
	public var boyfriend:Dynamic;
	public var members:Array<FlxBasic>;
	public function insert(position:Int, object:FlxBasic):Void;
	public static var loopSoundName:String;
	public static var endSoundName:String;
}

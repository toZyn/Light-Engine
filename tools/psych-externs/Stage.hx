/**
 * The stage a song is playing on. Psych reads a few of its flags when it builds
 * sprite groups.
 */
extern class Stage {
	public var curStage:String;
	public var hide_girlfriend:Bool;
	public var boyfriendGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
}

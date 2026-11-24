extern class PlayState extends FlxState {
	public static var instance:PlayState;
	public static var SONG:Song;
	public static var isStoryMode:Bool;
	public static var seenCutscene:Bool;
	public static var storyWeek:Int;
	public static var storyDifficulty:Int;
	public static var chartingMode:Bool;
	public static var changedDifficulty:Bool;
	public static var deathCounter:Int;
	public var isDead:Bool;
	public var boyfriendGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var boyfriend:Dynamic;
	public var gf:Dynamic;
	public var dad:Dynamic;
	public var curStage:String;
	public var stage:Stage;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var controls:Dynamic;
	public function getLuaObject(tag:String, ?checkForTextsToo:Bool = true):Dynamic;
}

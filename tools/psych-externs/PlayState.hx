/**
 * The play state. This is where nearly every Lua callback acts, which is why it
 * carries the largest surface in these externs.
 *
 * Signatures are copied from Psych 1.0.4 `source/states/PlayState.hx`, not
 * inferred: several of them (moveCamera takes a Bool, RecalculateRating takes
 * badHit/scoreBop) are not what the call sites look like at a glance.
 */
extern class PlayState extends MusicBeatState {
	public static var instance:PlayState;
	public static var SONG:Song;
	public static var isStoryMode:Bool;
	public static var seenCutscene:Bool;
	public static var storyWeek:Int;
	public static var storyDifficulty:Int;
	public static var chartingMode:Bool;
	public static var changedDifficulty:Bool;
	public static var deathCounter:Int;

	// characters, camera and stage
	public var boyfriend:Dynamic;
	public var dad:Dynamic;
	public var gf:Dynamic;
	public var boyfriendGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var camFollow:Dynamic;
	public var stage:Stage;
	public var videoCutscene:VideoSprite;
	public var persistentUpdate:Bool;
	public var curStage:String;
	public var isDead:Bool;

	// script hosts
	public var luaArray:Array<Dynamic>;
	public var hscriptArray:Array<Dynamic>;

	// notes and score
	public var unspawnNotes:Array<Dynamic>;
	public var strumLineNotes:FlxTypedGroup<Dynamic>;
	public var notes:FlxTypedGroup<Dynamic>;
	public var vocals:FlxSound;
	public var health:Float;
	public var combo:Int;
	public var songScore:Int;
	public var songMisses:Int;
	public var songHits:Int;
	public var totalPlayed:Int;
	public var totalNotesHit:Float;
	public var ratingPercent:Float;
	public var ratingName:String;
	public var ratingFC:String;
	public var cpuControlled:Bool;
	public var practiceMode:Bool;
	public var transitioning:Bool;
	public var instakillOnMiss:Bool;
	public var guitarHeroSustains:Bool;
	public var playbackRate:Float;
	public var endingSong:Bool;
	public var startingSong:Bool;

	// stage anchors the camera uses
	public var BF_X:Float;
	public var BF_Y:Float;
	public var DAD_X:Float;
	public var DAD_Y:Float;
	public var GF_X:Float;
	public var GF_Y:Float;

	public var healthGain:Float->Void;
	public var healthLoss:Float->Void;

	public function getLuaObject(tag:String):Dynamic;
	public function addCharacterToList(newCharacter:String, type:Int):Void;
	public function updateScoreText():Void;
	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float):Void;
	public function moveCamera(isDad:Bool):Void;
	public function moveCameraToGirlfriend():Void;
	public function moveCameraSection(?sec:Null<Int>):Void;
	public function KillNotes():Void;
	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true):Void;
	public function startCountdown():Void;
	public function endSong():Void;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true):Bool;
	public function initHScript(file:String):Void;
	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic;
	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic;
	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic;
	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void;
}

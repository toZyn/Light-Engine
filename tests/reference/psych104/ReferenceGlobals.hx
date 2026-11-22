// Adapted Psych 1.0.4 FunkinLua constructor (ShadowMario and contributors), Apache-2.0.
// Modified: synthetic services and JSON capture; original set calls retained.

using StringTools;
typedef SwagSection=Dynamic;
class LuaUtils {
 public static var Function_Stop='##PSYCHLUA_FUNCTIONSTOP';public static var Function_Continue='##PSYCHLUA_FUNCTIONCONTINUE';
 public static var Function_StopLua='##PSYCHLUA_FUNCTIONSTOPLUA';public static var Function_StopHScript='##PSYCHLUA_FUNCTIONSTOPHSCRIPT';public static var Function_StopAll='##PSYCHLUA_FUNCTIONSTOPALL';
 public static function getBuildTarget() return 'linux';
}
class MainMenuState {public static var psychEngineVersion='1.0.4';}
class Conductor {public static var bpm=120.0;public static var crochet=500.0;public static var stepCrochet=125.0;}
class PlayState {
 public static var SONG:Dynamic={bpm:120.0,speed:2.5,song:'Test Song',stage:'fixture',needsVoices:true,player1:'bf-fixture',player2:'dad-fixture',gfVersion:'gf-fixture',notes:[{mustHitSection:true,altAnim:false,gfSection:true}]};
 public static var isStoryMode=true;public static var storyDifficulty=1;public static var storyWeek=2;public static var seenCutscene=false;public static var deathCounter=3;
}
class Song {public static var loadedSongName='test-song';public static var chartPath='mods/fixture/data/test-song/test-song.json';}
class Paths {public static function formatToSongPath(s:String) return s.toLowerCase().replace(' ','-');}
class Difficulty {public static function getString(translate:Bool) return 'Normal';public static function getFilePath() return '';}
class WeekData {public static var weeksList=['zero','one','fixture-week'];}
class GameOverSubstate {public static var instance:Dynamic=null;}
class FlxG {public static var width=1280;public static var height=720;public static var sound:Dynamic={music:{length:4096.0}};}
class Mods {public static var currentModDirectory='fixture';}
class Note {public static function getNoteSkinPostfix() return '';}
class NoteSplash {public static function getSplashSkinPostfix() return '';}
class ClientPrefs {public static var data:Dynamic={downScroll:false,middleScroll:false,framerate:60,ghostTapping:true,hideHud:false,timeBarType:'Time Left',scoreZoom:true,camZooms:true,flashing:true,noteOffset:0,healthBarAlpha:1.0,noReset:false,lowQuality:false,shaders:true,noteSkin:'Default',splashSkin:'Psych',splashAlpha:0.6};}
class ReferenceGlobals {
 var scriptName='synthetic.lua';var modFolder='fixture';var values:Dynamic={};var game:Dynamic;
 function set(name:String,value:Dynamic) Reflect.setField(values,name,value);
 function new() {
  game={curSection:0,curBeat:2,curStep:7,curDecBeat:1.875,curDecStep:7.5,songScore:0,songMisses:0,songHits:0,combo:0,ratingPercent:0.0,ratingName:'?',ratingFC:null,totalPlayed:0,totalNotesHit:0.0,healthGain:1.0,healthLoss:1.0,playbackRate:1.0,guitarHeroSustains:true,instakillOnMiss:false,cpuControlled:false,practiceMode:false,BF_X:123.0,BF_Y:456.0,DAD_X:-50.0,DAD_Y:60.0,GF_X:700.0,GF_Y:800.0,boyfriend:null,dad:null,gf:null};
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('version', MainMenuState.psychEngineVersion.trim());
		set('modFolder', this.modFolder);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('loadedSongName', Song.loadedSongName);
		set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		set('chartPath', Song.chartPath);
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString(false));
		set('difficultyPath', Difficulty.getFilePath());
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);


		// PlayState-only variables
		if(game != null)
		@:privateAccess
		{
			var curSection:SwagSection = PlayState.SONG.notes[game.curSection];
			set('curSection', game.curSection);
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);

			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);

			set('rating', game.ratingPercent);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			set('inGameOver', GameOverSubstate.instance != null);
			set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
			set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
			set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);

			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end

			set('guitarHeroSustains', game.guitarHeroSustains);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);

			for (i in 0...4) {
				set('defaultPlayerStrumX' + i, 0);
				set('defaultPlayerStrumY' + i, 0);
				set('defaultOpponentStrumX' + i, 0);
				set('defaultOpponentStrumY' + i, 0);
			}

			// Default character data
			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);

			set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
			set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
			set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
		}

		// Other settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		// build target (windows, mac, linux, etc.)
		set('buildTarget', LuaUtils.getBuildTarget());

 }
 static function main() { var reference=new ReferenceGlobals();Sys.println(haxe.Json.stringify(reference.values)); }
}

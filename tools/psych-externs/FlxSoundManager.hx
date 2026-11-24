/**
 * flixel's sound front-end. Psych reads the current music track from it, and
 * that track's length is what a script hears as `songLength`.
 */
extern class FlxSoundManager {
	public var music:FlxSound;
	public var musicVolume:Float;
	public var soundVolume:Float;
	public function play(path:String, ?volume:Float = 1, ?looped:Bool = false, ?group:Dynamic = null, ?autoDestroy:Bool = true, ?onComplete:Dynamic = null):FlxSound;
	public function playMusic(?music:FlxSound, ?volume:Float, ?looped:Bool):Void;
	public function pauseMusic():Void;
	public function resumeMusic():Void;
	public function destroy(?destroySound:Bool = true):Void;
}

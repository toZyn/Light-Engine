/**
 * The outside world Psych's Lua layer expects.
 *
 * Derived mechanically from ShadowMario/FNF-PsychEngine 1.0.4
 * `source/psychlua/*.hx` (see tools/build_psych_lua.py, which regenerates the
 * member list). Members are declared exactly as Psych calls them; anything not
 * listed here is something Psych does not use from that class.
 *
 * These are `extern` classes: Haxe emits `Paths.image(...)`, `FlxG.width`, ...
 * as calls into Lua globals of the same name, which the engine bridges.
 */

/* ------------------------------------------------------------------ paths */
extern class Paths {
	public static function image(key:String, ?allowGPU:Bool = true):Dynamic;
	public static function sound(key:String, ?logError:Bool = true):Dynamic;
	public static function music(key:String, ?logError:Bool = true):Dynamic;
	public static function video(key:String, ?library:String):Dynamic;
	public static function font(key:String):String;
	public static function getPath(file:String, ?library:String, ?modsAllowed:Bool = true):String;
	public static function getSharedPath(file:String):String;
	public static function mods(key:String):String;
	public static function formatToSongPath(path:String):String;
	public static function getSparrowAtlas(key:String, ?library:String):Dynamic;
	public static function getPackerAtlas(key:String, ?library:String):Dynamic;
	public static function getAsepriteAtlas(key:String, ?library:String):Dynamic;
	public static function getAtlas(key:String, ?library:String):Dynamic;
	public static function getMultiAtlas(keys:Array<String>, ?library:String):Dynamic;
	public static function loadAnimateAtlas(sprite:Dynamic, folder:String, ?sprite:String, ?animation:String):Dynamic;
	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false, ?ignoredFolders:Array<String> = null):String;
}

/* ---------------------------------------------------------------- flixel */
extern class FlxG {
	public static var width:Int;
	public static var height:Int;
	public static var camera:FlxCamera;
	public static var state:Dynamic;
	public static var keys:Dynamic;
	public static var mouse:Dynamic;
	public static var gamepads:Dynamic;
	public static var sound:Dynamic;
	public static var save:Dynamic;
	public static function log(data:Dynamic):Void;
	public static function random(?min:Int, ?max:Int):Float;
	public static function overlap(?object1:Dynamic, ?object2:Dynamic, ?notifyCallback:Dynamic):Bool;
}

extern class FlxCamera {
	public var zoom:Float;
	public var alpha:Float;
	public var x:Float;
	public var y:Float;
	public var scroll:Dynamic;
	public var target:Dynamic;
	public var width:Int;
	public var height:Int;
	public function shake(?intensity:Float, ?duration:Float):Void;
	public function flash(?color:Int, ?duration:Float, ?force:Bool):Void;
	public function fade(?color:Int, ?duration:Float, ?fadeIn:Bool, ?force:Bool):Void;
	public function setScroll(x:Float, y:Float):Void;
}

extern class FlxObject {
	public var x:Float;
	public var y:Float;
	public var angle:Float;
	public var alpha:Float;
	public var visible:Bool;
	public var active:Bool;
	public var scrollFactor:Dynamic;
	public var cameras:Array<FlxCamera>;
	public function getMidpoint():Dynamic;
	public function getScreenPosition(?camera:FlxCamera):Dynamic;
	public function isOnScreen(?camera:FlxCamera):Bool;
}

extern class FlxBasic extends FlxObject {
	public function destroy():Void;
	public function kill():Void;
	public function revive():Void;
}

extern class FlxSprite extends FlxBasic {
	public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:Dynamic);
	public var scale:Dynamic;
	public var offset:Dynamic;
	public var origin:Dynamic;
	public var color:Int;
	public var antialiasing:Bool;
	public var animation:Dynamic;
	public var shader:Dynamic;
	public var graphic:Dynamic;
	public function loadGraphic(graphic:Dynamic, ?animated:Bool, ?frameWidth:Int, ?frameHeight:Int):Void;
	public function loadFrames(frames:Dynamic, ?destroy:Bool):Void;
	public function makeGraphic(width:Int, height:Int, ?color:Int):Void;
	public function setGraphicSize(?width:Int, ?height:Int):Void;
	public function updateHitbox():Void;
	public function setPosition(x:Float, y:Float):Void;
	public function setBlendMode(mode:Dynamic):Void;
}

extern class FlxText extends FlxSprite {
	public function new(?x:Float = 0, ?y:Float = 0, ?fieldWidth:Int = 0, ?text:String = '', ?size:Int = 8);
	public var text:String;
	public var size:Int;
	public var font:String;
	public var borderSize:Int;
	public var borderColor:Int;
	public var borderStyle:Dynamic;
	public var alignment:Dynamic;
	public var fieldWidth:Int;
	public function setFormat(?font:String, ?size:Int, ?color:Int, ?align:Dynamic, ?borderStyle:Dynamic, ?borderColor:Int):Void;
}

extern class FlxSound {
	public var time:Float;
	public var pitch:Float;
	public var volume:Float;
	public var length:Float;
	public var playing:Bool;
	public function play(?forceRestart:Bool = true):Void;
	public function pause():Void;
	public function resume():Void;
	public function stop():Void;
	public function fadeIn(?duration:Float, ?from:Float, ?to:Float):Void;
	public function fadeOut(?duration:Float, ?to:Float):Void;
	public function cancelFade():Void;
}

extern class FlxTimer {
	public function new();
	public static function globalManager:Dynamic;
	public function start(?time:Float = 1, ?onComplete:Dynamic):Void;
	public function cancel():Void;
}

extern class FlxTween {
	public static function tween(object:Dynamic, values:Dynamic, duration:Float, ?options:Dynamic):FlxTween;
	public static function color(object:Dynamic, values:Dynamic, duration:Float, ?options:Dynamic):FlxTween;
	public static function cancel(tween:FlxTween, ?field:String, ?complete:Bool):Void;
	public var active:Bool;
	public function cancel():Void;
}

extern class FlxEase {
	public static var linear:Dynamic;
	public static var sineIn:Dynamic; public static var sineOut:Dynamic; public static var sineInOut:Dynamic;
	public static var quadIn:Dynamic; public static var quadOut:Dynamic; public static var quadInOut:Dynamic;
	public static var cubeIn:Dynamic; public static var cubeOut:Dynamic; public static var cubeInOut:Dynamic;
	public static var quartIn:Dynamic; public static var quartOut:Dynamic; public static var quartInOut:Dynamic;
	public static var quintIn:Dynamic; public static var quintOut:Dynamic; public static var quintInOut:Dynamic;
	public static var expoIn:Dynamic; public static var expoOut:Dynamic; public static var expoInOut:Dynamic;
	public static var circIn:Dynamic; public static var circOut:Dynamic; public static var circInOut:Dynamic;
	public static var backIn:Dynamic; public static var backOut:Dynamic; public static var backInOut:Dynamic;
	public static var bounceIn:Dynamic; public static var bounceOut:Dynamic; public static var bounceInOut:Dynamic;
	public static var elasticIn:Dynamic; public static var elasticOut:Dynamic; public static var elasticInOut:Dynamic;
}

extern class FlxColor {
	public static function fromString(color:String):Int;
	public static function fromRGB(red:Int, green:Int, blue:Int):Int;
	public static function fromHSV(hue:Float, saturation:Float, brightness:Float):Int;
	public static var WHITE:Int; public static var BLACK:Int; public static var RED:Int;
	public static var GREEN:Int; public static var BLUE:Int; public static var TRANSPARENT:Int;
	public static var YELLOW:Int; public static var PURPLE:Int; public static var ORANGE:Int;
}

extern class FlxSave {
	public function new();
	public var data:Dynamic;
	public function bind(name:String):Bool;
	public function flush():Bool;
}

extern class FlxRuntimeShader {
	public function new(?fragmentSource:String, ?vertexSource:String);
	public function setFloat(name:String, value:Float):Bool;
	public function setInt(name:String, value:Int):Bool;
	public function setBool(name:String, value:Bool):Bool;
	public function setFloatArray(name:String, values:Array<Float>):Bool;
	public function getFloat(name:String):Float;
	public function getInt(name:String):Int;
}

/* ------------------------------------------------------------- openfl */
extern class BlendMode {
	public static var ADD:Dynamic; public static var NORMAL:Dynamic;
	public static var SUBTRACT:Dynamic; public static var MULTIPLY:Dynamic;
	public static var SCREEN:Dynamic;
}

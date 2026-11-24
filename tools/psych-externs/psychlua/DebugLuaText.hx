package psychlua;

/**
 * Psych's on-screen debug console, where luaTrace output goes when a script asks
 * for it.
 */
extern class DebugLuaText extends FlxText {
	public static var instance:DebugLuaText;
	public function new(?x:Float = 0, ?y:Float = 0, ?width:Int = 0):Void;
	public function addText(text:String, ?color:FlxColor = cast 0xFFFFFFFF, ?isBold:Bool = false):Void;
	public function addTextToDebug(text:String, ?color:FlxColor = cast 0xFFFFFFFF):Void;
	public function setVisible(value:Bool):Void;
}

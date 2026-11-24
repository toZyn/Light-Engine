/**
 * Psych's on-screen debug console, where luaTrace output goes when the script
 * asks for it.
 */
extern class DebugLuaText {
	public static var instance:DebugLuaText;
	public function addText(text:String, ?color:Int = 0xFFFFFFFF, ?isBold:Bool = false):Void;
	public function addTextToDebug(text:String, ?color:Int = 0xFFFFFFFF):Void;
	public function setVisible(value:Bool):Void;
}

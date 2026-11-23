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
	public var fieldHeight:Int;
	public var autoSize:Bool;
	public var italic:Bool;
	public function setFormat(?font:String, ?size:Int, ?color:Int, ?align:Dynamic, ?borderStyle:Dynamic, ?borderColor:Int):Void;
}

extern class FlxSave {
	public function new();
	public var data:Dynamic;
	public function bind(name:String, ?folder:String):Bool;
	public function flush():Bool;
}

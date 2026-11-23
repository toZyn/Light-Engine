extern class FlxSave {
	public function new();
	public var data:Dynamic;
	public function bind(name:String):Bool;
	public function flush():Bool;
}

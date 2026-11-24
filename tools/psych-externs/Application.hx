/**
 * openfl's application object, where the window lives. Scripts read the stage
 * size and close the game through it.
 */
extern class Application {
	public static var current:Application;
	public var stage:Dynamic;
	public var window:Dynamic;
	public function exit(code:Int):Void;
}

/**
 * A flixel state. Scripts add sprites to it through MusicBeatState's current
 * state, which is why `add` and `members` are needed here.
 */
extern class FlxState extends FlxBasic {
	public function new():Void;
	public var members:Array<FlxBasic>;
	public var persistentUpdate:Bool;
	public var persistentDraw:Bool;
	public function add(object:FlxBasic):FlxBasic;
	public function remove(object:FlxBasic, ?splice:Bool = false):FlxBasic;
	public function insert(position:Int, object:FlxBasic):Void;
}

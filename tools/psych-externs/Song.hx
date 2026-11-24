/**
 * A chart. Scripts read its tempo, speed and characters, and change the tempo
 * mid-song, which is why these are fields rather than constants.
 */
extern class Song {
	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function loadFromJson(json:Dynamic):Dynamic;

	public var song:String;
	public var stage:String;
	public var bpm:Float;
	public var speed:Float;
	public var needsVoices:Bool;
	public var player1:String;
	public var player2:String;
	public var gfVersion:String;
	public var format:String;
	public var sections:Array<SwagSection>;
	public var notes:Array<Dynamic>;
	public var events:Array<Dynamic>;
	public var validScore:Bool;
}

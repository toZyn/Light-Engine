/**
 * Score storage and the song-name formatter the score files are keyed by.
 */
extern class Highscore {
	public static var saves:Map<String, Dynamic>;
	public static function reset():Void;
	public static function saveScore(score:Int, ?song:String, ?diff:Int, ?misses:Int, ?accuracy:Float):Void;
	public static function formatSong(song:String, diff:Int):String;
	public static function formatSongName(song:String):String;
	public static function formatScore(score:Int):String;
}

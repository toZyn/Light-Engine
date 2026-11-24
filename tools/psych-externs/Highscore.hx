/**
 * Score storage. Scripts can reset it, so Psych needs the file prefix and the
 * save object.
 */
extern class Highscore {
	public static var saves:Map<String, Dynamic>;
	public static function reset():Void;
	public static function saveScore(score:Dynamic, ?song:String, ?diff:Int):Void;
	public static function formatScore(score:Int):String;
}

/**
 * The week list a song belongs to. Psych reads the current week's name from it.
 */
extern class WeekData {
	public static var weeksList:Array<String>;
	public static function reloadAllWeeks():Void;
}

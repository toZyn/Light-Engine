/**
 * The week select. Psych reads the current week and difficulty from it.
 */
extern class StoryMenuState extends MusicBeatState {
	public static var weekCompleted:Map<String, Bool>;
	public static var curDifficulty:Int;
	public static var curWeek:Int;
}

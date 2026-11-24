/**
 * Psych's achievement backend, when it is compiled in.
 */
extern class Achievements {
	public static function unlockAchievement(name:String, ?absolute:Bool = false):Bool;
	public static function isAchievementUnlocked(name:String):Bool;
	public static function loadAchievements():Void;
}

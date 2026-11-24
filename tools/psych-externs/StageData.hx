/**
 * Psych's stage loader. Scripts read the stage's own folder and defaults from
 * what it parsed.
 */
extern class StageData {
	public static function getStageFile(stage:String):StageFile;
	public static var currentStage:String;
}

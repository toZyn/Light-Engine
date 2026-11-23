/**
 * A parsed stage JSON. Psych reads `directory` to know where the stage's own
 * assets live.
 */
extern class StageFile {
	public var directory:String;
	public var defaultZoom:Float;
	public var isPixelStage:Bool;
}

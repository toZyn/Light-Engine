/**
 * The song clock. Scripts read the current beat and step, and can follow the
 * song position directly.
 */
extern class Conductor {
	public static var bpm:Float;
	public static var crochet:Float;
	public static var stepCrochet:Float;
	public static var songPosition:Float;
	public static var songLength:Float;
	public static var curBeat:Int;
	public static var curStep:Int;
	public static var curDecBeat:Float;
	public static var curDecStep:Float;
	public static var curSection:Int;
	public static var offset:Float;
	public static function mapBPMChange(newBPM:Float, ?startTime:Float):Void;
}

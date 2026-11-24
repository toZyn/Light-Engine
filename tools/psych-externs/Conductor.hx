/**
 * Psych's tempo maths: the beat length derived from the song's BPM. The beat
 * *clock* lives on MusicBeatState, not here.
 */
extern class Conductor {
	public static var bpm:Float;
	public static var crochet:Float;
	public static var stepCrochet:Float;
	public static var songPosition:Float;
	public static function mapBPMChange(newBPM:Float, ?startTime:Float):Void;
}

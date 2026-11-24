/**
 * One section of a chart: the steps and the events that fire on it.
 */
extern class SwagSection {
	public var sectionBeats:Float;
	public var mustHitSection:Bool;
	public var altAnim:Bool;
	public var gfSection:Bool;
	public var changeBPM:Bool;
	public var bpm:Float;
	public var notes:Array<Dynamic>;
	public var sectionNotes:Array<Dynamic>;
}

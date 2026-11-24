extern class Song {
	public static var chartPath:String;
	public var stage:String;
	public var song:String;
	public static var loadedSongName:String;
	public static function loadFromJson(json:Dynamic):Dynamic;
}

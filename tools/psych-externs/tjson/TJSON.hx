package tjson;

/**
 * The tolerant JSON parser Psych uses for its own data files, where a trailing
 * comma or a comment would break the strict parser.
 */
extern class TJSON {
	public static function parse(data:String):Dynamic;
	public static function encode(value:Dynamic, ?pretty:Bool = false):String;
	public static var parseTrace:String;
}

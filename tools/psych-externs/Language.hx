/**
 * Psych's translation lookup, used when a script passes a string key instead of
 * literal text.
 */
extern class Language {
	public function new(?lang:String):Void;
	public function get(key:String, ?values:Array<Dynamic>):String;
	public static function getGlobal():Language;
}

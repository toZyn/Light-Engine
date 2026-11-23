/**
 * Psych's property-path resolver. Scripts name objects with dotted paths
 * (`"boyfriend.animation.curAnim"`), and these three turn that string into the
 * live object and back.
 */
extern class LuaUtils {
	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic;
	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic;
	public static function getVarInArray(instance:Dynamic, variable:String, ?allowMaps:Bool = false):Dynamic;
	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false):Bool;
}

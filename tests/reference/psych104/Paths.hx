import sys.FileSystem;import sys.io.File;
enum AssetType {TEXT;}
class Paths {
 public static function getPath(p:String,t:AssetType,mods:Bool=true) return "/tmp/psych-files-comparison/"+p;
 public static function mods(p:String) return "/tmp/psych-files-comparison/"+p;
 public static function getTextFromFile(p:String,ignore:Bool=false):String {var path=getPath(p,TEXT,!ignore);return FileSystem.exists(path)?File.getContent(path):null;}
}
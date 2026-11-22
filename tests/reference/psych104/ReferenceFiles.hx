// Adapted reference excerpts from Psych Engine 1.0.4 (ShadowMario and contributors), Apache-2.0.
// Modified: isolated callback/declaration harness with synthetic providers; see LICENSE-Psych.txt and README.md.
import sys.FileSystem;
import sys.io.File;
class ReferenceFiles {
 static var callbacks:Map<String,Dynamic> = [];
 static function register(name:String, fn:Dynamic) { callbacks.set(name, fn); }
 static function main() {
register( "checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute) return FileSystem.exists(filename);

			return FileSystem.exists(Paths.getPath(filename, TEXT));

			#else
			if(absolute) return Assets.exists(filename, TEXT);

			return Assets.exists(Paths.getPath(filename, TEXT));
			#end
		});
register( "saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
					File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
register( "deleteFile", function(path:String, ?ignoreModFolders:Bool = false, ?absolute:Bool = false)
		{
			try {
				var lePath:String = path;
				if(!absolute) lePath = Paths.getPath(path, TEXT, !ignoreModFolders);
				if(FileSystem.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				FunkinLua.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
register( "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
register( "directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});
 var cases:Array<Dynamic> = [];
 function check(name:String,args:Array<Dynamic>) {
  var value:Dynamic=null;var error=false;
  try value=Reflect.callMethod(null,callbacks.get(name),args) catch(e:Dynamic) error=true;
  if(name=="directoryFileList") {var a:Array<String>=value; a.sort(Reflect.compare);}
  cases.push({name:name,args:args,value:value,error:error});
 }
 var base="/tmp/psych-files-comparison";
 if(!FileSystem.exists(base)) FileSystem.createDirectory(base);
 if(FileSystem.exists(base+"/data.txt")) FileSystem.deleteFile(base+"/data.txt");
 check("checkFileExists",["missing.txt"]);
 check("saveFile",["data.txt","hello\nworld"]);
 check("checkFileExists",["data.txt"]);
 check("getTextFromFile",["data.txt"]);
 check("getTextFromFile",["missing.txt"]);
 check("directoryFileList",[base]);
 check("directoryFileList",[base+"/missing"]);
 check("saveFile",[base+"/direct.txt","direct",true]);
 check("checkFileExists",[base+"/direct.txt",true]);
 check("deleteFile",[base+"/direct.txt",false,true]);
 check("deleteFile",["data.txt"]);
 check("deleteFile",["data.txt"]);
 check("saveFile",["missing/data.txt","no"]);
 Sys.println(haxe.Json.stringify(cases));
 }
}
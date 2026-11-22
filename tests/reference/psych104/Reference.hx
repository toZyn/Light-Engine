using StringTools;
class Reference {
 static var lua:Dynamic;
 static var callbacks:Map<String,Dynamic> = [];
 static function register(name:String, fn:Dynamic) { callbacks.set(name, fn); }
 static function main() {
register( "stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
register( "stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
register( "stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
register( "stringTrim", function(str:String) {
			return str.trim();
		});
register( "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '') break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
register( "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '') break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
register( "getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
 var cases:Array<Dynamic> = [];
 function check(name:String,args:Array<Dynamic>) {
  var value:Dynamic=null;var error=false;
  try value=Reflect.callMethod(null,callbacks.get(name),args) catch(e:Dynamic) error=true;
  cases.push({name:name,args:args,value:value,error:error});
 }
check("stringStartsWith",["abc", ""]);
check("stringStartsWith",["Abc", "a"]);
check("stringEndsWith",["abc", "bc"]);
check("stringEndsWith",["a", "long"]);
check("stringSplit",["a,,b,", ","]);
check("stringSplit",["", ""]);
check("stringSplit",["Aé𐐀", ""]);
check("stringSplit",["a.b", "."]);
check("stringTrim",[" \t\r\na \t\r\n"]);
check("stringTrim",[" a "]);
check("stringTrim",[""]);
check("stringTrim",[null]);
check("getRandomInt",[1, 5, "2,3"]);
check("getRandomInt",[1, 5, "2,3"]);
check("getRandomInt",[1, 5, "2,3"]);
check("getRandomInt",[1, 5, "2,3"]);
check("getRandomInt",[1, 5, "2,3"]);
check("getRandomInt",[7, 3, ""]);
check("getRandomInt",[7, 3, ""]);
check("getRandomInt",[7, 3, ""]);
check("getRandomInt",[7, 3, ""]);
check("getRandomInt",[7, 3, ""]);
check("getRandomInt",[5, 5, "5"]);
check("getRandomInt",[5, 5, "5"]);
check("getRandomInt",[5, 5, "5"]);
check("getRandomInt",[5, 5, "5"]);
check("getRandomInt",[5, 5, "5"]);
check("getRandomInt",[2]);
check("getRandomInt",[2]);
check("getRandomInt",[2]);
check("getRandomInt",[2]);
check("getRandomInt",[2]);
check("getRandomFloat",[0, 1, ""]);
check("getRandomFloat",[0, 1, ""]);
check("getRandomFloat",[0, 1, ""]);
check("getRandomFloat",[0, 1, ""]);
check("getRandomFloat",[0, 1, ""]);
check("getRandomFloat",[3, 1, ""]);
check("getRandomFloat",[3, 1, ""]);
check("getRandomFloat",[3, 1, ""]);
check("getRandomFloat",[3, 1, ""]);
check("getRandomFloat",[3, 1, ""]);
check("getRandomFloat",[2, 2, "2"]);
check("getRandomFloat",[2, 2, "2"]);
check("getRandomFloat",[2, 2, "2"]);
check("getRandomFloat",[2, 2, "2"]);
check("getRandomFloat",[2, 2, "2"]);
check("getRandomBool",[]);
check("getRandomBool",[]);
check("getRandomBool",[]);
check("getRandomBool",[]);
check("getRandomBool",[]);
check("getRandomBool",[0]);
check("getRandomBool",[0]);
check("getRandomBool",[0]);
check("getRandomBool",[0]);
check("getRandomBool",[0]);
check("getRandomBool",[100]);
check("getRandomBool",[100]);
check("getRandomBool",[100]);
check("getRandomBool",[100]);
check("getRandomBool",[100]);
check("getRandomBool",[-1]);
check("getRandomBool",[-1]);
check("getRandomBool",[-1]);
check("getRandomBool",[-1]);
check("getRandomBool",[-1]);
Sys.println(haxe.Json.stringify(cases));
 }
}
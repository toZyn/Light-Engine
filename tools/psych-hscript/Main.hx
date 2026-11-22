import crowplexus.hscript.Expr;
import crowplexus.hscript.Interp;
import crowplexus.hscript.Parser;
import crowplexus.hscript.Printer;
import haxe.Exception;
import lua.Lua;

private class ScopedInterp extends Interp {
	public var remaining:Int;
	final constructors:Map<String, Array<Dynamic>->Dynamic> = [];
	final importsAllowed:Map<String, Dynamic> = [
		"Math" => Math,
		"Std" => Std,
		"StringTools" => StringTools
	];

	public function expose(name:String, value:Dynamic):Void {
		importsAllowed.set(name, value);
	}

	override public function getOrImportClass(name:String):Dynamic {
		return importsAllowed.get(name);
	}

	override public function expr(expr:Expr):Dynamic {
		if (--remaining < 0) throw "HScript execution limit exceeded";
		return super.expr(expr);
	}

	public function registerConstructor(name:String, make:Array<Dynamic>->Dynamic):Void {
		constructors.set(name, make);
	}

	override function cnew(name:String, args:Array<Dynamic>):Dynamic {
		final make = constructors.get(name);
		if (make != null) return make(args);
		throw 'HScript registerConstructor unavailable: $name';
	}
}

class Main {
	static function run(exec:Void->Dynamic):Dynamic {
		try {
			return exec();
		} catch (error:crowplexus.hscript.Expr.Error) {
			Lua.error(Printer.errorToString(error, true));
		} catch (error:Exception) {
			Lua.error(error.message);
		}
		return null;
	}

	static function create(name:String):Dynamic {
		final interp = new ScopedInterp();
		interp.variables.set("Math", Math);
		interp.variables.set("Std", Std);
		interp.variables.set("StringTools", StringTools);
		return {
			bind: function(key:String, value:Dynamic) interp.variables.set(key, value),
			expose: function(key:String, value:Dynamic) interp.expose(key, value),
			registerConstructor: function(key:String, make:Array<Dynamic>->Dynamic) interp.registerConstructor(key, make),
			has: function(key:String) return Reflect.isFunction(interp.variables.get(key)),
			eval: function(source:String) return run(function() {
				final parser = new Parser();
				parser.allowTypes = true;
				parser.allowMetadata = true;
				parser.allowJSON = true;
				interp.remaining = 100000;
				return interp.execute(parser.parseString(source, name));
			}),
			invoke: function(key:String, values:Dynamic, count:Int) return run(function() {
				final callback = interp.variables.get(key);
				if (!Reflect.isFunction(callback)) return null;
				final args = [for (i in 0...count) untyped values[i + 1]];
				interp.remaining = 100000;
				return Reflect.callMethod(null, callback, args);
			})
		};
	}

	static function main():Void {
		untyped __lua__("_G.lightHScriptCreate = {0}", create);
	}
}

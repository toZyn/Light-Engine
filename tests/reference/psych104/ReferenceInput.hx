// Adapted reference excerpts from Psych Engine 1.0.4 (ShadowMario and contributors), Apache-2.0.
// Modified: isolated callback/declaration harness with synthetic providers; see LICENSE-Psych.txt and README.md.
using StringTools;
enum Stick { LEFT_ANALOG_STICK; RIGHT_ANALOG_STICK; }
class ReferenceInput {
 static var callbacks:Map<String,Dynamic> = [];
 static function register(name:String, fn:Dynamic) { callbacks.set(name, fn); }
 static function main() {
register( "keyboardJustPressed", function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
register( "keyboardPressed", function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
register( "keyboardReleased", function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));
register( "anyGamepadJustPressed", function(name:String) return FlxG.gamepads.anyJustPressed(name));
register( "anyGamepadPressed", function(name:String) FlxG.gamepads.anyPressed(name));
register( "anyGamepadReleased", function(name:String) return FlxG.gamepads.anyJustReleased(name));
register( "gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
register( "gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
register( "gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
register( "gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
register( "gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});
register( "keyJustPressed", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': return PlayState.instance.controls.NOTE_UP_P;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_P;
				default: return PlayState.instance.controls.justPressed(name);
			}
			return false;
		});
register( "keyPressed", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT;
				case 'down': return PlayState.instance.controls.NOTE_DOWN;
				case 'up': return PlayState.instance.controls.NOTE_UP;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT;
				default: return PlayState.instance.controls.pressed(name);
			}
			return false;
		});
register( "keyReleased", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': return PlayState.instance.controls.NOTE_UP_R;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_R;
				default: return PlayState.instance.controls.justReleased(name);
			}
			return false;
		});
 var cases:Array<Dynamic> = [];
 function check(name:String,args:Array<Dynamic>) {
  var value:Dynamic=null;var error=false;
  try value=Reflect.callMethod(null,callbacks.get(name),args) catch(e:Dynamic) error=true;
  cases.push({name:name,args:args,value:value,error:error});
 }
check("keyboardJustPressed",["A"]);
check("keyboardJustPressed",["B"]);
check("keyboardJustPressed",["NOT_A_KEY"]);
check("keyboardJustPressed",["a"]);
check("keyboardPressed",["A"]);
check("keyboardPressed",["B"]);
check("keyboardPressed",["NOT_A_KEY"]);
check("keyboardPressed",["a"]);
check("keyboardReleased",["A"]);
check("keyboardReleased",["B"]);
check("keyboardReleased",["NOT_A_KEY"]);
check("keyboardReleased",["a"]);
check("anyGamepadJustPressed",["A"]);
check("anyGamepadJustPressed",["B"]);
check("anyGamepadJustPressed",["NOT_A_KEY"]);
check("anyGamepadJustPressed",["a"]);
check("anyGamepadPressed",["A"]);
check("anyGamepadPressed",["B"]);
check("anyGamepadPressed",["NOT_A_KEY"]);
check("anyGamepadPressed",["a"]);
check("anyGamepadReleased",["A"]);
check("anyGamepadReleased",["B"]);
check("anyGamepadReleased",["NOT_A_KEY"]);
check("anyGamepadReleased",["a"]);
check("gamepadAnalogX",[0]);
check("gamepadAnalogX",[0, false]);
check("gamepadAnalogX",[8]);
check("gamepadAnalogY",[0]);
check("gamepadAnalogY",[0, false]);
check("gamepadAnalogY",[8]);
check("gamepadJustPressed",[0, "A"]);
check("gamepadJustPressed",[0, "B"]);
check("gamepadJustPressed",[8, "A"]);
check("gamepadJustPressed",[0, "a"]);
check("gamepadPressed",[0, "A"]);
check("gamepadPressed",[0, "B"]);
check("gamepadPressed",[8, "A"]);
check("gamepadPressed",[0, "a"]);
check("gamepadReleased",[0, "A"]);
check("gamepadReleased",[0, "B"]);
check("gamepadReleased",[8, "A"]);
check("gamepadReleased",[0, "a"]);
check("keyJustPressed",[]);
check("keyJustPressed",[" LEFT "]);
check("keyJustPressed",["note_left"]);
check("keyJustPressed",["accept"]);
check("keyJustPressed",["missing"]);
check("keyPressed",[]);
check("keyPressed",[" LEFT "]);
check("keyPressed",["note_left"]);
check("keyPressed",["accept"]);
check("keyPressed",["missing"]);
check("keyReleased",[]);
check("keyReleased",[" LEFT "]);
check("keyReleased",["note_left"]);
check("keyReleased",["accept"]);
check("keyReleased",["missing"]);
check("keyJustPressed",["space"]);
Sys.println(haxe.Json.stringify(cases));
 }
}
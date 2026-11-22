class Pads { public function new() {} public function getByID(id:Int):Dynamic {return id==0 ? {
 justPressed:{A:true,B:false},pressed:{A:true,B:false},justReleased:{A:true,B:false},
 getXAxis:function(s:ReferenceInput.Stick) return s==LEFT_ANALOG_STICK ? 0.75 : -0.25,
 getYAxis:function(s:ReferenceInput.Stick) return s==LEFT_ANALOG_STICK ? -0.5 : 0.5} : null;}
 public function anyJustPressed(n:String) return n=="A";
 public function anyPressed(n:String) return n=="A";
 public function anyJustReleased(n:String) return n=="A"; }
class FlxG {public static var random=new Random();public static var gamepads=new Pads();public static var keys:Dynamic={justPressed:{A:true,B:false},pressed:{A:true,B:false},justReleased:{A:true,B:false}};}
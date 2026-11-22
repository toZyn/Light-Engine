class PlayState { public static var instance:Dynamic = {controls: {
 NOTE_LEFT_P:true,NOTE_LEFT:true,NOTE_LEFT_R:true,NOTE_DOWN_P:false,NOTE_DOWN:false,NOTE_DOWN_R:false,
 NOTE_UP_P:false,NOTE_UP:false,NOTE_UP_R:false,NOTE_RIGHT_P:false,NOTE_RIGHT:false,NOTE_RIGHT_R:false,
 justPressed:function(n:String) return n=="note_left",pressed:function(n:String) return n=="note_left",justReleased:function(n:String) return n=="note_left"}}; }
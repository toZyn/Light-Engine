// Adapted Psych 1.0.4 PlayState reference (ShadowMario and contributors), Apache-2.0.
// Modified: synthetic fields, callback capture and case runner; original method bodies retained.

class LuaUtils {public static var Function_Stop='##PSYCHLUA_FUNCTIONSTOP';}
class ReferenceRating {
 public var songScore:Int=0; public var songMisses:Int=0; public var songHits:Int=0; public var combo:Int=0;
 public var ratingName:String='?'; public var ratingPercent:Float=0; public var ratingFC:String=null;
 public var totalPlayed:Int=0; public var totalNotesHit:Float=0;
 public var ratingsData:Array<Dynamic>;
 public var events:Array<Dynamic>=[];public var stopped:Bool=false;
 public function new() {ratingsData=[{hits:0},{hits:0},{hits:0},{hits:0}];}
 function setOnScripts(name:String,value:Dynamic) {events.push({kind:'set',name:name,value:value});}
 function callOnScripts(name:String,args:Dynamic=null,ignoreStops:Bool=false):Dynamic {events.push({kind:'call',name:name});return stopped ? LuaUtils.Function_Stop : null;}
 function updateScore(badHit:Bool=false,scoreBop:Bool=true) {}
public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}
public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}
 static function main() {
  var cases:Array<Dynamic>=[];
  for (value in [-1.0,0.0,0.199999,0.2,0.399999,0.4,0.499999,0.5,0.599999,0.6,0.689999,0.69,0.699999,0.7,0.799999,0.8,0.899999,0.9,0.999999,1.0,2.0]) cases.push({played:100,hit:value*100,misses:0,hits:[1,0,0,0],stop:false});
  for (miss in [0,1,9,10,50]) for (hits in [[0,0,0,0],[1,0,0,0],[1,1,0,0],[1,1,1,0],[1,1,0,1]]) cases.push({played:10,hit:7.0,misses:miss,hits:hits,stop:false});
  cases.push({played:0,hit:0.0,misses:0,hits:[0,0,0,0],stop:false});
  cases.push({played:100,hit:50.0,misses:4,hits:[1,0,0,0],stop:true});
  var output:Array<Dynamic>=[];
  for (input in cases) {
   var r=new ReferenceRating();r.totalPlayed=input.played;r.totalNotesHit=input.hit;r.songMisses=input.misses;r.stopped=input.stop;
   var values:Array<Int>=input.hits;
   for (i in 0...4) r.ratingsData[i].hits=values[i];
   r.RecalculateRating();
   output.push({input:input,ratingName:r.ratingName,ratingPercent:r.ratingPercent,ratingFC:r.ratingFC,events:r.events});
  }
  Sys.println(haxe.Json.stringify(output));
 }
}

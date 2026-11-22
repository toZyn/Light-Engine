class Reference {
public var songScore:Int = 0;
public var songHits:Int = 0;
public var songMisses:Int = 0;
public var combo:Int = 0;
public var totalPlayed:Int = 0;
public var totalNotesHit:Float = 0.0;
public var ratingName:String = '?';
public var ratingPercent:Float;
public var ratingFC:String;
public function new() {}
}
class ReferenceInitialization {static function main() { var r=new Reference(); Sys.println(haxe.Json.stringify(r)); }}
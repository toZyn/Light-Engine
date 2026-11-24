/**
 * The Discord presence client. Scripts change the presence string.
 */
extern class DiscordClient {
	public static var instance:DiscordClient;
	public function changePresence(?details:String, ?state:String, ?startTimestamp:Bool):Void;
	public function shutdown():Void;
}

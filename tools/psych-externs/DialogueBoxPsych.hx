/**
 * Psych's dialogue box, opened by a script with a JSON file.
 */
extern class DialogueBoxPsych extends FlxSpriteGroup {
	public function new(dialogueFile:DialogueFile, ?songName:String):Void;
	public static var finishThing:Void->Void;
}

/**
 * How a tween repeats. Psych reads these when it builds tween options from a
 * script's `{type = 'pingpong'}` table.
 */
extern enum FlxTweenType {
	BACKWARD;
	LOOPING;
	ONESHOT;
	PERSIST;
	PINGPONG;
}

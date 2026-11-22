class Random { public var internalSeed:Float = 1; static inline var MODULUS:Int=2147483647; static inline var MULTIPLIER:Float=48271.0; public function new() {}
public function int(Min:Int = 0, Max:Int = FlxMath.MAX_VALUE_INT, ?Excludes:Array<Int>):Int
	{
		if (Min == 0 && Max == FlxMath.MAX_VALUE_INT && Excludes == null)
		{
			return Std.int(generate());
		}
		else if (Min == Max)
		{
			return Min;
		}
		else
		{
			// Swap values if reversed
			if (Min > Max)
			{
				Min = Min + Max;
				Max = Min - Max;
				Min = Min - Max;
			}

			if (Excludes == null)
			{
				return Math.floor(Min + generate() / MODULUS * (Max - Min + 1));
			}
			else
			{
				var result:Int = 0;

				do
				{
					result = Math.floor(Min + generate() / MODULUS * (Max - Min + 1));
				}
				while (Excludes.indexOf(result) >= 0);

				return result;
			}
		}
	}
public function float(Min:Float = 0, Max:Float = 1, ?Excludes:Array<Float>):Float
	{
		var result:Float = 0;

		if (Min == 0 && Max == 1 && Excludes == null)
		{
			return generate() / MODULUS;
		}
		else if (Min == Max)
		{
			result = Min;
		}
		else
		{
			// Swap values if reversed.
			if (Min > Max)
			{
				Min = Min + Max;
				Max = Min - Max;
				Min = Min - Max;
			}

			if (Excludes == null)
			{
				result = Min + (generate() / MODULUS) * (Max - Min);
			}
			else
			{
				do
				{
					result = Min + (generate() / MODULUS) * (Max - Min);
				}
				while (Excludes.indexOf(result) >= 0);
			}
		}

		return result;
	}
public function bool(Chance:Float = 50):Bool
	{
		return float(0, 100) < Chance;
	}
public function generate():Float
	{
		return internalSeed = (internalSeed * MULTIPLIER) % MODULUS;
	}
}
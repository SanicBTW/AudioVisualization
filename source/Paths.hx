package;

import backend.Cache;
import flixel.graphics.FlxGraphic;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

class Paths
{
	private static var currentLevel:String;

	public static function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = "";
			if (currentLevel != "shared")
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (Assets.exists(levelPath))
					return levelPath;
				else
					trace('Asset at path $levelPath doesn\'t exist (PATHS - CURRENT LEVEL)');
			}

			levelPath = getLibraryPathForce(file, "");
			if (Assets.exists(levelPath))
				return levelPath;
			else
				trace('Asset at path $levelPath doesn\'t exist (PATHS - CURRENT LEVEL SHARED)');
		}

		return getPreloadPath(file);
	}

	public static inline function getLibraryPath(file:String, library:String = "default")
		return (library == "default" ? getPreloadPath(file) : getLibraryPathForce(file, library));

	private static inline function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	public static inline function getPreloadPath(file:String)
		return 'assets/$file';

	public static inline function file(file:String, ?library:String)
		return getPath(file, library);

	public static inline function sound(key:String, ?library:String):Sound
		return Cache.getSound(getPath('sounds/$key.ogg', library));

	public static inline function font(key:String)
		return 'assets/fonts/$key';

	public static inline function music(key:String, ?library:String):Sound
		return Cache.getSound(getPath('music/$key.ogg', library));

	public static inline function image(key:String, ?library:String):FlxGraphic
		return Cache.getGraphic(getPath('images/$key.png', library));

	public static inline function formatString(string:String)
		return string.toLowerCase().replace(" ", "-");
}

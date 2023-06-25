package;

import backend.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import soloud.*;
import window.debug.*;

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = states.State;
	private var zoom:Float = -1;
	private var framerate:Int = 250;

	#if !hl
	@:unreflective public static var soloud:Soloud;
	#end

	public static function main()
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		#if !hl
		soloud = Soloud.create();
		#end

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event)
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		// Enable GCs
		#if cpp
		cpp.vm.Gc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end

		// Setup soloud
		#if !hl
		soloud.init();
		soloud.setVisualizationEnable(true);
		#end

		// Do the funny
		Controls.Initialize();

		setupGame();

		#if !hl
		Application.current.window.onDropFile.add((filePath:String) ->
		{
			soloud.stopAll();
			var soundStream:WavStream = WavStream.create();
			soundStream.load(filePath);
			soundStream.setLooping(true);
			soloud.play(soundStream);
		});
		#end

		FlxG.signals.preStateCreate.add((state:FlxState) ->
		{
			Cache.clearStoredMemory();
			Cache.clearUnusedMemory();
			FlxG.bitmap.dumpCache();
			Cache.collect();
		});

		#if !hl
		FlxG.sound.volumeHandler = (vol:Float) ->
		{
			soloud.setGlobalVolume(vol);
		}
		#end
	}

	private function setupGame()
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		FlxGraphic.defaultPersist = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, true, false));

		FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();
		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end
	}
}

package states;

import backend.Cache;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import network.Request;
import network.pocketbase.Collection;
import network.pocketbase.Record;
import openfl.Lib;
import openfl.media.Sound;
#if !hl
import soloud.WavStream;
#end

class State extends FlxState
{
	#if !hl
	var sampleData:cpp.Pointer<cpp.Float32>;
	#end

	var bars:FlxTypedGroup<FlxSprite>;
	var targetZoom:Float = 1;
	var targetAlpha:Float = 0.2;

	var camMain:FlxCamera;
	var camUI:FlxCamera;

	// for the settings panel
	var hoverRegion:FlxSprite;
	var backSettings:FlxSprite;

	var panelX:Float = 0;
	var panelAlpha:Float = 0;

	// settings lol
	var beatThreshold:VisOption = {description: "The threshold that must be passed for a beat", value: 15};
	var beatsEnabled:Bool = false;

	override public function create()
	{
		camMain = new FlxCamera();
		FlxG.cameras.reset(camMain);
		camMain.bgColor = FlxColor.WHITE;
		camMain.bgColor.alphaFloat = targetAlpha;
		FlxG.cameras.setDefaultDrawTarget(camMain, true);

		camUI = new FlxCamera();
		camUI.bgColor.alpha = 0;
		FlxG.cameras.add(camUI, false);

		#if !hl
		var shit = WavStream.create();
		shit.load(Paths.getPath('music/sex.ogg'));
		shit.setLooping(true);
		Main.soloud.stopAll();
		Main.soloud.play(shit);
		#end

		bars = new FlxTypedGroup<FlxSprite>();
		add(bars);

		Cache.set(FlxGraphic.fromRectangle(10, 100, FlxColor.WHITE, true), GRAPHIC, "bar");
		for (i in 0...128)
		{
			var newBar:FlxSprite = new FlxSprite(0, 0).loadGraphic(Cache.get("bar", GRAPHIC));
			newBar.screenCenter();
			newBar.x = (i * 15);
			newBar.scrollFactor.x = 0;
			bars.add(newBar);
		}

		hoverRegion = new FlxSprite();
		regenGraphic(hoverRegion, 'hreg${FlxG.height}', 150, FlxG.height, FlxColor.TRANSPARENT);
		hoverRegion.cameras = [camUI];

		backSettings = new FlxSprite();
		regenGraphic(backSettings, 'setbg${FlxG.height}', 350, FlxG.height, FlxColor.BLACK);
		backSettings.alpha = 0;
		backSettings.cameras = [camUI];

		add(backSettings);
		add(hoverRegion);

		FlxG.signals.gameResized.add((w, h) ->
		{
			regenGraphic(hoverRegion, 'hreg$h', 150, h, FlxColor.TRANSPARENT);
			regenGraphic(backSettings, 'setbg$h', 350, h, FlxColor.BLACK);

			if (panelAlpha == 0.75)
				panelX = FlxG.width - backSettings.width;
			else
				panelX = FlxG.width + backSettings.width;
		});

		super.create();
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.5), 0, 1);

		updateVisualizer(lerpVal);
		updateCamera(lerpVal);
		updatePanel(lerpVal);

		super.update(elapsed);
	}

	public function updateVisualizer(lerp:Float)
	{
		#if !hl
		sampleData = Main.soloud.calcFFT();

		for (i in 0...bars.members.length)
		{
			var it = bars.members[i];

			it.scale.y = FlxMath.lerp(sampleData[i] / 4, it.scale.y, lerp);

			if (it.scale.y >= beatThreshold.value && beatsEnabled)
			{
				FlxG.camera.zoom += 0.015;
				FlxG.camera.bgColor.alphaFloat += 0.015;
			}
		}
		#end
	}

	public function updateCamera(lerp:Float)
	{
		if (FlxG.mouse.wheel != 0)
			targetZoom += FlxG.mouse.wheel / 10;

		if (FlxG.mouse.justPressedMiddle)
			targetZoom = 1;

		FlxG.camera.zoom = FlxMath.lerp(targetZoom, FlxG.camera.zoom, lerp);
		FlxG.camera.bgColor.alphaFloat = FlxMath.lerp(targetAlpha, FlxG.camera.bgColor.alphaFloat, lerp);
	}

	public function updatePanel(lerp:Float)
	{
		if (FlxG.mouse.screenX >= hoverRegion.x && FlxG.mouse.justPressed && panelAlpha != 0.75)
		{
			panelX = FlxG.width - backSettings.width;
			panelAlpha = 0.75;
		}

		if (FlxG.mouse.screenX <= backSettings.x && !FlxG.mouse.overlaps(hoverRegion) && FlxG.mouse.justPressed)
		{
			panelX = FlxG.width + backSettings.width;
			panelAlpha = 0;
		}

		lerpTrack(backSettings, "alpha", panelAlpha, lerp);
		lerpTrack(backSettings, "x", panelX, lerp);
	}

	private function regenGraphic(sprite:FlxSprite, key:String, width:Int, height:Int, color:FlxColor)
	{
		sprite.loadGraphic(Cache.set(FlxGraphic.fromRectangle(width, height, color), GRAPHIC, key));
		sprite.screenCenter(Y);
		sprite.x = FlxG.width - sprite.width;
	}

	private function lerpTrack(sprite:FlxSprite, property:String, track:Float, ratio:Float)
	{
		var field = Reflect.field(sprite, property);
		var lerp:Float = FlxMath.lerp(track, field, ratio);
		Reflect.setProperty(sprite, property, lerp);
	}

	public static inline function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));
}

typedef VisOption =
{
	var description:String;
	var value:Dynamic;
}

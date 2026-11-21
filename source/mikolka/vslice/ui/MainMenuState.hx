package mikolka.vslice.ui;

import mikolka.vslice.ui.mainmenu.DesktopMenuState;
import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.ui.title.TitleState;
import mikolka.compatibility.ModsHelper;
import options.OptionsState;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MainMenuState extends MusicBeatState
{
	#if !LEGACY_PSYCH
	public static var psychEngineVersion:String = '1.0.4';
	#else
	public static var psychEngineVersion:String = '0.6.3';
	#end
	public static var pSliceVersion:String = '3.4.2';
	public static var funkinVersion:String = '0.7.6';

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var checkerPattern:FlxBackdrop;
	var rightPanel:FlxSprite;

	var stickerSubState:Bool;
	var logoBl:FlxSprite;
	var baseLogoY:Float = 0;
	var logoTimer:Float = 0; // Usato per il movimento fluido a onda

	public function new(?stickers:Bool = false)
	{
		super();
		stickerSubState = stickers;
	}

	override function create()
	{
		if(stickerSubState) ModsHelper.clearStoredWithoutStickers();
		else CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();
		#if (debug && !LEGACY_PSYCH)
		FlxG.console.registerFunction("dumpCache",CacheSystem.cacheStatus); 
		FlxG.console.registerFunction("dumpSystem",backend.Native.buildSystemInfo);
		#end
		
		ModsHelper.resetActiveMods();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = VsliceOptions.ANTIALIASING;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = VsliceOptions.ANTIALIASING;
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		checkerPattern = new FlxBackdrop(Paths.image('checkerboard'), XY, 0, 0);
		checkerPattern.antialiasing = VsliceOptions.ANTIALIASING;
		checkerPattern.scrollFactor.set(1.5, 1.5);
		checkerPattern.alpha = 0.65;
		add(checkerPattern);

		// --- QUADRATO NERO DI SFONDO (FISSO) ---
		var panelX = ((FlxG.width * 0.35) - 200) + 400;
		var panelY = 0 - 400;
		var panelHeight = FlxG.height + 2000;
		
		rightPanel = new FlxSprite(panelX, panelY).makeGraphic(Std.int(FlxG.width - panelX), Std.int(panelHeight), FlxColor.BLACK);
		rightPanel.scrollFactor.set(0, 0);
		rightPanel.alpha = 0.5; // Trasparenza al 50%
		add(rightPanel);

		// --- LOGO FNF PERFETTAMENTE CENTRATO ---
		var logoBaseX = ((FlxG.width * 0.52) - 450) + 40;
		var logoBaseY = (((25 - 500) + 200) + 75) - 30;
		
		baseLogoY = (logoBaseY + 350) + 10;
		logoBl = new FlxSprite((logoBaseX + 200) + 150 + 40, baseLogoY);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = VsliceOptions.ANTIALIASING;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, true);
		logoBl.animation.play('bump');
		logoBl.scrollFactor.set(0, 0);
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.68));
		logoBl.updateHitbox();
		add(logoBl);

		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, "Psych Engine " + psychEngineVersion, 12);
		var fnfVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, 'v${funkinVersion} (P-slice ${pSliceVersion})', 12);

		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		psychVer.scrollFactor.set();
		fnfVer.scrollFactor.set();
		add(psychVer);
		add(fnfVer);

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			MainMenuHooks.unlockFriday();

		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		super.create();
		#if TOUCH_CONTROLS_ALLOWED
		if (controls.mobileC)
			new mobile.states.MobileMenuState(this);
		else
		#end
		new DesktopMenuState(this);
	}

	function goToOptions()
	{
		MusicBeatState.switchState(new OptionsState());
		#if !LEGACY_PSYCH OptionsState.onPlayState = false; #end
		if (PlayState.SONG != null)
		{
			PlayState.SONG.arrowSkin = null;
			PlayState.SONG.splashSkin = null;
			#if !LEGACY_PSYCH PlayState.stageUI = 'normal'; #end
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (checkerPattern != null)
		{
			checkerPattern.x -= 20 * elapsed;
			checkerPattern.y -= 20 * elapsed;
		}

		// Effetto floating (ondeggiamento fluido del logo) calcolato tramite seno senza errori di tween
		if (logoBl != null)
		{
			logoTimer += elapsed;
			logoBl.y = baseLogoY + Math.sin(logoTimer * 3) * 10;
		}

		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();
		if (logoBl != null && curBeat % 2 == 0)
		{
			FlxTween.cancelTweensOf(logoBl.scale);
			logoBl.scale.set(0.70, 0.70);
			FlxTween.tween(logoBl.scale, {x: 0.68, y: 0.68}, 0.2, {ease: FlxEase.cubeOut});
		}
	}
}
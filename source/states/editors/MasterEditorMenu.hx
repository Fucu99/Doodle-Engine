package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import mikolka.vslice.ui.obj.ModSelector;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.editors.CharSelectEditor;
import mikolka.editors.StickerTest;
import mikolka.compatibility.VsliceOptions;
import backend.WeekData;
import mikolka.vslice.results.ResultState;
import objects.Character;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'Stage Editor',
		'Week Editor',
		'Test stickers',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Player editor',
		#if PROFILE_BUILD
		'Crash the game',
		'Usermess the game',
		#end
		'Note Splash Editor',
		'Result Preview Menu',
		'Code Editor',
		'Logic Editor'
	];

	private var modDir:ModSelector;

	var wallpaper:FlxSprite;
	var topTaskbar:FlxSprite;
	var desktopHeader:FlxText;
	var clockText:FlxText;
	var sessionSeconds:Float = 0;

	// Desktop icons + drag state
	var iconSprites:Array<FlxSprite> = [];
	var iconLabels:Array<FlxText> = [];
	var iconAngles:Array<Float> = [];
	var draggingIconIndex:Int = -1;
	var iconDragStartMouseX:Float = 0;
	var iconDragStartMouseY:Float = 0;
	var iconOffsetX:Float = 0;
	var iconOffsetY:Float = 0;
	var iconMovedDistance:Float = 0;

	// Detached system/desktop icons
	var fileExplorerSpr:FlxSprite;
	var fileExplorerLbl:FlxText;
	var desktopSettingsSpr:FlxSprite;
	var desktopSettingsLbl:FlxText;

	// Desktop customization settings
	var allowIconDrag:Bool = true;
	var currentIconSize:Int = 48;
	var desktopZoomLevel:Float = 1.0;
	var showIconLabels:Bool = true;
	var allowIconTilt:Bool = true;
	var showDoodlyWindow:Bool = true;
	var wallpaperTintIndex:Int = 0;
	var wallpaperTints:Array<Int> = [0xFF2B3A42, 0xFF243447, 0xFF33293E, 0xFF233B34, 0xFF3A3126];

	// Desktop Settings window
	var settingsOpen:Bool = false;
	var settingsGroup:FlxTypedGroup<FlxSprite>;
	var settingsTexts:FlxTypedGroup<FlxText>;
	var settingsButtons:FlxTypedGroup<FlxButton>;
	var settingsHeader:FlxSprite;
	var isDraggingSettingsWin:Bool = false;
	var settingsLastMouseX:Float = 0;
	var settingsLastMouseY:Float = 0;

	var btnDragToggle:FlxButton;
	var btnLabelsToggle:FlxButton;
	var btnTiltToggle:FlxButton;
	var btnTintCycle:FlxButton;
	var btnDoodlyWinToggle:FlxButton;

	// Fake Windows Start button with HaxeFlixel logo
	var bottomBar:FlxSprite;
	var startBtnBg:FlxSprite;
	var startBtnLogo:FlxSprite;
	var startBtnText:FlxText;
	var startPopupBg:FlxSprite;
	var startPopupText:FlxText;
	var startMenuOpen:Bool = false;

	// File Explorer window
	var explorerOpen:Bool = false;
	var explorerGroup:FlxTypedGroup<FlxSprite>;
	var explorerTexts:FlxTypedGroup<FlxText>;
	var explorerButtons:FlxTypedGroup<FlxButton>;
	var explorerHeader:FlxSprite;
	var isDraggingExplorerWin:Bool = false;
	var explorerLastMouseX:Float = 0;
	var explorerLastMouseY:Float = 0;
	var explorerPreview:FlxSprite;
	var randomImageKeys:Array<String> = [];
	var candidateImages:Array<String> = [
		'menuDesat',
		'menuBG',
		'menuBGBlue',
		'menuBGMagenta',
		'storyMenuBg',
		'mainmenu/menu_freeplay',
		'mainmenu/menu_story_mode',
		'mainmenu/menu_options',
		'mainmenu/menu_credits'
	];

	// Open Doodly window on the desktop
	var doodlyWindowBg:FlxSprite;
	var doodlyWindowHeader:FlxSprite;
	var doodlyWindowTitle:FlxText;
	var isDraggingDoodlyWindow:Bool = false;
	var winLastMouseX:Float = 0;
	var winLastMouseY:Float = 0;

	var doodly:FlxSprite;
	var doodlyBubble:FlxSprite;
	var doodlyText:FlxText;
	var doodlyTalkTimer:Float = 0;

	var doodlyMoveMode:Bool = false;
	var isDraggingDoodly:Bool = false;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;

	var doodlyResizeMode:Bool = false;
	var isResizingDoodly:Bool = false;
	var resizeStartMouseX:Float = 0;
	var resizeStartMouseY:Float = 0;
	var resizeStartWidth:Float = 96;
	var resizeStartHeight:Float = 100;

	var btnDoodlyHelp:FlxButton;
	var btnDoodlyJoke:FlxButton;
	var btnDoodlyMove:FlxButton;
	var btnDoodlyResize:FlxButton;

	var doodlyHelpPages:Array<String> = [];
	var doodlyHelpPageIndex:Int = 0;
	var doodlyInHelpMode:Bool = false;
	var btnHelpPrev:FlxButton;
	var btnHelpNext:FlxButton;

	var doodlyJokes:Array<String> = [
		"Why did the editor shortcut run away? It didn't want to be clicked!",
		"A tidy-ish chaotic desktop is peak Doodle Engine energy.",
		"Click any icon to launch that editor straight away!",
		"Try clicking the HaxeFlixel Start button in the bottom-left corner!",
		"Doodly's tip: don't press 7 by accident during a tough song!",
		"Everything is in English here because Doodly thinks it sounds cooler.",
		"Moving or resizing me won't fix your chart's BPM, sorry!",
		"Desktop Settings lets you tweak icon sizes, zoom, windows, and more."
	];

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		FlxG.camera.zoom = desktopZoomLevel;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		wallpaper = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		wallpaper.scrollFactor.set();
		wallpaper.setGraphicSize(Std.int(wallpaper.width * 1.175));
		wallpaper.screenCenter();
		wallpaper.color = wallpaperTints[wallpaperTintIndex];
		add(wallpaper);

		topTaskbar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 34, 0xFF1B2228);
		add(topTaskbar);

		desktopHeader = new FlxText(12, 7, FlxG.width - 220, "DOODLE_OS // EDITOR_DESKTOP.EXE  [ESC: Back]", 15);
		desktopHeader.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT);
		add(desktopHeader);

		clockText = new FlxText(FlxG.width - 190, 7, 178, "UPTIME 00:00", 14);
		clockText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF90CAF9, RIGHT);
		add(clockText);

		buildDesktopIcons();
		buildDetachedSystemIcons();
		buildDoodlyDesktopWindow();
		buildFakeFileExplorer();
		buildDesktopSettingsWindow();
		buildFakeStartButton();

		#if MODS_ALLOWED
		modDir = new ModSelector(null);
		modDir.allowInput = true;
		add(modDir);
		if (controls.mobileC)
		{
			var btn_sharedY = (FlxG.height - 90);
			var prevBtn = new PsychUIButton(40, btn_sharedY, "<=", () -> modDir.changeDirectory(-1), 140, 50);
			prevBtn.text.size = 30;
			prevBtn.text.y -= 10;
			prevBtn.normalStyle.bgColor = 0xFF888888;
			var nextBtn = new PsychUIButton(((FlxG.width - 40) - 140), btn_sharedY, "=>", () -> modDir.changeDirectory(1), 140, 50);
			nextBtn.text.size = 30;
			nextBtn.text.y -= 10;
			nextBtn.normalStyle.bgColor = 0xFF888888;
			add(prevBtn);
			add(nextBtn);
		}
		#end

		FlxG.mouse.visible = true;

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'B_TOP');
		#end
		super.create();
	}

	function pointInRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool
	{
		return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
	}

	function optionToIconFilename(optionName:String):String
	{
		var clean = optionName.toLowerCase().split(" ").join("_");
		return "editors_icons/" + clean;
	}

	function applyIconGraphic(spr:FlxSprite, optionName:String)
	{
		var customPath = optionToIconFilename(optionName);
		var realImg = Paths.image(customPath);
		if (realImg != null)
		{
			spr.loadGraphic(realImg);
		}
		else
		{
			spr.loadGraphic(createDetailedPixelIcon(optionName));
		}
		spr.setGraphicSize(currentIconSize, currentIconSize);
		spr.updateHitbox();
	}

	function createDetailedPixelIcon(optionName:String):BitmapData
	{
		var w:Int = 48;
		var h:Int = 48;
		var bd = new BitmapData(w, h, true, 0x00000000);

		switch (optionName)
		{
			case 'Chart Editor':
				bd.fillRect(new Rectangle(8, 4, 28, 38), 0xFFECEFF1);
				bd.fillRect(new Rectangle(30, 4, 6, 6), 0xFFB0BEC5);
				bd.fillRect(new Rectangle(12, 14, 6, 6), 0xFFC24B99);
				bd.fillRect(new Rectangle(20, 18, 6, 6), 0xFF00FFFF);
				bd.fillRect(new Rectangle(12, 26, 6, 6), 0xFF12FA05);
				bd.fillRect(new Rectangle(24, 30, 6, 6), 0xFFF9393F);

			case 'Character Editor':
				bd.fillRect(new Rectangle(14, 8, 18, 7), 0xFFE53935);
				bd.fillRect(new Rectangle(24, 12, 14, 4), 0xFF1E88E5);
				bd.fillRect(new Rectangle(12, 15, 22, 6), 0xFF00E5FF);
				bd.fillRect(new Rectangle(15, 20, 16, 13), 0xFFFFCCBC);
				bd.fillRect(new Rectangle(18, 23, 3, 4), 0xFF212121);
				bd.fillRect(new Rectangle(25, 23, 3, 4), 0xFF212121);
				bd.fillRect(new Rectangle(14, 33, 18, 10), 0xFFFFFFFF);

			case 'Stage Editor':
				bd.fillRect(new Rectangle(6, 8, 36, 26), 0xFF1A237E);
				bd.fillRect(new Rectangle(6, 8, 7, 26), 0xFFC62828);
				bd.fillRect(new Rectangle(35, 8, 7, 26), 0xFFC62828);
				bd.fillRect(new Rectangle(17, 10, 4, 4), 0xFFFFEE58);
				bd.fillRect(new Rectangle(27, 10, 4, 4), 0xFFFFEE58);
				bd.fillRect(new Rectangle(4, 34, 40, 8), 0xFF6D4C41);

			case 'Week Editor':
				bd.fillRect(new Rectangle(6, 10, 15, 5), 0xFFFBC02D);
				bd.fillRect(new Rectangle(6, 14, 36, 24), 0xFFFFD54F);
				bd.fillRect(new Rectangle(6, 14, 36, 3), 0xFFFFF59D);
				bd.fillRect(new Rectangle(12, 22, 24, 3), 0xFF795548);
				bd.fillRect(new Rectangle(12, 28, 16, 3), 0xFF795548);

			case 'Test stickers':
				bd.fillRect(new Rectangle(10, 8, 28, 32), 0xFFFFFFFF);
				bd.fillRect(new Rectangle(12, 10, 24, 28), 0xFFFF4081);
				bd.fillRect(new Rectangle(18, 16, 12, 12), 0xFFFFEB3B);
				bd.fillRect(new Rectangle(30, 32, 8, 8), 0xFFE0E0E0);

			case 'Menu Character Editor':
				bd.fillRect(new Rectangle(8, 6, 32, 36), 0xFFFFB300);
				bd.fillRect(new Rectangle(12, 10, 24, 28), 0xFF263238);
				bd.fillRect(new Rectangle(19, 14, 10, 10), 0xFFFFCC80);
				bd.fillRect(new Rectangle(15, 25, 18, 11), 0xFF7E57C2);

			case 'Dialogue Editor':
				bd.fillRect(new Rectangle(6, 8, 36, 24), 0xFFFFFFFF);
				bd.fillRect(new Rectangle(14, 32, 8, 4), 0xFFFFFFFF);
				bd.fillRect(new Rectangle(12, 36, 5, 4), 0xFFFFFFFF);
				bd.fillRect(new Rectangle(11, 14, 26, 3), 0xFF263238);
				bd.fillRect(new Rectangle(11, 20, 20, 3), 0xFF263238);
				bd.fillRect(new Rectangle(11, 26, 14, 3), 0xFF263238);

			case 'Dialogue Portrait Editor':
				bd.fillRect(new Rectangle(8, 8, 32, 32), 0xFF00897B);
				bd.fillRect(new Rectangle(11, 11, 26, 22), 0xFFE0F7FA);
				bd.fillRect(new Rectangle(19, 14, 10, 9), 0xFFFFAB91);
				bd.fillRect(new Rectangle(15, 24, 18, 9), 0xFF00695C);

			case 'Player editor':
				bd.fillRect(new Rectangle(6, 16, 36, 18), 0xFF37474F);
				bd.fillRect(new Rectangle(6, 28, 10, 10), 0xFF37474F);
				bd.fillRect(new Rectangle(32, 28, 10, 10), 0xFF37474F);
				bd.fillRect(new Rectangle(12, 20, 3, 9), 0xFFECEFF1);
				bd.fillRect(new Rectangle(9, 23, 9, 3), 0xFFECEFF1);
				bd.fillRect(new Rectangle(31, 20, 4, 4), 0xFFFF5252);
				bd.fillRect(new Rectangle(35, 24, 4, 4), 0xFF69F0AE);

			case 'Note Splash Editor':
				bd.fillRect(new Rectangle(22, 6, 4, 36), 0xFF00E5FF);
				bd.fillRect(new Rectangle(6, 22, 36, 4), 0xFF00E5FF);
				bd.fillRect(new Rectangle(12, 12, 6, 6), 0xFFFF4081);
				bd.fillRect(new Rectangle(30, 12, 6, 6), 0xFFFFEA00);
				bd.fillRect(new Rectangle(12, 30, 6, 6), 0xFF69F0AE);
				bd.fillRect(new Rectangle(30, 30, 6, 6), 0xFF7C4DFF);

			case 'Result Preview Menu':
				bd.fillRect(new Rectangle(13, 8, 22, 16), 0xFFFFD54F);
				bd.fillRect(new Rectangle(9, 10, 4, 9), 0xFFFFCA28);
				bd.fillRect(new Rectangle(35, 10, 4, 9), 0xFFFFCA28);
				bd.fillRect(new Rectangle(21, 24, 6, 9), 0xFFFFB300);
				bd.fillRect(new Rectangle(14, 33, 20, 6), 0xFF8D6E63);

			case 'Code Editor':
				bd.fillRect(new Rectangle(6, 8, 36, 32), 0xFF1E1E1E);
				bd.fillRect(new Rectangle(6, 8, 36, 6), 0xFF007ACC);
				bd.fillRect(new Rectangle(11, 19, 10, 3), 0xFF4FC3F7);
				bd.fillRect(new Rectangle(15, 25, 18, 3), 0xFFA5D6A7);
				bd.fillRect(new Rectangle(11, 31, 14, 3), 0xFFFFCC80);

			case 'Logic Editor':
				bd.fillRect(new Rectangle(5, 10, 18, 12), 0xFFFFAB19);
				bd.fillRect(new Rectangle(23, 14, 4, 4), 0xFFE74C3C);
				bd.fillRect(new Rectangle(21, 26, 4, 4), 0xFF2ECC71);
				bd.fillRect(new Rectangle(25, 22, 18, 12), 0xFF4C97FF);
				bd.fillRect(new Rectangle(24, 16, 2, 12), 0xFF66FCF1);

			case 'File Explorer':
				bd.fillRect(new Rectangle(6, 10, 16, 5), 0xFFFBC02D);
				bd.fillRect(new Rectangle(6, 14, 36, 25), 0xFFFFD54F);
				bd.fillRect(new Rectangle(6, 14, 36, 3), 0xFFFFF59D);
				bd.fillRect(new Rectangle(6, 36, 36, 3), 0xFFF57F17);

			case 'Desktop Settings':
				bd.fillRect(new Rectangle(12, 12, 24, 24), 0xFF78909C);
				bd.fillRect(new Rectangle(20, 6, 8, 6), 0xFFB0BEC5);
				bd.fillRect(new Rectangle(20, 36, 8, 6), 0xFFB0BEC5);
				bd.fillRect(new Rectangle(6, 20, 6, 8), 0xFFB0BEC5);
				bd.fillRect(new Rectangle(36, 20, 6, 8), 0xFFB0BEC5);
				bd.fillRect(new Rectangle(18, 18, 12, 12), 0xFF263238);

			default:
				bd.fillRect(new Rectangle(8, 8, 32, 32), 0xFFCFD8DC);
				bd.fillRect(new Rectangle(8, 8, 32, 7), 0xFF1976D2);
				bd.fillRect(new Rectangle(18, 20, 12, 12), 0xFF546E7A);
		}

		return bd;
	}

	function buildDesktopIcons()
	{
		var cols:Int = 4;
		var cellW:Float = 126.0;
		var cellH:Float = 96.0;
		var originX:Float = 24.0;
		var originY:Float = 48.0;

		for (i in 0...options.length)
		{
			var optName = options[i];
			var colIdx:Int = i % cols;
			var rowIdx:Int = Std.int(i / cols);

			var baseX:Float = originX + colIdx * cellW;
			var baseY:Float = originY + rowIdx * cellH;
			var slightX:Float = FlxG.random.float(-2.5, 2.5);
			var slightY:Float = FlxG.random.float(-2.0, 2.0);

			var ix:Float = Math.max(16.0, Math.min(FlxG.width - 495.0, baseX + slightX));
			var iy:Float = Math.max(44.0, Math.min(FlxG.height - 165.0, baseY + slightY));

			var ang:Float = FlxG.random.float(-2.0, 2.0);
			iconAngles.push(ang);

			var iconSpr = new FlxSprite(ix, iy);
			applyIconGraphic(iconSpr, optName);
			iconSpr.angle = allowIconTilt ? ang : 0;
			add(iconSpr);
			iconSprites.push(iconSpr);

			var lbl = new FlxText(ix - 30, iy + iconSpr.height + 4, 108, optName, 11);
			lbl.setFormat(Paths.font("vcr.ttf"), 11, FlxColor.WHITE, CENTER);
			lbl.visible = showIconLabels;
			add(lbl);
			iconLabels.push(lbl);
		}
	}

	function buildDetachedSystemIcons()
	{
		var feX:Float = 24.0;
		var feY:Float = FlxG.height - 134.0;

		fileExplorerSpr = new FlxSprite(feX, feY);
		applyIconGraphic(fileExplorerSpr, 'File Explorer');
		add(fileExplorerSpr);

		fileExplorerLbl = new FlxText(feX - 30, feY + fileExplorerSpr.height + 4, 110, "File Explorer", 11);
		fileExplorerLbl.setFormat(Paths.font("vcr.ttf"), 11, FlxColor.WHITE, CENTER);
		fileExplorerLbl.visible = showIconLabels;
		add(fileExplorerLbl);

		var dsX:Float = 150.0;
		var dsY:Float = FlxG.height - 134.0;

		desktopSettingsSpr = new FlxSprite(dsX, dsY);
		applyIconGraphic(desktopSettingsSpr, 'Desktop Settings');
		add(desktopSettingsSpr);

		desktopSettingsLbl = new FlxText(dsX - 34, dsY + desktopSettingsSpr.height + 4, 118, "Desktop Settings", 11);
		desktopSettingsLbl.setFormat(Paths.font("vcr.ttf"), 11, 0xFF90CAF9, CENTER);
		desktopSettingsLbl.visible = showIconLabels;
		add(desktopSettingsLbl);
	}

	function setDoodlyWindowVisible(vis:Bool)
	{
		showDoodlyWindow = vis;
		doodlyWindowBg.visible = vis;
		doodlyWindowHeader.visible = vis;
		doodlyWindowTitle.visible = vis;
		doodly.visible = vis;
		doodlyBubble.visible = vis;
		doodlyText.visible = vis;
		btnDoodlyHelp.visible = vis;
		btnDoodlyJoke.visible = vis;
		btnDoodlyMove.visible = vis;
		btnDoodlyResize.visible = vis;
		btnHelpPrev.visible = vis && doodlyInHelpMode;
		btnHelpNext.visible = vis && doodlyInHelpMode;
	}

	function applyDesktopAppearanceChanges()
	{
		for (i in 0...iconSprites.length)
		{
			var spr = iconSprites[i];
			spr.setGraphicSize(currentIconSize, currentIconSize);
			spr.updateHitbox();
			spr.angle = allowIconTilt ? iconAngles[i] : 0;

			var lbl = iconLabels[i];
			lbl.visible = showIconLabels;
			lbl.setPosition(spr.x - 30, spr.y + spr.height + 4);
		}

		fileExplorerSpr.setGraphicSize(currentIconSize, currentIconSize);
		fileExplorerSpr.updateHitbox();
		fileExplorerLbl.visible = showIconLabels;
		fileExplorerLbl.setPosition(fileExplorerSpr.x - 30, fileExplorerSpr.y + fileExplorerSpr.height + 4);

		desktopSettingsSpr.setGraphicSize(currentIconSize, currentIconSize);
		desktopSettingsSpr.updateHitbox();
		desktopSettingsLbl.visible = showIconLabels;
		desktopSettingsLbl.setPosition(desktopSettingsSpr.x - 34, desktopSettingsSpr.y + desktopSettingsSpr.height + 4);

		FlxG.camera.zoom = desktopZoomLevel;
		wallpaper.color = wallpaperTints[wallpaperTintIndex];

		setDoodlyWindowVisible(showDoodlyWindow);
		refreshSettingsButtonLabels();
	}

	function resetDesktopLayout()
	{
		var cols:Int = 4;
		var cellW:Float = 126.0;
		var cellH:Float = 96.0;
		var originX:Float = 24.0;
		var originY:Float = 48.0;

		for (i in 0...iconSprites.length)
		{
			var colIdx:Int = i % cols;
			var rowIdx:Int = Std.int(i / cols);
			iconSprites[i].setPosition(originX + colIdx * cellW, originY + rowIdx * cellH);
		}

		fileExplorerSpr.setPosition(24.0, FlxG.height - 134.0);
		desktopSettingsSpr.setPosition(150.0, FlxG.height - 134.0);

		var winX:Float = FlxG.width - 430;
		var winY:Float = 54;
		moveDoodlyWindowBy(winX - doodlyWindowBg.x, winY - doodlyWindowBg.y);

		currentIconSize = 48;
		desktopZoomLevel = 1.0;
		allowIconDrag = true;
		showIconLabels = true;
		allowIconTilt = true;
		showDoodlyWindow = true;
		wallpaperTintIndex = 0;
		applyDesktopAppearanceChanges();
	}

	function syncIconLabel(index:Int)
	{
		if (index < 0 || index >= iconSprites.length || index >= iconLabels.length) return;
		var spr = iconSprites[index];
		var lbl = iconLabels[index];
		spr.x = Math.max(8, Math.min(FlxG.width - spr.width - 8, spr.x));
		spr.y = Math.max(38, Math.min(FlxG.height - 105, spr.y));
		lbl.setPosition(spr.x - 30, spr.y + spr.height + 4);
		lbl.visible = showIconLabels;
	}

	function syncDetachedIconLabel(spr:FlxSprite, lbl:FlxText, offsetX:Float = -30)
	{
		spr.x = Math.max(8, Math.min(FlxG.width - spr.width - 8, spr.x));
		spr.y = Math.max(38, Math.min(FlxG.height - 105, spr.y));
		lbl.setPosition(spr.x + offsetX, spr.y + spr.height + 4);
		lbl.visible = showIconLabels;
	}

	function buildDesktopSettingsWindow()
	{
		settingsGroup = new FlxTypedGroup<FlxSprite>();
		settingsTexts = new FlxTypedGroup<FlxText>();
		settingsButtons = new FlxTypedGroup<FlxButton>();
		add(settingsGroup);
		add(settingsTexts);
		add(settingsButtons);

		var winX:Float = 170;
		var winY:Float = 72;
		var winW:Int = 440;
		var winH:Int = 340;

		var frame = new FlxSprite(winX, winY).makeGraphic(winW, winH, 0xFF1E232B);
		settingsHeader = new FlxSprite(winX, winY).makeGraphic(winW, 28, 0xFF2E3B4E);
		settingsGroup.add(frame);
		settingsGroup.add(settingsHeader);

		var title = new FlxText(winX + 10, winY + 6, winW - 20, "DESKTOP_SETTINGS.EXE", 13);
		title.setFormat(Paths.font("vcr.ttf"), 13, FlxColor.WHITE, LEFT);
		settingsTexts.add(title);

		var col1X:Float = winX + 16;
		var col2X:Float = winX + 224;
		var row1Y:Float = winY + 42;
		var row2Y:Float = winY + 84;
		var row3Y:Float = winY + 126;
		var row4Y:Float = winY + 168;
		var row5Y:Float = winY + 210;
		var row6Y:Float = winY + 252;
		var row7Y:Float = winY + 294;

		btnDragToggle = new FlxButton(col1X, row1Y, "", () -> {
			allowIconDrag = !allowIconDrag;
			refreshSettingsButtonLabels();
		});
		var btnIconPlus = new FlxButton(col2X, row1Y, "Icon Size +", () -> {
			currentIconSize = Std.int(Math.min(84, currentIconSize + 6));
			applyDesktopAppearanceChanges();
		});

		var btnIconMinus = new FlxButton(col1X, row2Y, "Icon Size -", () -> {
			currentIconSize = Std.int(Math.max(28, currentIconSize - 6));
			applyDesktopAppearanceChanges();
		});
		var btnZoomPlus = new FlxButton(col2X, row2Y, "Zoom +", () -> {
			desktopZoomLevel = Math.min(1.25, Math.round((desktopZoomLevel + 0.05) * 100) / 100);
			applyDesktopAppearanceChanges();
		});

		var btnZoomMinus = new FlxButton(col1X, row3Y, "Zoom -", () -> {
			desktopZoomLevel = Math.max(0.8, Math.round((desktopZoomLevel - 0.05) * 100) / 100);
			applyDesktopAppearanceChanges();
		});
		var btnZoomReset = new FlxButton(col2X, row3Y, "Reset Zoom", () -> {
			desktopZoomLevel = 1.0;
			applyDesktopAppearanceChanges();
		});

		btnLabelsToggle = new FlxButton(col1X, row4Y, "", () -> {
			showIconLabels = !showIconLabels;
			applyDesktopAppearanceChanges();
		});
		btnTiltToggle = new FlxButton(col2X, row4Y, "", () -> {
			allowIconTilt = !allowIconTilt;
			applyDesktopAppearanceChanges();
		});

		btnDoodlyWinToggle = new FlxButton(col1X, row5Y, "", () -> {
			showDoodlyWindow = !showDoodlyWindow;
			applyDesktopAppearanceChanges();
		});
		btnTintCycle = new FlxButton(col2X, row5Y, "", () -> {
			wallpaperTintIndex = (wallpaperTintIndex + 1) % wallpaperTints.length;
			applyDesktopAppearanceChanges();
		});

		var btnResetLayout = new FlxButton(col1X, row6Y, "Reset Layout", resetDesktopLayout);
		var btnCloseSettings = new FlxButton(col2X, row6Y, "Close", () -> setSettingsVisible(false));

		var infoLbl = new FlxText(col1X, row7Y + 6, winW - 32, 'Icon Size: ${currentIconSize}px | Zoom: ${desktopZoomLevel}x', 12);
		infoLbl.setFormat(Paths.font("vcr.ttf"), 12, 0xFFB0BEC5, LEFT);
		settingsTexts.add(infoLbl);

		for (b in [
			btnDragToggle, btnIconPlus, btnIconMinus, btnZoomPlus, btnZoomMinus, btnZoomReset,
			btnLabelsToggle, btnTiltToggle, btnDoodlyWinToggle, btnTintCycle, btnResetLayout, btnCloseSettings
		])
		{
			b.label.fieldWidth = 176;
			b.label.wordWrap = false;
			settingsButtons.add(b);
		}

		refreshSettingsButtonLabels();
		setSettingsVisible(false);
	}

	function refreshSettingsButtonLabels()
	{
		if (btnDragToggle != null)
			btnDragToggle.label.text = allowIconDrag ? "Move Icons: ON" : "Move Icons: OFF";
		if (btnLabelsToggle != null)
			btnLabelsToggle.label.text = showIconLabels ? "Labels: ON" : "Labels: OFF";
		if (btnTiltToggle != null)
			btnTiltToggle.label.text = allowIconTilt ? "Icon Tilt: ON" : "Icon Tilt: OFF";
		if (btnDoodlyWinToggle != null)
			btnDoodlyWinToggle.label.text = showDoodlyWindow ? "Doodly Win: ON" : "Doodly Win: OFF";
		if (btnTintCycle != null)
			btnTintCycle.label.text = 'BG Tint #${wallpaperTintIndex + 1}';
		if (settingsTexts != null && settingsTexts.length > 1)
			settingsTexts.members[1].text = 'Icon Size: ${currentIconSize}px | Zoom: ${desktopZoomLevel}x';
	}

	function moveSettingsWindowBy(dx:Float, dy:Float)
	{
		if (settingsGroup == null || settingsGroup.length == 0) return;
		var frame = settingsGroup.members[0];
		if (frame == null) return;

		var newX = Math.max(8, Math.min(FlxG.width - frame.width - 8, frame.x + dx));
		var newY = Math.max(38, Math.min(FlxG.height - frame.height - 42, frame.y + dy));
		var actualDx = newX - frame.x;
		var actualDy = newY - frame.y;

		for (s in settingsGroup.members)
		{
			if (s != null)
			{
				s.x += actualDx;
				s.y += actualDy;
			}
		}
		for (t in settingsTexts.members)
		{
			if (t != null)
			{
				t.x += actualDx;
				t.y += actualDy;
			}
		}
		for (b in settingsButtons.members)
		{
			if (b != null)
			{
				b.x += actualDx;
				b.y += actualDy;
			}
		}
	}

	function setSettingsVisible(vis:Bool)
	{
		settingsOpen = vis;
		for (s in settingsGroup.members)
			if (s != null) s.visible = vis;
		for (t in settingsTexts.members)
			if (t != null) t.visible = vis;
		for (b in settingsButtons.members)
			if (b != null) b.visible = vis;
	}

	function toggleDesktopSettings()
	{
		if (explorerOpen) setExplorerVisible(false);
		setSettingsVisible(!settingsOpen);
	}

	function buildFakeStartButton()
	{
		var barH:Int = 36;
		var barY:Float = FlxG.height - barH;

		bottomBar = new FlxSprite(0, barY).makeGraphic(FlxG.width, barH, 0xFF181D24);
		add(bottomBar);

		startBtnBg = new FlxSprite(6, barY + 4).makeGraphic(124, 28, 0xFF2B3440);
		add(startBtnBg);

		startBtnLogo = new FlxSprite(12, barY + 8);
		startBtnLogo.makeGraphic(20, 20, FlxColor.TRANSPARENT, true);
		var px = startBtnLogo.pixels;
		px.fillRect(new Rectangle(0, 0, 10, 10), 0xFFF58220);
		px.fillRect(new Rectangle(10, 0, 10, 10), 0xFF54B948);
		px.fillRect(new Rectangle(0, 10, 10, 10), 0xFF2E6BB3);
		px.fillRect(new Rectangle(10, 10, 10, 10), 0xFFFFCA28);
		add(startBtnLogo);

		startBtnText = new FlxText(38, barY + 10, 86, "Start", 14);
		startBtnText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(startBtnText);

		startPopupBg = new FlxSprite(6, barY - 94).makeGraphic(260, 88, 0xFF222933);
		startPopupBg.visible = false;
		add(startPopupBg);

		startPopupText = new FlxText(14, barY - 86, 244, "HaxeFlixel Start Menu\n- Editors & tools ready\n- Customize via Desktop Settings", 12);
		startPopupText.setFormat(Paths.font("vcr.ttf"), 12, 0xFFE3F2FD, LEFT);
		startPopupText.visible = false;
		add(startPopupText);
	}

	function toggleStartPopup()
	{
		startMenuOpen = !startMenuOpen;
		startPopupBg.visible = startMenuOpen;
		startPopupText.visible = startMenuOpen;
		if (startMenuOpen && showDoodlyWindow)
		{
			playDoodlyAnim('talk1', 2.0);
			doodlyText.text = "HaxeFlixel Start button clicked! Everything is running smoothly.";
		}
	}

	function buildDoodlyDesktopWindow()
	{
		var winX:Float = FlxG.width - 430;
		var winY:Float = 54;
		var winW:Int = 412;
		var winH:Int = 440;

		doodlyWindowBg = new FlxSprite(winX, winY).makeGraphic(winW, winH, 0xFF232931);
		add(doodlyWindowBg);

		doodlyWindowHeader = new FlxSprite(winX, winY).makeGraphic(winW, 28, 0xFF3A4654);
		add(doodlyWindowHeader);

		doodlyWindowTitle = new FlxText(winX + 10, winY + 6, winW - 20, "DOODLY_DESKTOP_HELPER.EXE", 13);
		doodlyWindowTitle.setFormat(Paths.font("vcr.ttf"), 13, FlxColor.WHITE, LEFT);
		add(doodlyWindowTitle);

		doodly = new FlxSprite(winX + winW - 122, winY + winH - 122);
		var atlas:FlxAtlasFrames = Paths.getSparrowAtlas('doodlyspritesheet');
		if (atlas != null)
		{
			doodly.frames = atlas;
			doodly.animation.addByPrefix('idle', 'doodlyidle', 6, true);
			doodly.animation.addByPrefix('talk1', 'doodlytalkcalm', 8, true);
			doodly.animation.addByPrefix('talk2', 'doodlytalkcalmsecondanimation', 8, true);
			doodly.animation.play('idle');
		}
		else
		{
			doodly.makeGraphic(96, 100, FlxColor.WHITE);
		}
		doodly.setGraphicSize(96, 100);
		doodly.updateHitbox();
		add(doodly);

		doodlyBubble = new FlxSprite(winX + 16, winY + 42).makeGraphic(378, 166, 0xFFFFFBE6);
		add(doodlyBubble);

		doodlyText = new FlxText(winX + 24, winY + 50, 362, "Hey! Welcome to the Editor Desktop! Click Help, Joke, Move, or Resize.", 13);
		doodlyText.setFormat(Paths.font("vcr.ttf"), 13, 0xFF1A1A1A, LEFT);
		add(doodlyText);

		var btnY:Float = winY + 216;
		btnDoodlyHelp = new FlxButton(winX + 16, btnY, "Help", onDoodlyHelp);
		btnDoodlyJoke = new FlxButton(winX + 102, btnY, "Joke", onDoodlyJoke);
		btnDoodlyMove = new FlxButton(winX + 188, btnY, "Move", onDoodlyMoveToggle);
		btnDoodlyResize = new FlxButton(winX + 274, btnY, "Resize", onDoodlyResizeToggle);

		btnHelpPrev = new FlxButton(winX + 16, btnY + 26, "< Prev", onHelpPrevPage);
		btnHelpNext = new FlxButton(winX + 102, btnY + 26, "Next >", onHelpNextPage);
		btnHelpPrev.visible = false;
		btnHelpNext.visible = false;

		for (b in [btnDoodlyHelp, btnDoodlyJoke, btnDoodlyMove, btnDoodlyResize, btnHelpPrev, btnHelpNext])
		{
			add(b);
		}

		buildDesktopHelpPages();
	}

	function moveDoodlyWindowBy(dx:Float, dy:Float)
	{
		if (doodlyWindowBg == null) return;
		var newX = Math.max(8, Math.min(FlxG.width - doodlyWindowBg.width - 8, doodlyWindowBg.x + dx));
		var newY = Math.max(38, Math.min(FlxG.height - doodlyWindowBg.height - 42, doodlyWindowBg.y + dy));
		var actualDx = newX - doodlyWindowBg.x;
		var actualDy = newY - doodlyWindowBg.y;

		doodlyWindowBg.x += actualDx;
		doodlyWindowBg.y += actualDy;
		doodlyWindowHeader.x += actualDx;
		doodlyWindowHeader.y += actualDy;
		doodlyWindowTitle.x += actualDx;
		doodlyWindowTitle.y += actualDy;

		doodlyBubble.x += actualDx;
		doodlyBubble.y += actualDy;
		doodlyText.x += actualDx;
		doodlyText.y += actualDy;

		doodly.x += actualDx;
		doodly.y += actualDy;

		for (b in [btnDoodlyHelp, btnDoodlyJoke, btnDoodlyMove, btnDoodlyResize, btnHelpPrev, btnHelpNext])
		{
			b.x += actualDx;
			b.y += actualDy;
		}
	}

	function buildDesktopHelpPages()
	{
		doodlyHelpPages = [
			"[DESKTOP HELP 1/2 - LAUNCHING EDITORS]\nClick any icon on the desktop to open that editor immediately.\nIncludes Chart, Character, Stage, Week, Dialogue, Code Editor & Logic Editor.",
			"[DESKTOP HELP 2/2 - DESKTOP SETTINGS & MODS]\nOpen Desktop Settings to adjust icon size, zoom, labels, tints, windows, or icon movement.\nUse Left/Right to switch active mods, or press ESC to return to Main Menu."
		];
		doodlyHelpPageIndex = 0;
	}

	function showDesktopHelpPage()
	{
		if (doodlyHelpPages.length == 0)
			buildDesktopHelpPages();
		doodlyInHelpMode = true;
		playDoodlyAnim('talk1', 3.5);
		doodlyText.text = doodlyHelpPages[doodlyHelpPageIndex];
		btnHelpPrev.visible = showDoodlyWindow;
		btnHelpNext.visible = showDoodlyWindow;
	}

	function onDoodlyHelp()
	{
		buildDesktopHelpPages();
		showDesktopHelpPage();
	}

	function onHelpPrevPage()
	{
		if (doodlyHelpPages.length == 0) return;
		doodlyHelpPageIndex = (doodlyHelpPageIndex - 1 + doodlyHelpPages.length) % doodlyHelpPages.length;
		showDesktopHelpPage();
	}

	function onHelpNextPage()
	{
		if (doodlyHelpPages.length == 0) return;
		doodlyHelpPageIndex = (doodlyHelpPageIndex + 1) % doodlyHelpPages.length;
		showDesktopHelpPage();
	}

	function onDoodlyJoke()
	{
		doodlyInHelpMode = false;
		btnHelpPrev.visible = false;
		btnHelpNext.visible = false;
		playDoodlyAnim('talk2', 3.5);
		doodlyText.text = doodlyJokes[FlxG.random.int(0, doodlyJokes.length - 1)];
	}

	function onDoodlyMoveToggle()
	{
		doodlyResizeMode = false;
		isResizingDoodly = false;
		btnDoodlyResize.label.text = "Resize";

		doodlyMoveMode = !doodlyMoveMode;
		playDoodlyAnim('talk1', 2.5);
		if (doodlyMoveMode)
		{
			doodlyText.text = "Move mode ON! Drag me around inside the window, then click Lock Move.";
			btnDoodlyMove.label.text = "Lock Move";
		}
		else
		{
			isDraggingDoodly = false;
			doodlyText.text = "Locked position! Ready whenever you are.";
			btnDoodlyMove.label.text = "Move";
		}
	}

	function onDoodlyResizeToggle()
	{
		doodlyMoveMode = false;
		isDraggingDoodly = false;
		btnDoodlyMove.label.text = "Move";

		doodlyResizeMode = !doodlyResizeMode;
		playDoodlyAnim('talk2', 2.5);
		if (doodlyResizeMode)
		{
			doodlyText.text = "Resize mode ON! Drag on me to scale up or down, then click Lock Size.";
			btnDoodlyResize.label.text = "Lock Size";
		}
		else
		{
			isResizingDoodly = false;
			doodlyText.text = "Nice size! Looks good on this desktop.";
			btnDoodlyResize.label.text = "Resize";
		}
	}

	function playDoodlyAnim(animName:String, duration:Float = 2.0)
	{
		if (doodly != null && doodly.animation != null && doodly.animation.getByName(animName) != null)
		{
			doodly.animation.play(animName, true);
		}
		doodlyTalkTimer = duration;
	}

	function buildFakeFileExplorer()
	{
		explorerGroup = new FlxTypedGroup<FlxSprite>();
		explorerTexts = new FlxTypedGroup<FlxText>();
		explorerButtons = new FlxTypedGroup<FlxButton>();
		add(explorerGroup);
		add(explorerTexts);
		add(explorerButtons);

		var exX:Float = 140;
		var exY:Float = 95;
		var exW:Int = 580;
		var exH:Int = 370;

		var frame = new FlxSprite(exX, exY).makeGraphic(exW, exH, 0xFF1E2229);
		explorerHeader = new FlxSprite(exX, exY).makeGraphic(exW, 28, 0xFF007ACC);
		var addrBar = new FlxSprite(exX + 12, exY + 36).makeGraphic(exW - 24, 24, 0xFF14171C);
		explorerGroup.add(frame);
		explorerGroup.add(explorerHeader);
		explorerGroup.add(addrBar);

		var title = new FlxText(exX + 10, exY + 6, 360, "FILE_EXPLORER.EXE", 13);
		title.setFormat(Paths.font("vcr.ttf"), 13, FlxColor.WHITE, LEFT);
		explorerTexts.add(title);

		var addr = new FlxText(exX + 18, exY + 40, exW - 36, "C:\\DoodleEngine\\Images\\", 12);
		addr.setFormat(Paths.font("vcr.ttf"), 12, 0xFF90CAF9, LEFT);
		explorerTexts.add(addr);

		pickFiveRandomImages();

		for (i in 0...5)
		{
			var imgName = randomImageKeys[i];
			var itemY:Float = exY + 72 + i * 28;
			var btn = new FlxButton(exX + 14, itemY, imgName + ".png", () -> previewExplorerImage(imgName));
			btn.label.fieldWidth = 215;
			btn.label.wordWrap = false;
			explorerButtons.add(btn);
		}

		var btnReroll = new FlxButton(exX + 14, exY + 230, "Refresh", () -> {
			pickFiveRandomImages();
			refreshExplorerButtons();
		});
		var btnCloseEx = new FlxButton(exX + 114, exY + 230, "Close", toggleFakeExplorer);
		btnReroll.label.fieldWidth = 72;
		btnReroll.label.wordWrap = false;
		btnCloseEx.label.fieldWidth = 72;
		btnCloseEx.label.wordWrap = false;
		explorerButtons.add(btnReroll);
		explorerButtons.add(btnCloseEx);

		explorerPreview = new FlxSprite(exX + 265, exY + 74).makeGraphic(290, 210, 0xFF111317);
		explorerGroup.add(explorerPreview);

		var prevCaption = new FlxText(exX + 265, exY + 292, 290, "Select a file on the left to preview", 12);
		prevCaption.setFormat(Paths.font("vcr.ttf"), 12, 0xFFCFD8DC, CENTER);
		explorerTexts.add(prevCaption);

		setExplorerVisible(false);
	}

	function moveExplorerWindowBy(dx:Float, dy:Float)
	{
		if (explorerGroup == null || explorerGroup.length == 0) return;
		var frame = explorerGroup.members[0];
		if (frame == null) return;

		var newX = Math.max(8, Math.min(FlxG.width - frame.width - 8, frame.x + dx));
		var newY = Math.max(38, Math.min(FlxG.height - frame.height - 42, frame.y + dy));
		var actualDx = newX - frame.x;
		var actualDy = newY - frame.y;

		for (s in explorerGroup.members)
		{
			if (s != null)
			{
				s.x += actualDx;
				s.y += actualDy;
			}
		}
		for (t in explorerTexts.members)
		{
			if (t != null)
			{
				t.x += actualDx;
				t.y += actualDy;
			}
		}
		for (b in explorerButtons.members)
		{
			if (b != null)
			{
				b.x += actualDx;
				b.y += actualDy;
			}
		}
	}

	function pickFiveRandomImages()
	{
		var pool = candidateImages.copy();
		randomImageKeys = [];
		while (randomImageKeys.length < 5 && pool.length > 0)
		{
			var idx = FlxG.random.int(0, pool.length - 1);
			randomImageKeys.push(pool[idx]);
			pool.splice(idx, 1);
		}
		while (randomImageKeys.length < 5)
		{
			randomImageKeys.push('menuDesat');
		}
	}

	function refreshExplorerButtons()
	{
		for (i in 0...5)
		{
			if (i < explorerButtons.length && i < randomImageKeys.length)
			{
				explorerButtons.members[i].label.text = randomImageKeys[i] + ".png";
			}
		}
	}

	function previewExplorerImage(key:String)
	{
		var graphic = Paths.image(key);
		if (graphic != null)
		{
			explorerPreview.loadGraphic(graphic);
		}
		else
		{
			explorerPreview.makeGraphic(290, 210, 0xFF446688);
		}
		explorerPreview.setGraphicSize(290, 210);
		explorerPreview.updateHitbox();
	}

	function setExplorerVisible(vis:Bool)
	{
		explorerOpen = vis;
		for (s in explorerGroup.members)
			if (s != null) s.visible = vis;
		for (t in explorerTexts.members)
			if (t != null) t.visible = vis;
		for (b in explorerButtons.members)
			if (b != null) b.visible = vis;
	}

	function toggleFakeExplorer()
	{
		if (settingsOpen) setSettingsVisible(false);
		setExplorerVisible(!explorerOpen);
		if (explorerOpen)
		{
			pickFiveRandomImages();
			refreshExplorerButtons();
			previewExplorerImage(randomImageKeys[0]);
		}
	}

	function formatUptime(totalSec:Float):String
	{
		var secInt:Int = Std.int(totalSec);
		var mins:Int = Std.int(secInt / 60);
		var secs:Int = secInt % 60;
		var mStr = (mins < 10) ? "0" + mins : "" + mins;
		var sStr = (secs < 10) ? "0" + secs : "" + secs;
		return 'UPTIME $mStr:$sStr';
	}

	override function update(elapsed:Float)
	{
		sessionSeconds += elapsed;
		if (clockText != null)
			clockText.text = formatUptime(sessionSeconds);

		if (doodlyTalkTimer > 0)
		{
			doodlyTalkTimer -= elapsed;
			if (doodlyTalkTimer <= 0 && doodly != null && doodly.animation != null && doodly.animation.getByName('idle') != null)
			{
				doodly.animation.play('idle');
			}
		}

		var mx:Float = FlxG.mouse.x;
		var my:Float = FlxG.mouse.y;

		// 1. Window header dragging (checked first so windows always move smoothly)
		if (FlxG.mouse.justPressed)
		{
			if (settingsOpen && settingsHeader != null && pointInRect(mx, my, settingsHeader.x, settingsHeader.y, settingsHeader.width, settingsHeader.height))
			{
				isDraggingSettingsWin = true;
				settingsLastMouseX = mx;
				settingsLastMouseY = my;
			}
			else if (explorerOpen && explorerHeader != null && pointInRect(mx, my, explorerHeader.x, explorerHeader.y, explorerHeader.width, explorerHeader.height))
			{
				isDraggingExplorerWin = true;
				explorerLastMouseX = mx;
				explorerLastMouseY = my;
			}
			else if (showDoodlyWindow && doodlyWindowHeader != null && pointInRect(mx, my, doodlyWindowHeader.x, doodlyWindowHeader.y, doodlyWindowHeader.width, doodlyWindowHeader.height))
			{
				isDraggingDoodlyWindow = true;
				winLastMouseX = mx;
				winLastMouseY = my;
			}
		}

		if (FlxG.mouse.released)
		{
			isDraggingSettingsWin = false;
			isDraggingExplorerWin = false;
			isDraggingDoodlyWindow = false;
		}

		if (isDraggingSettingsWin)
		{
			moveSettingsWindowBy(mx - settingsLastMouseX, my - settingsLastMouseY);
			settingsLastMouseX = mx;
			settingsLastMouseY = my;
		}

		if (isDraggingExplorerWin)
		{
			moveExplorerWindowBy(mx - explorerLastMouseX, my - explorerLastMouseY);
			explorerLastMouseX = mx;
			explorerLastMouseY = my;
		}

		if (isDraggingDoodlyWindow)
		{
			moveDoodlyWindowBy(mx - winLastMouseX, my - winLastMouseY);
			winLastMouseX = mx;
			winLastMouseY = my;
		}

		// 2. Move / Resize Doodly inside its desktop window
		if (doodly != null && showDoodlyWindow)
		{
			if (doodlyMoveMode)
			{
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(doodly))
				{
					isDraggingDoodly = true;
					dragOffsetX = mx - doodly.x;
					dragOffsetY = my - doodly.y;
				}
				else if (FlxG.mouse.released)
				{
					isDraggingDoodly = false;
				}

				if (isDraggingDoodly)
				{
					doodly.x = Math.max(doodlyWindowBg.x + 8, Math.min(doodlyWindowBg.x + doodlyWindowBg.width - doodly.width - 8, mx - dragOffsetX));
					doodly.y = Math.max(doodlyWindowHeader.y + doodlyWindowHeader.height + 6, Math.min(doodlyWindowBg.y + doodlyWindowBg.height - doodly.height - 8, my - dragOffsetY));
				}
			}
			else if (doodlyResizeMode)
			{
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(doodly))
				{
					isResizingDoodly = true;
					resizeStartMouseX = mx;
					resizeStartMouseY = my;
					resizeStartWidth = doodly.width;
					resizeStartHeight = doodly.height;
				}
				else if (FlxG.mouse.released)
				{
					isResizingDoodly = false;
				}

				if (isResizingDoodly)
				{
					var dx = mx - resizeStartMouseX;
					var dy = my - resizeStartMouseY;
					var delta = (Math.abs(dx) > Math.abs(dy)) ? dx : dy;
					var newW = Math.max(50, Math.min(180, resizeStartWidth + delta));
					var ratio = (resizeStartWidth > 0) ? (resizeStartHeight / resizeStartWidth) : 1.04;
					var newH = Math.max(52, Math.min(188, newW * ratio));
					doodly.setGraphicSize(Std.int(newW), Std.int(newH));
					doodly.updateHitbox();
				}
			}
		}

		var modalOpen:Bool = explorerOpen || settingsOpen || isDraggingDoodlyWindow || isDraggingSettingsWin || isDraggingExplorerWin;

		if (FlxG.mouse.justPressed && !modalOpen)
		{
			if (FlxG.mouse.overlaps(startBtnBg) || FlxG.mouse.overlaps(startBtnLogo) || FlxG.mouse.overlaps(startBtnText))
			{
				toggleStartPopup();
			}
			else
			{
				if (startMenuOpen)
					toggleStartPopup();

				if (FlxG.mouse.overlaps(fileExplorerSpr) || FlxG.mouse.overlaps(fileExplorerLbl))
				{
					draggingIconIndex = 1000;
					iconDragStartMouseX = mx;
					iconDragStartMouseY = my;
					iconOffsetX = mx - fileExplorerSpr.x;
					iconOffsetY = my - fileExplorerSpr.y;
					iconMovedDistance = 0;
				}
				else if (FlxG.mouse.overlaps(desktopSettingsSpr) || FlxG.mouse.overlaps(desktopSettingsLbl))
				{
					draggingIconIndex = 1001;
					iconDragStartMouseX = mx;
					iconDragStartMouseY = my;
					iconOffsetX = mx - desktopSettingsSpr.x;
					iconOffsetY = my - desktopSettingsSpr.y;
					iconMovedDistance = 0;
				}
				else
				{
					for (i in 0...iconSprites.length)
					{
						if (FlxG.mouse.overlaps(iconSprites[i]) || FlxG.mouse.overlaps(iconLabels[i]))
						{
							draggingIconIndex = i;
							iconDragStartMouseX = mx;
							iconDragStartMouseY = my;
							iconOffsetX = mx - iconSprites[i].x;
							iconOffsetY = my - iconSprites[i].y;
							iconMovedDistance = 0;
							break;
						}
					}
				}
			}
		}

		if (draggingIconIndex >= 0)
		{
			if (FlxG.mouse.pressed)
			{
				iconMovedDistance = Math.abs(mx - iconDragStartMouseX) + Math.abs(my - iconDragStartMouseY);
				if (allowIconDrag)
				{
					if (draggingIconIndex == 1000)
					{
						fileExplorerSpr.x = mx - iconOffsetX;
						fileExplorerSpr.y = my - iconOffsetY;
						syncDetachedIconLabel(fileExplorerSpr, fileExplorerLbl, -30);
					}
					else if (draggingIconIndex == 1001)
					{
						desktopSettingsSpr.x = mx - iconOffsetX;
						desktopSettingsSpr.y = my - iconOffsetY;
						syncDetachedIconLabel(desktopSettingsSpr, desktopSettingsLbl, -34);
					}
					else if (draggingIconIndex < iconSprites.length)
					{
						var spr = iconSprites[draggingIconIndex];
						spr.x = mx - iconOffsetX;
						spr.y = my - iconOffsetY;
						syncIconLabel(draggingIconIndex);
					}
				}
			}
			else
			{
				var idx = draggingIconIndex;
				var wasClick = (iconMovedDistance < 6);
				draggingIconIndex = -1;

				if (wasClick)
				{
					if (idx == 1000)
						toggleFakeExplorer();
					else if (idx == 1001)
						toggleDesktopSettings();
					else if (idx >= 0 && idx < options.length)
						onAccept(options[idx]);
				}
			}
		}

		#if MODS_ALLOWED
		if (controls.UI_LEFT_P)
		{
			modDir.changeDirectory(-1);
		}
		if (controls.UI_RIGHT_P)
		{
			modDir.changeDirectory(1);
		}
		#end

		if (controls.BACK)
		{
			if (explorerOpen)
				setExplorerVisible(false);
			else if (settingsOpen)
				setSettingsVisible(false);
			else if (startMenuOpen)
				toggleStartPopup();
			else
				MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	function onAccept(option:String)
	{
		switch (option)
		{
			case 'Chart Editor':
				LoadingState.loadAndSwitchState(new ChartingState(), false);
			case 'Character Editor':
				LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
			case 'Stage Editor':
				LoadingState.loadAndSwitchState(new StageEditorState());
			case 'Week Editor':
				MusicBeatState.switchState(new WeekEditorState());
			case 'Menu Character Editor':
				MusicBeatState.switchState(new MenuCharacterEditorState());
			case 'Dialogue Editor':
				LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
			case 'Dialogue Portrait Editor':
				LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
			case 'Note Splash Editor':
				MusicBeatState.switchState(new NoteSplashEditorState());
			case 'Test stickers':
				MusicBeatState.switchState(new StickerTest());
			case 'Player editor':
				MusicBeatState.switchState(new CharSelectEditor());
			#if PROFILE_BUILD
			case 'Crash the game':
				{
					trace("Break the StackOverflow.com");
					untyped __cpp__("throw \"This is a native C++ exception!\";");
				}
			case 'Usermess the game':
				{
					UserErrorSubstate.makeMessage("The devs are too stupid and they write way too long errors", "Skill issue :/");
				}
			#end
			case 'Result Preview Menu':
				MusicBeatState.switchState(new ResultPreviewMenu());
			case 'Code Editor':
				MusicBeatState.switchState(new CodeEditorState());
			case 'Logic Editor':
				MusicBeatState.switchState(new LogicEditorState());
		}
		FlxG.sound.music.volume = 0;
	}
}
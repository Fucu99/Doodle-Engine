package mikolka.vslice.ui;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.compatibility.freeplay.FreeplayHelpers;
import mikolka.compatibility.ui.StoryModeHooks;
import mikolka.compatibility.ModsHelper;
import mikolka.vslice.StickerSubState;
import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
#if !LEGACY_PSYCH
import backend.CacheSystem;
import states.editors.MasterEditorMenu;
import backend.WeekData;
import backend.Highscore;
import objects.MenuItem;
import objects.MenuCharacter;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
#else
import Paths as CacheSystem;
import editors.MasterEditorMenu;
#end

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';

	public var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;

	public static var curWeek:Int = 0;

	public var curSelectedPartial:Float = 0;

	var txtTracklist:FlxText;
	var tracksSprite:FlxSprite;
	var albumSprite:FlxSprite;
	var albumOutline:FlxSprite;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	public var loadedWeeks:Array<WeekData> = [];

	var stickerSubState:StickerSubState;

	public function new(?stickers:StickerSubState = null)
	{
		super();

		if (stickers != null)
		{
			stickerSubState = stickers;
		}
	}

	override function create()
	{
		if (stickerSubState != null)
		{
			openSubState(stickerSubState);
			ModsHelper.clearStoredWithoutStickers();
			stickerSubState.degenStickers();
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		else
			CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		PlayState.altInstrumentals = null;
		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		final accept:String = controls.mobileC ? "A" : "ACCEPT";
		final reject:String = controls.mobileC ? "B" : "BACK";

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			UserErrorSubstate.makeMessage("NO LEVELS ADDED FOR STORY MODE", "\n\nPress " + accept + " to go to the Week Editor Menu.");
			subStateClosed.addOnce(s -> FlxG.switchState(new MasterEditorMenu()));
			return;
		}

		if (curWeek >= WeekData.weeksList.length)
			curWeek = 0;

		#if LEGACY_PSYCH
		scoreText = new FlxText(10, 10, 0, 'LEVEL SCORE: ' + lerpScore, 36);
		#else
		scoreText = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'LEVEL SCORE: {1}', [lerpScore]), 36);
		#end
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = VsliceOptions.ANTIALIASING;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = FreeplayHelpers.weekIsLocked(WeekData.weeksList[i]);
			if ((!isLocked || !weekFile.hiddenUntilUnlocked) && weekFile != null)
			{
				loadedWeeks.push(weekFile);
				ModsHelper.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				
				// Week rese leggermente più compatte (0.72)
				weekThing.scale.set(0.72, 0.72);
				weekThing.updateHitbox();

				itemTargetY += Math.max(weekThing.height, 80) + 10;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				weekThing.x += 68;

				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.antialiasing = VsliceOptions.ANTIALIASING;
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = num;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		ModsHelper.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(FlxG.width - 380, grpWeekText.members[0].y + 10);
		leftArrow.antialiasing = VsliceOptions.ANTIALIASING;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.scale.set(0.85, 0.85);
		leftArrow.updateHitbox();
		difficultySelectors.add(leftArrow);

		StoryModeHooks.resetDiffList();
		if (lastDifficultyName == '')
		{
			lastDifficultyName = StoryModeHooks.DEFAULT_DIFF;
		}
		curDifficulty = Math.round(Math.max(0, StoryModeHooks.DEFAULT_DIFFICULTIES.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = VsliceOptions.ANTIALIASING;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 320, leftArrow.y);
		rightArrow.antialiasing = VsliceOptions.ANTIALIASING;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.scale.set(0.85, 0.85);
		rightArrow.updateHitbox();
		difficultySelectors.add(rightArrow);

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, 56, 0xFF000000));
		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		// --- TRACKS IMAGE SPOSTATA DI 40 PIXEL A DESTRA (285 + 40 = 325) ---
		tracksSprite = new FlxSprite(325, bgSprite.y + 415).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = VsliceOptions.ANTIALIASING;
		tracksSprite.scale.set(0.75, 0.75);
		tracksSprite.updateHitbox();
		add(tracksSprite);

		// --- TESTO TRACCE SPOSTATO DI 40 PIXEL A DESTRA (320 + 40 = 360) ---
		txtTracklist = new FlxText(360, tracksSprite.y + 38, 0, "", 22);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);

		// --- OUTLINE BIANCO EVIDENTE DELL'ALBUM ---
		albumOutline = new FlxSprite();
		albumOutline.antialiasing = VsliceOptions.ANTIALIASING;
		albumOutline.angle = -6;
		add(albumOutline);

		// --- ALBUM ROLL PRINCIPALE ---
		albumSprite = new FlxSprite();
		albumSprite.antialiasing = VsliceOptions.ANTIALIASING;
		albumSprite.angle = -6;
		add(albumSprite);
		// ---------------------------------------------

		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('LEFT_FULL', 'A_B_X_Y');

		var button = new TouchZone((FlxG.width / 2) - 210, 460, 420, 160, FlxColor.PURPLE);

		var scroll = new ScrollableObject(-0.01, (FlxG.width / 2) - 240, 0, 500, FlxG.height, button);
		scroll.onPartialScroll.add(delta -> changeWeek(delta, false));
		scroll.onFullScroll.add(delta ->
		{
			changeDifficulty();
		});
		scroll.onFullScrollSnap.add(() -> changeWeek(0, true));
		scroll.onTap.add(() ->
		{
			selectWeek();
		});
		add(scroll);
		add(button);
		#end

		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		if (WeekData.weeksList.length > 0)
			changeWeek();
		super.closeSubState();

		#if TOUCH_CONTROLS_ALLOWED
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_X_Y');
		#end
	}

	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(new MainMenuState());
			}
			super.update(elapsed);
			return;
		}

		if (intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if (Math.abs(intendedScore - lerpScore) < 10)
				lerpScore = intendedScore;

			#if LEGACY_PSYCH
			scoreText.text = 'LEVEL SCORE: ${lerpScore}';
			#else
			scoreText.text = Language.getPhrase('week_score', 'LEVEL SCORE: {1}', [lerpScore]);
			#end
		}

		if (!movedBack && !selectedWeek)
		{
			var changeDiff = false;
			if (controls.UI_UP_P)
			{
				changeWeek(-1, true);
				changeDiff = true;
			}

			if (controls.UI_DOWN_P)
			{
				changeWeek(1, true);
				changeDiff = true;
			}

			if (FlxG.mouse.wheel != 0)
			{
				changeWeek(-FlxG.mouse.wheel, true);
				changeDifficulty();
			}

			var holdingUiRight = controls.UI_RIGHT;
			var holdingUiLeft = controls.UI_LEFT;
			var pressedUiLeft = controls.UI_LEFT_P;
			var pressedUiRight = controls.UI_RIGHT_P;
			#if TOUCH_CONTROLS_ALLOWED
			#if debug
			if (FlxG.mouse.overlaps(leftArrow))
			{
				holdingUiLeft = true;
				pressedUiLeft = FlxG.mouse.justPressed;
			}
			if (FlxG.mouse.overlaps(rightArrow))
			{
				holdingUiRight = true;
				pressedUiRight = FlxG.mouse.justPressed;
			}
			#end
			if (TouchUtil.overlaps(leftArrow))
			{
				holdingUiLeft = true;
				pressedUiLeft = TouchUtil.justPressed;
			}
			if (TouchUtil.overlaps(rightArrow))
			{
				holdingUiRight = true;
				pressedUiRight = TouchUtil.justPressed;
			}
			#end

			if (holdingUiRight)
				rightArrow.animation.play('press')
			else
				rightArrow.animation.play('idle');

			if (holdingUiLeft)
				leftArrow.animation.play('press');
			else
				leftArrow.animation.play('idle');

			if (pressedUiRight)
				changeDifficulty(1);
			else if (pressedUiLeft)
				changeDifficulty(-1);
			else if (changeDiff)
				changeDifficulty();

			if (FlxG.keys.justPressed.CONTROL #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonX.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
				#if TOUCH_CONTROLS_ALLOWED
				removeTouchPad();
				#end
			}
			else if (controls.RESET #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonY.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				#if TOUCH_CONTROLS_ALLOWED
				removeTouchPad();
				#end
			}
			else if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
		var offY:Float = grpWeekText.members[curWeek].targetY;

		var partialDiff = (curSelectedPartial - curWeek);
		var curItem = grpWeekText.members[curWeek];
		if (partialDiff > 0 && grpWeekText.length > curWeek + 1)
		{
			var nextItem = grpWeekText.members[curWeek + 1];
			offY = FlxMath.lerp(curItem.targetY, nextItem.targetY, partialDiff);
		}
		else if (partialDiff < 0 && 0 <= curWeek - 1)
		{
			var prevItem = grpWeekText.members[curWeek - 1];
			offY = FlxMath.lerp(prevItem.targetY, curItem.targetY, 1 + partialDiff);
		}

		for (num => item in grpWeekText.members)
			item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));

		for (num => lock in grpLocks.members)
			lock.y = grpWeekText.members[lock.ID].y + grpWeekText.members[lock.ID].height / 2 - lock.height / 2;
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!FreeplayHelpers.weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var succsess = StoryModeHooks.prepareWeek(this);
			if (!succsess)
				return;
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].isFlashing = true;
				for (char in grpWeekCharacters.members)
				{
					if (char.character != '' && char.hasConfirmAnimation)
					{
						char.animation.play('confirm');
					}
				}
				stopspamming = true;
			}
			StoryModeHooks.moveWeekToPlayState();
		}
		else
			FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = StoryModeHooks.DIFFICULTIES.length - 1;
		if (curDifficulty >= StoryModeHooks.DIFFICULTIES.length)
			curDifficulty = 0;

		ModsHelper.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = StoryModeHooks.getDifficultyString(curDifficulty);

		if (Paths.fileExists('images/menudifficulties/' + Paths.formatToSongPath(diff) + ".xml",BINARY))
		{
			var newFrames = Paths.getSparrowAtlas('menudifficulties/' + Paths.formatToSongPath(diff));
			sprDifficulty.frames = newFrames;
			sprDifficulty.animation.addByPrefix('idle', 'idle0', 24, true);
			if (VsliceOptions.FLASHBANG)
				sprDifficulty.animation.play('idle');
			sprDifficulty.scale.set(0.85, 0.85);
			sprDifficulty.updateHitbox();
			sprDifficulty.x = leftArrow.x + 50;
			sprDifficulty.x += (250 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + 40;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 25, alpha: 1}, 0.07);
		}
		else
		{
			var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));

			if (sprDifficulty.graphic != newImage)
			{
				sprDifficulty.loadGraphic(newImage);
				sprDifficulty.scale.set(0.85, 0.85);
				sprDifficulty.updateHitbox();
				sprDifficulty.x = leftArrow.x + 50;
				sprDifficulty.x += (250 - sprDifficulty.width) / 3;
				sprDifficulty.alpha = 0;
				sprDifficulty.y = leftArrow.y - sprDifficulty.height + 40;

				FlxTween.cancelTweensOf(sprDifficulty);
				FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 25, alpha: 1}, 0.07);
			}
		}
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;

	function changeWeek(change:Float = 0, usePrecision:Bool = false):Void
	{
		if (usePrecision)
		{
			if (change != 0)
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curWeek = FlxMath.wrap(curWeek + Std.int(change), 0, loadedWeeks.length - 1);
			curSelectedPartial = curWeek;
		}
		else
		{
			curSelectedPartial = FlxMath.bound(curSelectedPartial + change, 0, loadedWeeks.length - 1);
			if (curWeek != Math.round(curSelectedPartial))
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

			curWeek = Math.round(curSelectedPartial);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		ModsHelper.setDirectoryFromWeek(leWeek);

		#if LEGACY_PSYCH
		var leName:String = leWeek.storyName;
		#else
		var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
		#end
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var unlocked:Bool = !FreeplayHelpers.weekIsLocked(leWeek.fileName);
		for (num => item in grpWeekText.members)
		{
			item.alpha = 0.6;
			if (num - curWeek == 0 && unlocked)
				item.alpha = 1;
		}

		bgSprite.visible = true;
		var assetName:String = leWeek.weekBackground;
		if (assetName == null || assetName.length < 1)
		{
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
			if (MobileScaleMode.enabled)
				bgSprite.screenCenter(X);
		}
		PlayState.storyWeek = curWeek;

		StoryModeHooks.loadDifficultiesFromWeek();
		difficultySelectors.visible = unlocked;

		if (StoryModeHooks.DIFFICULTIES.contains(StoryModeHooks.DEFAULT_DIFF))
			curDifficulty = Math.round(Math.max(0, StoryModeHooks.DEFAULT_DIFFICULTIES.indexOf(StoryModeHooks.DEFAULT_DIFF)));
		else
			curDifficulty = 0;

		var newPos:Int = StoryModeHooks.DIFFICULTIES.indexOf(lastDifficultyName);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
		{
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		// --- LETTURA ALBUM ID DAL METADATA DELLA PRIMA CANZONE ---
		var albumToLoad:String = "base";
		if (leWeek.songs != null && leWeek.songs.length > 0)
		{
			var firstSongName:String = leWeek.songs[0][0];
			var songLowercase:String = Paths.formatToSongPath(firstSongName);
			var metaPath:String = 'data/' + songLowercase + '/metadata.json';
			
			if (Paths.fileExists(metaPath, TEXT))
			{
				try
				{
					var rawJson:String = Paths.getTextFromFile(metaPath);
					if (rawJson != null)
					{
						var json:Dynamic = haxe.Json.parse(rawJson);
						if (json != null && Reflect.hasField(json, "albumId") && json.albumId != null)
						{
							albumToLoad = json.albumId;
						}
					}
				}
				catch(e:Dynamic)
				{
					trace('Errore nel caricamento del metadata per $firstSongName: $e');
				}
			}
		}

		var albumGraphic = Paths.image('freeplay/albumRoll/' + albumToLoad);
		if (albumGraphic == null)
		{
			albumGraphic = Paths.image('freeplay/albumRoll/base');
		}

		if (albumGraphic != null)
		{
			// Configurazione Outline bianca molto spessa e marcata
			albumOutline.loadGraphic(albumGraphic);
			albumOutline.setGraphicSize(Std.int(albumOutline.width * 1.15) + 20);
			albumOutline.updateHitbox();
			albumOutline.color = FlxColor.WHITE;

			// Configurazione Sprite Album principale (ingrandito a 1.15)
			albumSprite.loadGraphic(albumGraphic);
			albumSprite.setGraphicSize(Std.int(albumSprite.width * 1.15));
			albumSprite.updateHitbox();

			// Posizione finale in basso a sinistra
			var targetX:Float = -15;
			var targetY:Float = FlxG.height - albumSprite.height + 20;

			// Animazione Tween d'impatto con flash cromatico/trasparenza
			albumSprite.x = targetX - 70;
			albumSprite.y = targetY + 40;
			albumSprite.alpha = 0;
			albumSprite.scale.set(0.9, 0.9);

			albumOutline.x = targetX - 70 - 10;
			albumOutline.y = targetY + 40 - 10;
			albumOutline.alpha = 0;
			albumOutline.scale.set(0.9, 0.9);

			FlxTween.cancelTweensOf(albumSprite);
			FlxTween.cancelTweensOf(albumOutline);

			// Animazione fluida e dinamica per entrambi
			FlxTween.tween(albumSprite, {x: targetX, y: targetY, alpha: 1}, 0.3, {ease: FlxEase.cubeOut});
			FlxTween.tween(albumSprite.scale, {x: 1.15, y: 1.15}, 0.3, {ease: FlxEase.cubeOut});

			FlxTween.tween(albumOutline, {x: targetX - 10, y: targetY - 10, alpha: 1.0}, 0.3, {ease: FlxEase.cubeOut});
			FlxTween.tween(albumOutline.scale, {x: 1.15, y: 1.15}, 0.3, {ease: FlxEase.cubeOut});
		}
		// ---------------------------------------------------------

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}
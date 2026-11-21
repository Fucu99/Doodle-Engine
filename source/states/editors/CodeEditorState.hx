package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxInputText;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;

enum EditorLang
{
	HX;
	LUA;
	JSON;
}

class CodeEditorState extends MusicBeatState
{
	var currentLang:EditorLang = HX;
	var currentFileName:String = "script.hx";
	var hasUnsavedChanges:Bool = false;
	var lastCodeText:String = "";

	var topBarBg:FlxSprite;
	var titleText:FlxText;
	var statusText:FlxText;
	var gutterBg:FlxSprite;
	var lineNumbersText:FlxText;
	var activeLineIndicator:FlxSprite;

	var codeInput:FlxInputText;
	var fontSize:Int = 18;
	var showLineNumbers:Bool = true;
	var autoCompleteEnabled:Bool = true;
	var doodlyVisibleEnabled:Bool = true;

	// Autocomplete popup
	var acBox:FlxSprite;
	var acItems:FlxTypedGroup<FlxText>;
	var suggestions:Array<String> = [];
	var acSelected:Int = 0;
	var acVisible:Bool = false;
	var maxAcVisible:Int = 6;

	// Doodly helper
	var doodly:FlxSprite;
	var doodlyBubble:FlxSprite;
	var doodlyText:FlxText;
	var doodlyMenuOpen:Bool = false;

	// Move & Resize states for Doodly
	var doodlyMoveMode:Bool = false;
	var isDraggingDoodly:Bool = false;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;

	var doodlyResizeMode:Bool = false;
	var isResizingDoodly:Bool = false;
	var resizeStartMouseX:Float = 0;
	var resizeStartMouseY:Float = 0;
	var resizeStartWidth:Float = 110;
	var resizeStartHeight:Float = 114;

	var doodlyTalkTimer:Float = 0;

	var btnDoodlyHelp:FlxButton;
	var btnDoodlyJoke:FlxButton;
	var btnDoodlyMove:FlxButton;
	var btnDoodlyResize:FlxButton;

	// Expanded 5-page Help system
	var doodlyHelpPages:Array<String> = [];
	var doodlyHelpPageIndex:Int = 0;
	var doodlyInHelpMode:Bool = false;
	var btnHelpPrev:FlxButton;
	var btnHelpNext:FlxButton;

	var doodlyJokes:Array<String> = [
		"Why do programmers prefer dark mode? Because light attracts bugs!",
		"I told my code a joke... it threw an unhandled exception.",
		"99 little bugs in the code, take one down, patch it around... 127 little bugs in the code.",
		"My favorite Haxe feature? Compiling once and praying it works everywhere.",
		"Lua starts arrays at 1 just to keep you on your toes.",
		"Ctrl+S is the true save point of every developer.",
		"It's not a bug, it's an undocumented Doodle Engine feature!",
		"Semiconductors? More like maybe-conductors when my script crashes.",
		"Why did the sprite cross the screen? Because scrollFactor wasn't set to zero!",
		"Sleep is just garbage collection for humans."
	];

	// Settings panel
	var settingsPanel:FlxSprite;
	var settingsTitle:FlxText;
	var settingsGroup:FlxTypedGroup<FlxButton>;
	var settingsOpen:Bool = false;

	// File dialogs
	var openFileRef:FileReference;
	var saveFileRef:FileReference;

	// Expanded autocomplete dictionaries
	var hxKeywords:Array<String> = [
		"import", "package", "class", "extends", "implements", "public", "private", "static", "override", "inline",
		"var", "final", "function", "return", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue",
		"try", "catch", "throw", "new", "true", "false", "null", "trace", "ease", "enable", "enabled", "exists",
		"FlxG", "FlxSprite", "FlxText", "FlxTween", "FlxEase", "FlxMath", "FlxColor", "FlxTimer", "FlxCamera", "FlxSound", "FlxTypedGroup",
		"PlayState", "ClientPrefs", "Conductor", "Paths", "CoolUtil", "MusicBeatState", "MusicBeatSubstate", "Note", "StrumNote", "Character",
		"onCreate", "onCreatePost", "onUpdate", "onUpdatePost", "onBeatHit", "onStepHit", "onSectionHit", "onEvent", "onDestroy",
		"goodNoteHit", "opponentNoteHit", "noteMiss", "onGameOver", "onStartCountdown", "onSongStart", "onEndSong",
		"boyfriend", "dad", "gf", "camGame", "camHUD", "camOther", "add", "insert", "remove", "loadGraphic", "makeGraphic", "setGraphicSize", "updateHitbox", "screenCenter"
	];

	var luaKeywords:Array<String> = [
		"function", "local", "if", "then", "else", "elseif", "end", "return", "for", "in", "do", "while", "repeat", "until", "break",
		"true", "false", "nil", "and", "or", "not", "ease", "enable", "enabled", "exists", "pairs", "ipairs", "tonumber", "tostring", "table", "string", "math",
		"onCreate", "onCreatePost", "onUpdate", "onUpdatePost", "onBeatHit", "onStepHit", "onSectionHit",
		"onCountdownTick", "onStartCountdown", "onSongStart", "onEndSong", "onEvent", "onEventPushed",
		"goodNoteHit", "opponentNoteHit", "noteMiss", "noteMissPress", "onGameOver", "onGameOverStart", "onGameOverConfirm",
		"getProperty", "setProperty", "getPropertyFromGroup", "setPropertyFromGroup", "getPropertyFromClass", "setPropertyFromClass",
		"callMethod", "callOnLuas", "setOnLuas", "getRunningScripts", "addLuaScript", "removeLuaScript",
		"makeLuaSprite", "addLuaSprite", "removeLuaSprite", "makeAnimatedLuaSprite", "addAnimationByPrefix", "addAnimationByIndices", "playAnim", "setScrollFactor", "scaleObject", "screenCenter",
		"doTweenX", "doTweenY", "doTweenAngle", "doTweenAlpha", "doTweenColor", "doTweenScaleX", "doTweenScaleY", "cancelTween", "runTimer", "cancelTimer",
		"triggerEvent", "runHaxeCode", "runHaxeFunction", "addHaxeLibrary", "playSound", "stopSound", "soundFadeIn", "soundFadeOut",
		"getRandomInt", "getRandomFloat", "curBeat", "curStep", "curSection", "crochet", "stepCrochet", "songLength", "songName", "bpm", "scrollSpeed", "health", "score", "misses", "rating"
	];

	var jsonKeywords:Array<String> = [
		"song", "notes", "bpm", "speed", "player1", "player2", "gfVersion", "stage",
		"sectionNotes", "mustHitSection", "altAnim", "gfSection", "sectionBeats", "changeBPM",
		"events", "event", "needsVoices", "validScore", "format", "offset", "scrollSpeed",
		"arrowSkin", "splashSkin", "songCredits", "allowErectVariants"
	];

	override function create()
	{
		FlxG.mouse.visible = true;
		FlxG.camera.bgColor = 0xFF1E1E1E;

		// Top bar
		topBarBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, 44, 0xFF252526);
		add(topBarBg);

		titleText = new FlxText(14, 10, 420, getHeaderTitle(), 16);
		titleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(titleText);

		var btnNewHx = new FlxButton(440, 8, "New .hx", () -> newFile(HX));
		var btnNewLua = new FlxButton(525, 8, "New .lua", () -> newFile(LUA));
		var btnNewJson = new FlxButton(610, 8, "New .json", () -> newFile(JSON));
		var btnOpen = new FlxButton(705, 8, "Open", openFileDialog);
		var btnSave = new FlxButton(790, 8, "Save As", saveFileDialog);
		var btnSettings = new FlxButton(875, 8, "Settings", toggleSettings);
		var btnExit = new FlxButton(960, 8, "Exit", exitEditor);

		for (b in [btnNewHx, btnNewLua, btnNewJson, btnOpen, btnSave, btnSettings, btnExit])
		{
			add(b);
		}

		// Left gutter for line numbers
		gutterBg = new FlxSprite(0, 44).makeGraphic(64, FlxG.height - 72, 0xFF1A1A1A);
		add(gutterBg);

		activeLineIndicator = new FlxSprite(60, 44).makeGraphic(4, 24, 0xFFFF8C00);
		add(activeLineIndicator);

		lineNumbersText = new FlxText(6, 48, 50, "1", fontSize);
		lineNumbersText.setFormat(Paths.font("vcr.ttf"), fontSize, 0xFF858585, RIGHT);
		add(lineNumbersText);

		// Main code area
		var initialText = getDefaultTemplate(HX);
		codeInput = new FlxInputText(74, 48, FlxG.width - 90, initialText, fontSize, FlxColor.WHITE, 0xFF1E1E1E);
		codeInput.setFormat(Paths.font("vcr.ttf"), fontSize, FlxColor.WHITE, LEFT);
		codeInput.multiline = true;
		lastCodeText = initialText;
		add(codeInput);

		// Doodly helper setup
		buildDoodlyHelper();

		// Bottom status bar
		var bottomBar = new FlxSprite(0, FlxG.height - 28).makeGraphic(FlxG.width, 28, 0xFF007ACC);
		add(bottomBar);

		statusText = new FlxText(12, FlxG.height - 24, FlxG.width - 24, "Lang: HX | Ready", 14);
		statusText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(statusText);

		// Autocomplete dropdown
		acBox = new FlxSprite(0, 0).makeGraphic(250, 160, 0xFF252526);
		acBox.visible = false;
		add(acBox);

		acItems = new FlxTypedGroup<FlxText>();
		add(acItems);
		for (i in 0...maxAcVisible)
		{
			var item = new FlxText(0, 0, 242, "", 16);
			item.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
			item.visible = false;
			acItems.add(item);
		}

		// Settings overlay
		buildSettingsPanel();

		refreshEditorVisuals();
		super.create();
	}

	function buildDoodlyHelper()
	{
		doodly = new FlxSprite(FlxG.width - 190, FlxG.height - 210);
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
			doodly.makeGraphic(120, 120, FlxColor.WHITE);
		}
		doodly.setGraphicSize(110, 114);
		doodly.updateHitbox();
		doodly.visible = doodlyVisibleEnabled;
		add(doodly);

		doodlyBubble = new FlxSprite(0, 0).makeGraphic(410, 168, 0xFFFFFBE6);
		doodlyBubble.visible = false;
		add(doodlyBubble);

		doodlyText = new FlxText(0, 0, 392, "Hey! I'm Doodly! Click Help, Joke, Move, or Resize.", 13);
		doodlyText.setFormat(Paths.font("vcr.ttf"), 13, 0xFF1A1A1A, LEFT);
		doodlyText.visible = false;
		add(doodlyText);

		btnDoodlyHelp = new FlxButton(0, 0, "Help", onDoodlyHelp);
		btnDoodlyJoke = new FlxButton(0, 0, "Joke", onDoodlyJoke);
		btnDoodlyMove = new FlxButton(0, 0, "Move", onDoodlyMoveToggle);
		btnDoodlyResize = new FlxButton(0, 0, "Resize", onDoodlyResizeToggle);
		btnHelpPrev = new FlxButton(0, 0, "< Prev", onHelpPrevPage);
		btnHelpNext = new FlxButton(0, 0, "Next >", onHelpNextPage);

		for (b in [btnDoodlyHelp, btnDoodlyJoke, btnDoodlyMove, btnDoodlyResize, btnHelpPrev, btnHelpNext])
		{
			b.visible = false;
			add(b);
		}

		syncDoodlyUI();
	}

	function syncDoodlyUI()
	{
		if (doodly == null) return;

		doodly.width = Math.max(55, Math.min(280, doodly.width));
		doodly.height = Math.max(57, Math.min(290, doodly.height));
		doodly.x = Math.max(70, Math.min(FlxG.width - doodly.width - 10, doodly.x));
		doodly.y = Math.max(50, Math.min(FlxG.height - doodly.height - 34, doodly.y));

		var bx = Math.max(70, Math.min(FlxG.width - doodlyBubble.width - 10, doodly.x - 160));
		var by = doodly.y - doodlyBubble.height - 56;
		if (by < 50)
			by = doodly.y + doodly.height + 6;

		doodlyBubble.setPosition(bx, by);
		doodlyText.setPosition(bx + 9, by + 8);

		var btnY = by + doodlyBubble.height + 4;
		if (btnY + 46 > FlxG.height - 30)
			btnY = by - 48;

		btnDoodlyHelp.setPosition(bx, btnY);
		btnDoodlyJoke.setPosition(bx + 84, btnY);
		btnDoodlyMove.setPosition(bx + 168, btnY);
		btnDoodlyResize.setPosition(bx + 252, btnY);

		btnHelpPrev.setPosition(bx, btnY + 24);
		btnHelpNext.setPosition(bx + 84, btnY + 24);
	}

	function setDoodlyMenuState(open:Bool)
	{
		if (!doodlyVisibleEnabled) open = false;
		doodlyMenuOpen = open;
		doodlyBubble.visible = open;
		doodlyText.visible = open;
		btnDoodlyHelp.visible = open;
		btnDoodlyJoke.visible = open;
		btnDoodlyMove.visible = open;
		btnDoodlyResize.visible = open;

		if (!open)
		{
			doodlyInHelpMode = false;
			btnHelpPrev.visible = false;
			btnHelpNext.visible = false;
			doodlyMoveMode = false;
			isDraggingDoodly = false;
			doodlyResizeMode = false;
			isResizingDoodly = false;
			btnDoodlyMove.label.text = "Move";
			btnDoodlyResize.label.text = "Resize";
			playDoodlyAnim('idle', 0);
		}
		else
		{
			btnHelpPrev.visible = doodlyInHelpMode;
			btnHelpNext.visible = doodlyInHelpMode;
			syncDoodlyUI();
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

	function buildHelpPagesForLang()
	{
		doodlyHelpPages = switch (currentLang)
		{
			case HX:
				[
					"[HSCRIPT 1/5 - SYNTAX BASICS]\nDeclare vars with types: var speed:Float = 1.2; var active:Bool = true;\nUse if / else if / else for logic and functions for reusable code.\nAlways end statements with ';' and wrap blocks in { }.",
					"[HSCRIPT 2/5 - SONG & STATE HOOKS]\nonCreate(): runs when the song/state is being set up.\nonCreatePost(): runs after characters, HUD & stage objects exist.\nonUpdate(elapsed): runs every frame (scale movement by elapsed!).\nonBeatHit() & onStepHit(): beat/step rhythm callbacks.",
					"[HSCRIPT 3/5 - NOTES & GAMEPLAY]\ngoodNoteHit(note): triggered when player hits a note.\nopponentNoteHit(note): triggered when opponent hits a note.\nnoteMiss(note): triggered on missed notes (check !note.isSustainNote).\nonEvent(name, val1, val2): react to chart events.",
					"[HSCRIPT 4/5 - CHARACTERS & CAMERAS]\nAccess characters via boyfriend, dad, gf.\nAccess cameras via camGame, camHUD, camOther.\nFor HUD elements, set scrollFactor.set(0, 0) so they stay pinned.\nUse FlxTween.tween(target, {x: 200, alpha: 0.5}, 0.6, {ease: FlxEase.quadOut});",
					"[HSCRIPT 5/5 - ENGINE UTILS & PREFS]\nRead Doodle/Psych prefs: ClientPrefs.data.doodleCamMove\nLoad assets via Paths.image('name'), Paths.sound('name'), Paths.music('name').\nUse FlxTimer.wait(1.5, () -> { trace('Done!'); }); for delays."
				];
			case LUA:
				[
					"[LUA 1/5 - SYNTAX BASICS]\nPrefer 'local' variables inside scripts so names don't clash.\nBlocks use 'if ... then ... elseif ... else ... end' and 'function ... end'.\nNote: Lua tables/arrays usually start at index 1, not 0!",
					"[LUA 2/5 - FNF LIFECYCLE HOOKS]\nonCreate() / onCreatePost(): setup sprites, shaders & initial values.\nonUpdate(elapsed) / onUpdatePost(elapsed): per-frame logic.\nonBeatHit() / onStepHit() / onSectionHit(): rhythm triggers.\nonStartCountdown() / onSongStart() / onEndSong(): song flow.",
					"[LUA 3/5 - PROPERTIES & GROUPS]\ngetProperty('boyfriend.x') / setProperty('camHUD.alpha', 0.5)\ngetPropertyFromClass('ClientPrefs', 'data.doodleNotes')\ngetPropertyFromGroup('strumLineNotes', i, 'color')\nsetPropertyFromGroup('unspawnNotes', i, 'rgbShader.r', col)",
					"[LUA 4/5 - SPRITES & ANIMATIONS]\nmakeLuaSprite('tag', 'imagePath', x, y)\naddLuaSprite('tag', frontOfCharsBool) -- false = behind, true = in front\nmakeAnimatedLuaSprite('animTag', 'atlasPath', x, y)\naddAnimationByPrefix('animTag', 'idle', 'AnimPrefix', 24, true)",
					"[LUA 5/5 - TWEENS, EVENTS & HAXE]\ndoTweenX('id', 'dad', 300, 1.0, 'cubeOut') / doTweenColor(...)\ntriggerEvent('Camera Follow Pos', '600', '400')\nrunHaxeCode('trace(PlayState.instance.songSpeed);') for Haxe access."
				];
			case JSON:
				[
					"[JSON 1/5 - STRICT SYNTAX RULES]\nJSON uses { } objects (key: value) and [ ] arrays (lists).\nEvery key and string MUST use double quotes \"likeThis\", never single quotes.\nDo NOT leave a trailing comma after the last item in { } or [ ].",
					"[JSON 2/5 - SONG METADATA]\nCommon top-level keys: \"song\", \"bpm\", \"speed\", \"needsVoices\".\nCharacters & stage: \"player1\", \"player2\", \"gfVersion\", \"stage\".\nKeep \"bpm\" and \"speed\" as numbers (not strings).",
					"[JSON 3/5 - NOTES & SECTIONS]\nChart sections live inside \"notes\": [ { ... } ].\nEach section has \"sectionNotes\": [ ... ] and \"mustHitSection\": true/false.\n\"mustHitSection\" controls whether camera focus defaults to BF or Dad.",
					"[JSON 4/5 - NOTE ENTRY FORMAT]\nEach item inside \"sectionNotes\" is [strumTime, noteData, sustainLength].\nstrumTime: exact hit time in milliseconds (Float/Int).\nnoteData: 0=Left, 1=Down, 2=Up, 3=Right (often +4 for opposite side).\nsustainLength: hold tail length in ms (0 for normal tap notes).",
					"[JSON 5/5 - EVENTS & DEBUGGING]\nChart events live in \"events\": [ [timeMs, [ [eventName, v1, v2] ]] ].\nAlways validate brackets { } and [ ] match before saving.\nUse Ctrl+S to export a backup copy anywhere on your PC."
				];
		};
		doodlyHelpPageIndex = 0;
	}

	function showCurrentHelpPage()
	{
		if (doodlyHelpPages.length == 0)
			buildHelpPagesForLang();

		doodlyInHelpMode = true;
		playDoodlyAnim('talk1', 4.0);
		doodlyText.text = doodlyHelpPages[doodlyHelpPageIndex];
		btnHelpPrev.visible = doodlyMenuOpen && doodlyInHelpMode;
		btnHelpNext.visible = doodlyMenuOpen && doodlyInHelpMode;
		syncDoodlyUI();
	}

	function onDoodlyHelp()
	{
		buildHelpPagesForLang();
		showCurrentHelpPage();
	}

	function onHelpPrevPage()
	{
		if (doodlyHelpPages.length == 0) return;
		doodlyHelpPageIndex = (doodlyHelpPageIndex - 1 + doodlyHelpPages.length) % doodlyHelpPages.length;
		showCurrentHelpPage();
	}

	function onHelpNextPage()
	{
		if (doodlyHelpPages.length == 0) return;
		doodlyHelpPageIndex = (doodlyHelpPageIndex + 1) % doodlyHelpPages.length;
		showCurrentHelpPage();
	}

	function onDoodlyJoke()
	{
		doodlyInHelpMode = false;
		btnHelpPrev.visible = false;
		btnHelpNext.visible = false;

		playDoodlyAnim('talk2', 3.5);
		var idx = FlxG.random.int(0, doodlyJokes.length - 1);
		doodlyText.text = doodlyJokes[idx];
	}

	function onDoodlyMoveToggle()
	{
		doodlyInHelpMode = false;
		btnHelpPrev.visible = false;
		btnHelpNext.visible = false;

		doodlyResizeMode = false;
		isResizingDoodly = false;
		btnDoodlyResize.label.text = "Resize";

		doodlyMoveMode = !doodlyMoveMode;
		playDoodlyAnim('talk1', 2.5);
		if (doodlyMoveMode)
		{
			doodlyText.text = "Move mode ON! Drag me around, then click Lock Move.";
			btnDoodlyMove.label.text = "Lock Move";
		}
		else
		{
			isDraggingDoodly = false;
			doodlyText.text = "Alright, staying right here! What's next?";
			btnDoodlyMove.label.text = "Move";
		}
	}

	function onDoodlyResizeToggle()
	{
		doodlyInHelpMode = false;
		btnHelpPrev.visible = false;
		btnHelpNext.visible = false;

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
			doodlyText.text = "Nice size! Looks good to me.";
			btnDoodlyResize.label.text = "Resize";
		}
	}

	function endsWithStr(str:String, suffix:String):Bool
	{
		if (str == null || suffix == null || suffix.length > str.length) return false;
		return str.substr(str.length - suffix.length) == suffix;
	}

	function startsWithStr(str:String, prefix:String):Bool
	{
		if (str == null || prefix == null || prefix.length > str.length) return false;
		return str.substr(0, prefix.length) == prefix;
	}

	function getHeaderTitle():String
	{
		var dirtyMark = hasUnsavedChanges ? " *" : "";
		return 'Doodle Code Editor - $currentFileName$dirtyMark';
	}

	function getDefaultTemplate(lang:EditorLang):String
	{
		return switch (lang)
		{
			case HX:
				"import flixel.FlxG;\nimport states.PlayState;\n\nfunction onUpdate(elapsed:Float)\n{\n    \n}\n";
			case LUA:
				"-- Doodle Engine Lua Script\nfunction onCreate()\n    \nend\n";
			case JSON:
				"{\n    \"name\": \"custom_data\"\n}\n";
		};
	}

	function insertCodeSnippet()
	{
		var snippet = switch (currentLang)
		{
			case HX:
				"\nfunction onBeatHit()\n{\n    if (curBeat % 4 == 0) {\n        FlxTween.tween(camHUD, {zoom: 1.04}, 0.2, {ease: FlxEase.quadOut});\n    }\n}\n";
			case LUA:
				"\nfunction onBeatHit()\n    if curBeat % 4 == 0 then\n        doTweenAlpha('hudPulse', 'camHUD', 0.85, 0.25, 'quadOut')\n    end\nend\n";
			case JSON:
				",\n    \"bpm\": 140,\n    \"speed\": 2.4\n";
		};
		var updated = codeInput.text + snippet;
		codeInput.text = updated;
		lastCodeText = updated;
		hasUnsavedChanges = true;
		refreshEditorVisuals();
	}

	function clearEditorText()
	{
		codeInput.text = "";
		lastCodeText = "";
		hasUnsavedChanges = true;
		hideAutoComplete();
		refreshEditorVisuals();
	}

	function newFile(lang:EditorLang)
	{
		currentLang = lang;
		currentFileName = switch (lang)
		{
			case HX: "script.hx";
			case LUA: "script.lua";
			case JSON: "data.json";
		};
		var tpl = getDefaultTemplate(lang);
		codeInput.text = tpl;
		lastCodeText = tpl;
		hasUnsavedChanges = false;
		hideAutoComplete();
		refreshEditorVisuals();

		if (doodlyInHelpMode)
		{
			buildHelpPagesForLang();
			showCurrentHelpPage();
		}
	}

	function onCodeChanged()
	{
		hasUnsavedChanges = true;
		refreshEditorVisuals();
		if (autoCompleteEnabled)
			updateAutoComplete();
	}

	function refreshEditorVisuals()
	{
		titleText.text = getHeaderTitle();
		var lines = codeInput.text.split("\n");
		var nums:String = "";
		for (i in 0...lines.length)
		{
			nums += (i + 1) + "\n";
		}
		lineNumbersText.size = fontSize;
		lineNumbersText.text = nums;

		gutterBg.visible = showLineNumbers;
		lineNumbersText.visible = showLineNumbers;
		activeLineIndicator.visible = showLineNumbers;
		codeInput.x = showLineNumbers ? 74 : 16;
		codeInput.width = showLineNumbers ? (FlxG.width - 90) : (FlxG.width - 32);

		codeInput.size = fontSize;
		var langLabel = switch (currentLang)
		{
			case HX: "HScript (.hx)";
			case LUA: "Lua (.lua)";
			case JSON: "JSON (.json)";
		};
		statusText.text = 'Language: $langLabel | Lines: ${lines.length} | Chars: ${codeInput.text.length} | Font: ${fontSize}px | Ctrl+S: Save As';
	}

	function getCurrentWordPrefix():String
	{
		var lines = codeInput.text.split("\n");
		if (lines.length == 0) return "";
		var lastLine = lines[lines.length - 1];
		var regex = ~/([A-Za-z0-9_]+)$/;
		if (regex.match(lastLine))
			return regex.matched(1);
		return "";
	}

	function updateAutoComplete()
	{
		var prefix = getCurrentWordPrefix();
		if (prefix.length < 1)
		{
			hideAutoComplete();
			return;
		}

		var pool = switch (currentLang)
		{
			case HX: hxKeywords;
			case LUA: luaKeywords;
			case JSON: jsonKeywords;
		};

		suggestions = [];
		var lowerPrefix = prefix.toLowerCase();
		for (word in pool)
		{
			var lowerWord = word.toLowerCase();
			if (startsWithStr(lowerWord, lowerPrefix) && lowerWord != lowerPrefix)
			{
				suggestions.push(word);
			}
		}

		if (suggestions.length == 0)
		{
			hideAutoComplete();
			return;
		}

		if (acSelected >= suggestions.length)
			acSelected = 0;

		acVisible = true;

		var lines = codeInput.text.split("\n");
		var lineIdx = lines.length - 1;
		var colIdx = lines[lineIdx].length;

		var popupX = codeInput.x + Math.min(colIdx * (fontSize * 0.6), codeInput.width - 270);
		var popupY = Math.min(codeInput.y + (lineIdx + 1) * (fontSize + 4), FlxG.height - 230);

		var visibleCount = Std.int(Math.min(suggestions.length, maxAcVisible));
		acBox.setPosition(popupX, popupY);
		acBox.makeGraphic(250, visibleCount * 24 + 8, 0xFF252526);
		acBox.visible = true;

		for (i in 0...maxAcVisible)
		{
			var txt = acItems.members[i];
			if (i < visibleCount)
			{
				txt.text = suggestions[i];
				txt.setPosition(popupX + 6, popupY + 4 + (i * 24));
				txt.color = (i == acSelected) ? 0xFF3794FF : FlxColor.WHITE;
				txt.visible = true;
			}
			else
			{
				txt.visible = false;
			}
		}
	}

	function hideAutoComplete()
	{
		acVisible = false;
		acBox.visible = false;
		for (item in acItems.members)
			item.visible = false;
	}

	function applySuggestion(?index:Int)
	{
		if (!acVisible || suggestions.length == 0) return;
		var idx = (index != null) ? index : acSelected;
		if (idx < 0 || idx >= suggestions.length) return;

		var chosen = suggestions[idx];
		var prefix = getCurrentWordPrefix();

		if (endsWithStr(codeInput.text, prefix))
		{
			var updated = codeInput.text.substr(0, codeInput.text.length - prefix.length) + chosen;
			codeInput.text = updated;
			lastCodeText = updated;
			hasUnsavedChanges = true;
			refreshEditorVisuals();
		}
		hideAutoComplete();
	}

	function openFileDialog()
	{
		openFileRef = new FileReference();
		openFileRef.addEventListener(Event.SELECT, onFileSelected);
		openFileRef.browse([new FileFilter("Engine Scripts & Data", "*.hx;*.lua;*.json")]);
	}

	function onFileSelected(e:Event)
	{
		openFileRef.removeEventListener(Event.SELECT, onFileSelected);
		openFileRef.addEventListener(Event.COMPLETE, onFileLoaded);
		openFileRef.load();
	}

	function onFileLoaded(e:Event)
	{
		openFileRef.removeEventListener(Event.COMPLETE, onFileLoaded);
		currentFileName = openFileRef.name;
		var lowerName = currentFileName.toLowerCase();
		if (endsWithStr(lowerName, ".lua"))
			currentLang = LUA;
		else if (endsWithStr(lowerName, ".json"))
			currentLang = JSON;
		else
			currentLang = HX;

		var loadedText = Std.string(openFileRef.data);
		codeInput.text = loadedText;
		lastCodeText = loadedText;
		hasUnsavedChanges = false;
		hideAutoComplete();
		refreshEditorVisuals();
	}

	function saveFileDialog()
	{
		saveFileRef = new FileReference();
		saveFileRef.addEventListener(Event.COMPLETE, onFileSaved);
		saveFileRef.save(codeInput.text, currentFileName);
	}

	function onFileSaved(e:Event)
	{
		saveFileRef.removeEventListener(Event.COMPLETE, onFileSaved);
		hasUnsavedChanges = false;
		refreshEditorVisuals();
		statusText.text = 'Saved "$currentFileName" successfully!';
	}

	function insertTabSpaces()
	{
		var updated = codeInput.text + "    ";
		codeInput.text = updated;
		lastCodeText = updated;
		hasUnsavedChanges = true;
		refreshEditorVisuals();
	}

	function buildSettingsPanel()
	{
		var panelW:Int = 310;
		var panelH:Int = 330;
		var panelX:Float = FlxG.width - panelW - 14;
		var panelY:Float = 54;

		settingsPanel = new FlxSprite(panelX, panelY).makeGraphic(panelW, panelH, 0xFF2D2D30);
		settingsPanel.visible = false;
		add(settingsPanel);

		settingsTitle = new FlxText(panelX + 14, panelY + 10, panelW - 28, "EDITOR SETTINGS & TOOLS", 16);
		settingsTitle.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		settingsTitle.visible = false;
		add(settingsTitle);

		settingsGroup = new FlxTypedGroup<FlxButton>();
		add(settingsGroup);

		var btnW:Int = 134;
		var btnH:Int = 34;
		var leftColX:Float = panelX + 14;
		var rightColX:Float = panelX + 162;

		var bFontPlus = new FlxButton(leftColX, panelY + 42, "Font Size +", () -> {
			fontSize = Std.int(Math.min(32, fontSize + 2));
			refreshEditorVisuals();
		});
		bFontPlus.setGraphicSize(btnW, btnH);
		bFontPlus.updateHitbox();

		var bFontMinus = new FlxButton(rightColX, panelY + 42, "Font Size -", () -> {
			fontSize = Std.int(Math.max(12, fontSize - 2));
			refreshEditorVisuals();
		});
		bFontMinus.setGraphicSize(btnW, btnH);
		bFontMinus.updateHitbox();

		var bLineNums = new FlxButton(leftColX, panelY + 88, "Line Numbers", () -> {
			showLineNumbers = !showLineNumbers;
			refreshEditorVisuals();
		});
		bLineNums.setGraphicSize(btnW, btnH);
		bLineNums.updateHitbox();

		var bToggleAc = new FlxButton(rightColX, panelY + 88, "Autocomplete", () -> {
			autoCompleteEnabled = !autoCompleteEnabled;
			if (!autoCompleteEnabled) hideAutoComplete();
			refreshEditorVisuals();
		});
		bToggleAc.setGraphicSize(btnW, btnH);
		bToggleAc.updateHitbox();

		var bInsertTab = new FlxButton(leftColX, panelY + 134, "Insert 4 Spaces", insertTabSpaces);
		bInsertTab.setGraphicSize(btnW, btnH);
		bInsertTab.updateHitbox();

		var bSnippet = new FlxButton(rightColX, panelY + 134, "Insert Snippet", insertCodeSnippet);
		bSnippet.setGraphicSize(btnW, btnH);
		bSnippet.updateHitbox();

		var bToggleDoodly = new FlxButton(leftColX, panelY + 180, "Doodly Helper", () -> {
			doodlyVisibleEnabled = !doodlyVisibleEnabled;
			if (doodly != null) doodly.visible = doodlyVisibleEnabled;
			if (!doodlyVisibleEnabled) setDoodlyMenuState(false);
		});
		bToggleDoodly.setGraphicSize(btnW, btnH);
		bToggleDoodly.updateHitbox();

		var bClearText = new FlxButton(rightColX, panelY + 180, "Clear Code", clearEditorText);
		bClearText.setGraphicSize(btnW, btnH);
		bClearText.updateHitbox();

		var bResetDoodly = new FlxButton(leftColX, panelY + 226, "Reset Doodly", () -> {
			if (doodly != null)
			{
				doodly.setGraphicSize(110, 114);
				doodly.updateHitbox();
				doodly.setPosition(FlxG.width - 190, FlxG.height - 210);
				syncDoodlyUI();
			}
		});
		bResetDoodly.setGraphicSize(panelW - 28, btnH);
		bResetDoodly.updateHitbox();

		for (btn in [bFontPlus, bFontMinus, bLineNums, bToggleAc, bInsertTab, bSnippet, bToggleDoodly, bClearText, bResetDoodly])
		{
			btn.label.size = 13;
			btn.label.y += 4;
			btn.visible = false;
			settingsGroup.add(btn);
		}
	}

	function toggleSettings()
	{
		settingsOpen = !settingsOpen;
		settingsPanel.visible = settingsOpen;
		settingsTitle.visible = settingsOpen;
		for (btn in settingsGroup.members)
			btn.visible = settingsOpen;
	}

	function exitEditor()
	{
		FlxG.mouse.visible = false;
		MusicBeatState.switchState(new MainMenuState());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (doodlyTalkTimer > 0)
		{
			doodlyTalkTimer -= elapsed;
			if (doodlyTalkTimer <= 0 && doodly != null && doodly.animation != null && doodly.animation.getByName('idle') != null)
			{
				doodly.animation.play('idle');
			}
		}

		// Dragging or Resizing Doodly when active
		if (doodlyVisibleEnabled && doodly != null)
		{
			if (doodlyMoveMode)
			{
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(doodly))
				{
					isDraggingDoodly = true;
					dragOffsetX = FlxG.mouse.x - doodly.x;
					dragOffsetY = FlxG.mouse.y - doodly.y;
				}
				else if (FlxG.mouse.released)
				{
					isDraggingDoodly = false;
				}

				if (isDraggingDoodly)
				{
					doodly.x = FlxG.mouse.x - dragOffsetX;
					doodly.y = FlxG.mouse.y - dragOffsetY;
					syncDoodlyUI();
				}
			}
			else if (doodlyResizeMode)
			{
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(doodly))
				{
					isResizingDoodly = true;
					resizeStartMouseX = FlxG.mouse.x;
					resizeStartMouseY = FlxG.mouse.y;
					resizeStartWidth = doodly.width;
					resizeStartHeight = doodly.height;
				}
				else if (FlxG.mouse.released)
				{
					isResizingDoodly = false;
				}

				if (isResizingDoodly)
				{
					var deltaX = FlxG.mouse.x - resizeStartMouseX;
					var deltaY = FlxG.mouse.y - resizeStartMouseY;
					var deltaMax = (Math.abs(deltaX) > Math.abs(deltaY)) ? deltaX : deltaY;
					var newW = Math.max(55, Math.min(280, resizeStartWidth + deltaMax));
					var ratio = (resizeStartWidth > 0) ? (resizeStartHeight / resizeStartWidth) : 1.036;
					var newH = Math.max(57, Math.min(290, newW * ratio));

					doodly.setGraphicSize(Std.int(newW), Std.int(newH));
					doodly.updateHitbox();
					syncDoodlyUI();
				}
			}
			else if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(doodly))
			{
				setDoodlyMenuState(!doodlyMenuOpen);
				if (doodlyMenuOpen)
				{
					playDoodlyAnim('talk1', 2.0);
					doodlyText.text = "Hey! I'm Doodly! Pick Help, Joke, Move, or Resize.";
				}
			}
		}

		if (codeInput != null && codeInput.text != lastCodeText)
		{
			lastCodeText = codeInput.text;
			onCodeChanged();
		}

		if (acVisible)
		{
			var count = Std.int(Math.min(suggestions.length, maxAcVisible));
			var hoveredAny:Bool = false;

			for (i in 0...count)
			{
				var item = acItems.members[i];
				if (item != null && item.visible && FlxG.mouse.overlaps(item))
				{
					hoveredAny = true;
					if (acSelected != i)
					{
						acSelected = i;
						updateAutoComplete();
					}
					if (FlxG.mouse.justPressed)
					{
						applySuggestion(i);
						return;
					}
				}
			}

			if (FlxG.mouse.justPressed && !hoveredAny && !FlxG.mouse.overlaps(acBox))
			{
				hideAutoComplete();
			}

			if (FlxG.keys.justPressed.DOWN)
			{
				acSelected = (acSelected + 1) % count;
				updateAutoComplete();
			}
			else if (FlxG.keys.justPressed.UP)
			{
				acSelected = (acSelected - 1 + count) % count;
				updateAutoComplete();
			}
			else if (FlxG.keys.justPressed.TAB || FlxG.keys.justPressed.ENTER)
			{
				applySuggestion();
				return;
			}
			else if (FlxG.keys.justPressed.ESCAPE)
			{
				hideAutoComplete();
				return;
			}
		}
		else if (FlxG.keys.justPressed.ESCAPE)
		{
			if (doodlyMenuOpen)
				setDoodlyMenuState(false);
			else
				exitEditor();
		}

		// Shortcuts
		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.S)
				saveFileDialog();
			else if (FlxG.keys.justPressed.O)
				openFileDialog();
			else if (FlxG.keys.justPressed.N)
				newFile(currentLang);
		}
	}
}
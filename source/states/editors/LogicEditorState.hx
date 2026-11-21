package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxInputText;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.net.FileFilter;
import openfl.net.FileReference;

enum ScratchBlockKind
{
	CAUSE_SONG_TIME;
	CAUSE_BF_X;
	CAUSE_OPPONENT;
	CAUSE_HEALTH;
	CAUSE_BEAT;
	CAUSE_STEP;
	CAUSE_COMBO;
	CAUSE_MISSES;
	LOGIC_OR;
	LOGIC_ELSE;
	EFFECT_SCRIPT;
}

class VisualLogicBlock
{
	public var id:Int;
	public var kind:ScratchBlockKind;
	public var x:Float;
	public var y:Float;
	public var width:Int = 310;
	public var height:Int = 44;
	public var paramValue:String = "";
	public var scriptFile:String = "none (click Attach)";

	// Blueprint-style OUT -> IN connection (id of target block receiving output)
	public var nextBlockId:Int = -1;

	public function new(id:Int, kind:ScratchBlockKind, x:Float, y:Float)
	{
		this.id = id;
		this.kind = kind;
		this.x = x;
		this.y = y;
		this.paramValue = defaultParamFor(kind);
	}

	public function getInPinX():Float
	{
		return x;
	}

	public function getInPinY():Float
	{
		return y + height * 0.5;
	}

	public function getOutPinX():Float
	{
		return x + width;
	}

	public function getOutPinY():Float
	{
		return y + height * 0.5;
	}

	public static function defaultParamFor(kind:ScratchBlockKind):String
	{
		return switch (kind)
		{
			case CAUSE_SONG_TIME: "10.0";
			case CAUSE_BF_X: "770";
			case CAUSE_OPPONENT: "dad";
			case CAUSE_HEALTH: "0.5";
			case CAUSE_BEAT: "16";
			case CAUSE_STEP: "64";
			case CAUSE_COMBO: "10";
			case CAUSE_MISSES: "5";
			case LOGIC_OR: "curBeat >= 32";
			case LOGIC_ELSE: "fallback";
			case EFFECT_SCRIPT: "script";
		};
	}

	public static function colorFor(kind:ScratchBlockKind):Int
	{
		return switch (kind)
		{
			case CAUSE_SONG_TIME | CAUSE_BEAT | CAUSE_STEP: 0xFFFFAB19;
			case CAUSE_BF_X | CAUSE_OPPONENT | CAUSE_HEALTH | CAUSE_COMBO | CAUSE_MISSES: 0xFF4C97FF;
			case LOGIC_OR | LOGIC_ELSE: 0xFFFF8C1A;
			case EFFECT_SCRIPT: 0xFF9966FF;
		};
	}

	public function displayText():String
	{
		return switch (kind)
		{
			case CAUSE_SONG_TIME: 'when song time >= ${paramValue}s';
			case CAUSE_BF_X: 'when BF.x == ${paramValue}';
			case CAUSE_OPPONENT: 'when opponent == "${paramValue}"';
			case CAUSE_HEALTH: 'when health <= ${paramValue}';
			case CAUSE_BEAT: 'when curBeat >= ${paramValue}';
			case CAUSE_STEP: 'when curStep >= ${paramValue}';
			case CAUSE_COMBO: 'when combo >= ${paramValue}';
			case CAUSE_MISSES: 'when misses >= ${paramValue}';
			case LOGIC_OR: 'OR  (${paramValue})';
			case LOGIC_ELSE: 'ELSE  [${scriptFile}]';
			case EFFECT_SCRIPT: 'run script  [${scriptFile}]';
		};
	}

	public function toHaxeSnippet():String
	{
		var v = (paramValue == null || paramValue == "") ? "0" : paramValue;
		return switch (kind)
		{
			case CAUSE_SONG_TIME: 'if ((Conductor.songPosition / 1000) >= $v) {';
			case CAUSE_BF_X: 'if (PlayState.instance.boyfriend != null && PlayState.instance.boyfriend.x == $v) {';
			case CAUSE_OPPONENT: 'if (PlayState.instance.dad != null && PlayState.instance.dad.curCharacter == "$v") {';
			case CAUSE_HEALTH: 'if (PlayState.instance.health <= $v) {';
			case CAUSE_BEAT: 'if (PlayState.instance.curBeat >= $v) {';
			case CAUSE_STEP: 'if (PlayState.instance.curStep >= $v) {';
			case CAUSE_COMBO: 'if (PlayState.instance.combo >= $v) {';
			case CAUSE_MISSES: 'if (PlayState.instance.songMisses >= $v) {';
			case LOGIC_OR: 'if ($v) { // OR branch';
			case LOGIC_ELSE: '} else { // ELSE branch -> $scriptFile';
			case EFFECT_SCRIPT: '    // Execute attached script: $scriptFile';
		};
	}
}

class LogicEditorState extends MusicBeatState
{
	var paletteKinds:Array<ScratchBlockKind> = [
		CAUSE_SONG_TIME,
		CAUSE_BF_X,
		CAUSE_OPPONENT,
		CAUSE_HEALTH,
		CAUSE_BEAT,
		CAUSE_STEP,
		CAUSE_COMBO,
		CAUSE_MISSES,
		LOGIC_OR,
		LOGIC_ELSE,
		EFFECT_SCRIPT
	];

	var paletteBgs:Array<FlxSprite> = [];
	var paletteTexts:Array<FlxText> = [];

	var placedBlocks:Array<VisualLogicBlock> = [];
	var wiresGroup:FlxTypedGroup<FlxSprite>;
	var placedBgs:FlxTypedGroup<FlxSprite>;
	var placedNotches:FlxTypedGroup<FlxSprite>;
	var inPinsGroup:FlxTypedGroup<FlxSprite>;
	var outPinsGroup:FlxTypedGroup<FlxSprite>;
	var placedTexts:FlxTypedGroup<FlxText>;

	// Blueprint wire dragging state
	var wiringFromIndex:Int = -1;
	var tempWireSprite:FlxSprite;

	var selectedPlacedIndex:Int = -1;
	var draggingPlacedIndex:Int = -1;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;
	var nextBlockId:Int = 1;

	var paramInput:FlxInputText;
	var statusText:FlxText;

	var browseRef:FileReference;
	var exportRef:FileReference;

	// Doodly helper (Logic Editor + Blueprint wires Help)
	var doodly:FlxSprite;
	var doodlyBubble:FlxSprite;
	var doodlyText:FlxText;
	var doodlyMenuOpen:Bool = false;

	var doodlyMoveMode:Bool = false;
	var isDraggingDoodly:Bool = false;
	var doodlyDragOffsetX:Float = 0;
	var doodlyDragOffsetY:Float = 0;

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

	var doodlyHelpPages:Array<String> = [];
	var doodlyHelpPageIndex:Int = 0;
	var doodlyInHelpMode:Bool = false;
	var btnHelpPrev:FlxButton;
	var btnHelpNext:FlxButton;

	var doodlyJokes:Array<String> = [
		"Blueprint wires + Scratch blocks: like LEGO and node graphs had a baby!",
		"Drag from an OUT pin on the right to an IN pin on the left to wire blocks!",
		"An OR block walks into a bar... or a beat >= 16 triggers. Either works!",
		"Attaching a script to a block is like giving a node a superpower.",
		"If nothing happens in your song, check if your condition value ever becomes true!",
		"Click Unlink if a wire goes somewhere weird!",
		"Doodly's favorite block? The one that doesn't crash on frame 1.",
		"ELSE blocks are great for when your main plan decides to take a nap.",
		"Follow the wires from left to right to trace your logic flow!",
		"Exporting to .hx turns your wired blocks into real Doodle Engine code."
	];

	override function create()
	{
		FlxG.mouse.visible = true;
		FlxG.camera.bgColor = 0xFF1A1D24;

		// Top bar
		var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 46, 0xFF252A34);
		add(topBar);

		var title = new FlxText(14, 12, 230, "Doodle Logic Editor", 17);
		title.setFormat(Paths.font("vcr.ttf"), 17, FlxColor.WHITE, LEFT);
		add(title);

		paramInput = new FlxInputText(245, 10, 155, "", 14, FlxColor.WHITE, 0xFF14171D);
		paramInput.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(paramInput);

		var btnSetVal = new FlxButton(406, 10, "Set Value", applyParamToSelected);
		var btnAttach = new FlxButton(492, 10, "Attach Script", attachScriptToSelected);
		var btnUnlink = new FlxButton(578, 10, "Unlink", unlinkSelectedBlock);
		var btnDelete = new FlxButton(664, 10, "Delete Block", deleteSelectedBlock);
		var btnExport = new FlxButton(750, 10, "Export .hx", exportLogicHScript);
		var btnExit = new FlxButton(836, 10, "Exit", exitEditor);

		for (b in [btnSetVal, btnAttach, btnUnlink, btnDelete, btnExport, btnExit])
		{
			add(b);
		}

		// Left Scratch-like block palette
		var paletteWidth:Int = 270;
		var paletteBg = new FlxSprite(0, 46).makeGraphic(paletteWidth, FlxG.height - 74, 0xFF202530);
		add(paletteBg);

		var paletteHeader = new FlxText(10, 52, paletteWidth - 20, "BLOCK PALETTE (Click to add)", 13);
		paletteHeader.setFormat(Paths.font("vcr.ttf"), 13, 0xFF9FB3D9, LEFT);
		add(paletteHeader);

		buildPaletteBlocks();

		// Workspace area
		var canvasBg = new FlxSprite(paletteWidth, 46).makeGraphic(FlxG.width - paletteWidth, FlxG.height - 74, 0xFF161920);
		add(canvasBg);

		wiresGroup = new FlxTypedGroup<FlxSprite>();
		placedBgs = new FlxTypedGroup<FlxSprite>();
		placedNotches = new FlxTypedGroup<FlxSprite>();
		inPinsGroup = new FlxTypedGroup<FlxSprite>();
		outPinsGroup = new FlxTypedGroup<FlxSprite>();
		placedTexts = new FlxTypedGroup<FlxText>();

		add(wiresGroup);
		add(placedBgs);
		add(placedNotches);
		add(inPinsGroup);
		add(outPinsGroup);
		add(placedTexts);

		tempWireSprite = new FlxSprite(0, 0);
		tempWireSprite.visible = false;
		add(tempWireSprite);

		// Doodly helper
		buildDoodlyHelper();

		// Bottom status bar
		var bottomBar = new FlxSprite(0, FlxG.height - 28).makeGraphic(FlxG.width, 28, 0xFF007ACC);
		add(bottomBar);

		statusText = new FlxText(12, FlxG.height - 24, FlxG.width - 24, "Drag from OUT (right) pin to IN (left) pin to connect blocks!", 14);
		statusText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(statusText);

		refreshPlacedVisuals();
		super.create();
	}

	function buildPaletteBlocks()
	{
		var startY:Float = 76;
		var stepY:Float = 44;

		for (i in 0...paletteKinds.length)
		{
			var kind = paletteKinds[i];
			var y = startY + i * stepY;
			var temp = new VisualLogicBlock(0, kind, 10, y);

			var bg = new FlxSprite(10, y).makeGraphic(250, 36, VisualLogicBlock.colorFor(kind));
			add(bg);
			paletteBgs.push(bg);

			var notch = new FlxSprite(26, y + 34).makeGraphic(18, 5, VisualLogicBlock.colorFor(kind));
			add(notch);

			var label = new FlxText(16, y + 9, 238, temp.displayText(), 12);
			label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT);
			add(label);
			paletteTexts.push(label);
		}
	}

	function spawnBlockFromPalette(kind:ScratchBlockKind, dropX:Float, dropY:Float)
	{
		var clampedX = Math.max(296, Math.min(FlxG.width - 344, dropX));
		var clampedY = Math.max(56, Math.min(FlxG.height - 90, dropY));

		var block = new VisualLogicBlock(nextBlockId++, kind, clampedX, clampedY);
		placedBlocks.push(block);
		selectedPlacedIndex = placedBlocks.length - 1;
		paramInput.text = block.paramValue;
		refreshPlacedVisuals();
	}

	function findBlockById(id:Int):VisualLogicBlock
	{
		for (b in placedBlocks)
		{
			if (b.id == id) return b;
		}
		return null;
	}

	function drawWireSprite(targetSprite:FlxSprite, x1:Float, y1:Float, x2:Float, y2:Float, color:Int = 0xFF66FCF1)
	{
		var minX = Math.min(x1, x2);
		var minY = Math.min(y1, y2);
		var w:Int = Std.int(Math.max(4, Math.abs(x2 - x1) + 6));
		var h:Int = Std.int(Math.max(4, Math.abs(y2 - y1) + 6));

		var bd = new BitmapData(w, h, true, 0x00000000);
		var lx1 = x1 - minX + 3;
		var ly1 = y1 - minY + 3;
		var lx2 = x2 - minX + 3;
		var ly2 = y2 - minY + 3;

		var steps:Int = Std.int(Math.max(Math.abs(lx2 - lx1), Math.abs(ly2 - ly1)));
		if (steps < 1) steps = 1;
		for (s in 0...steps + 1)
		{
			var t:Float = s / steps;
			var px = Std.int(lx1 + (lx2 - lx1) * t);
			var py = Std.int(ly1 + (ly2 - ly1) * t);
			bd.fillRect(new Rectangle(px - 1, py - 1, 3, 3), color);
		}

		targetSprite.loadGraphic(bd);
		targetSprite.setPosition(minX - 3, minY - 3);
		targetSprite.visible = true;
	}

	function refreshPlacedVisuals()
	{
		wiresGroup.clear();
		placedBgs.clear();
		placedNotches.clear();
		inPinsGroup.clear();
		outPinsGroup.clear();
		placedTexts.clear();

		for (i in 0...placedBlocks.length)
		{
			var b = placedBlocks[i];
			b.x = Math.max(296, Math.min(FlxG.width - b.width - 28, b.x));
			b.y = Math.max(54, Math.min(FlxG.height - b.height - 34, b.y));

			// Draw connected wire to next block
			if (b.nextBlockId != -1)
			{
				var target = findBlockById(b.nextBlockId);
				if (target != null)
				{
					var wire = new FlxSprite(0, 0);
					drawWireSprite(wire, b.getOutPinX(), b.getOutPinY(), target.getInPinX(), target.getInPinY(), 0xFF66FCF1);
					wiresGroup.add(wire);
				}
				else
				{
					b.nextBlockId = -1;
				}
			}
		}

		for (i in 0...placedBlocks.length)
		{
			var b = placedBlocks[i];
			var col = VisualLogicBlock.colorFor(b.kind);

			var card = new FlxSprite(b.x, b.y).makeGraphic(b.width, b.height, col);
			placedBgs.add(card);

			var notch = new FlxSprite(b.x + 18, b.y + b.height - 1).makeGraphic(20, 6, col);
			placedNotches.add(notch);

			// Left IN pin & Right OUT pin (Blueprint style)
			var inPin = new FlxSprite(b.getInPinX() - 7, b.getInPinY() - 7).makeGraphic(14, 14, 0xFF2ECC71);
			var outPin = new FlxSprite(b.getOutPinX() - 7, b.getOutPinY() - 7).makeGraphic(14, 14, 0xFFE74C3C);
			inPinsGroup.add(inPin);
			outPinsGroup.add(outPin);

			var linkInfo = (b.nextBlockId != -1) ? ' [->#${b.nextBlockId}]' : '';
			var prefix = (i == selectedPlacedIndex) ? "[SEL] " : "";
			var txt = new FlxText(b.x + 12, b.y + 8, b.width - 24, prefix + b.displayText() + linkInfo, 12);
			txt.setFormat(Paths.font("vcr.ttf"), 12, (i == selectedPlacedIndex) ? 0xFFFFF59D : FlxColor.WHITE, LEFT);
			placedTexts.add(txt);
		}

		if (selectedPlacedIndex >= 0 && selectedPlacedIndex < placedBlocks.length)
		{
			var sel = placedBlocks[selectedPlacedIndex];
			statusText.text = 'Selected #${sel.id}: ${sel.displayText()} | OUT->${sel.nextBlockId} | Drag RED OUT to GREEN IN';
		}
		else
		{
			statusText.text = 'Total Blocks: ${placedBlocks.length} | Drag RED OUT pin to GREEN IN pin to wire blocks';
		}
	}

	function applyParamToSelected()
	{
		if (selectedPlacedIndex < 0 || selectedPlacedIndex >= placedBlocks.length) return;
		placedBlocks[selectedPlacedIndex].paramValue = paramInput.text;
		refreshPlacedVisuals();
	}

	function unlinkSelectedBlock()
	{
		if (selectedPlacedIndex < 0 || selectedPlacedIndex >= placedBlocks.length) return;
		var selId = placedBlocks[selectedPlacedIndex].id;
		placedBlocks[selectedPlacedIndex].nextBlockId = -1;
		for (b in placedBlocks)
		{
			if (b.nextBlockId == selId)
				b.nextBlockId = -1;
		}
		refreshPlacedVisuals();
	}

	function deleteSelectedBlock()
	{
		if (selectedPlacedIndex < 0 || selectedPlacedIndex >= placedBlocks.length) return;
		var removedId = placedBlocks[selectedPlacedIndex].id;
		placedBlocks.splice(selectedPlacedIndex, 1);

		for (b in placedBlocks)
		{
			if (b.nextBlockId == removedId)
				b.nextBlockId = -1;
		}

		if (placedBlocks.length == 0)
			selectedPlacedIndex = -1;
		else if (selectedPlacedIndex >= placedBlocks.length)
			selectedPlacedIndex = placedBlocks.length - 1;

		refreshPlacedVisuals();
	}

	function attachScriptToSelected()
	{
		if (selectedPlacedIndex < 0 || selectedPlacedIndex >= placedBlocks.length) return;
		browseRef = new FileReference();
		browseRef.addEventListener(Event.SELECT, onScriptPicked);
		browseRef.browse([new FileFilter("Scripts", "*.hx;*.lua")]);
	}

	function onScriptPicked(e:Event)
	{
		browseRef.removeEventListener(Event.SELECT, onScriptPicked);
		if (selectedPlacedIndex < 0 || selectedPlacedIndex >= placedBlocks.length) return;
		placedBlocks[selectedPlacedIndex].scriptFile = browseRef.name;
		refreshPlacedVisuals();
	}

	function exportLogicHScript()
	{
		var code = "// Generated by Doodle Logic Editor (Scratch + Blueprint Wires)\n";
		code += "import states.PlayState;\n";
		code += "import backend.Conductor;\n\n";
		code += "function onUpdate(elapsed:Float)\n{\n";
		code += "    if (PlayState.instance == null) return;\n\n";

		// Determine root blocks (not targeted as nextBlockId by another block)
		var targetedIds:Array<Int> = [];
		for (b in placedBlocks)
		{
			if (b.nextBlockId != -1)
				targetedIds.push(b.nextBlockId);
		}

		var roots:Array<VisualLogicBlock> = [];
		for (b in placedBlocks)
		{
			if (targetedIds.indexOf(b.id) == -1)
				roots.push(b);
		}
		if (roots.length == 0 && placedBlocks.length > 0)
			roots.push(placedBlocks[0]);

		var visited:Array<Int> = [];
		for (root in roots)
		{
			var cur:VisualLogicBlock = root;
			while (cur != null && visited.indexOf(cur.id) == -1)
			{
				visited.push(cur.id);
				code += '    ${cur.toHaxeSnippet()}\n';
				cur = (cur.nextBlockId != -1) ? findBlockById(cur.nextBlockId) : null;
			}
		}

		code += "}\n";

		exportRef = new FileReference();
		exportRef.save(code, "logic_blueprint.hx");
		statusText.text = "Exported logic_blueprint.hx";
	}

	// Doodly setup with Logic Editor + Wires help pages
	function buildDoodlyHelper()
	{
		doodly = new FlxSprite(FlxG.width - 150, FlxG.height - 175);
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
			doodly.makeGraphic(110, 114, FlxColor.WHITE);
		}
		doodly.setGraphicSize(100, 104);
		doodly.updateHitbox();
		add(doodly);

		doodlyBubble = new FlxSprite(0, 0).makeGraphic(390, 154, 0xFFFFFBE6);
		doodlyBubble.visible = false;
		add(doodlyBubble);

		doodlyText = new FlxText(0, 0, 372, "Hey! Need Logic Editor help, a joke, or want to move/resize me?", 13);
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

		buildLogicHelpPages();
		syncDoodlyUI();
	}

	function buildLogicHelpPages()
	{
		doodlyHelpPages = [
			"[LOGIC EDITOR 1/4 - PALETTE & WIRES]\nClick any block on the left palette to place it on the canvas.\nEach block has a GREEN IN pin (left) and a RED OUT pin (right).\nDrag from a RED OUT pin to a GREEN IN pin to connect blocks with a wire!",
			"[LOGIC EDITOR 2/4 - CAUSE BLOCKS]\nCause blocks check gameplay conditions like:\n- Song time (seconds), curBeat, curStep\n- BF.x position, opponent character, health\n- Combo and misses during the song.",
			"[LOGIC EDITOR 3/4 - OR, ELSE & UNLINK]\nUse OR blocks for extra conditions and ELSE blocks for alternative branches.\nSelect a block, edit its value at the top, and click Set Value.\nClick Unlink to remove wires connected to the selected block.",
			"[LOGIC EDITOR 4/4 - ATTACH SCRIPTS & EXPORT]\nSelect a block and click Attach Script to pick a .hx or .lua file.\nClick Export .hx to generate HScript following your wired block chain!"
		];
		doodlyHelpPageIndex = 0;
	}

	function showCurrentHelpPage()
	{
		if (doodlyHelpPages.length == 0)
			buildLogicHelpPages();
		doodlyInHelpMode = true;
		playDoodlyAnim('talk1', 3.5);
		doodlyText.text = doodlyHelpPages[doodlyHelpPageIndex];
		btnHelpPrev.visible = doodlyMenuOpen && doodlyInHelpMode;
		btnHelpNext.visible = doodlyMenuOpen && doodlyInHelpMode;
		syncDoodlyUI();
	}

	function onDoodlyHelp()
	{
		buildLogicHelpPages();
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
		doodlyText.text = doodlyJokes[FlxG.random.int(0, doodlyJokes.length - 1)];
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
			doodlyText.text = "Got it! Staying right here.";
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
			doodlyText.text = "Resize mode ON! Drag on me to resize, then click Lock Size.";
			btnDoodlyResize.label.text = "Lock Size";
		}
		else
		{
			isResizingDoodly = false;
			doodlyText.text = "Nice size! Looks great.";
			btnDoodlyResize.label.text = "Resize";
		}
	}

	function syncDoodlyUI()
	{
		if (doodly == null) return;
		doodly.width = Math.max(55, Math.min(260, doodly.width));
		doodly.height = Math.max(57, Math.min(270, doodly.height));
		doodly.x = Math.max(290, Math.min(FlxG.width - doodly.width - 10, doodly.x));
		doodly.y = Math.max(52, Math.min(FlxG.height - doodly.height - 34, doodly.y));

		var bx = Math.max(290, Math.min(FlxG.width - doodlyBubble.width - 10, doodly.x - 160));
		var by = doodly.y - doodlyBubble.height - 54;
		if (by < 52)
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

	function exitEditor()
	{
		FlxG.mouse.visible = false;
		MusicBeatState.switchState(new MasterEditorMenu());
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

		// Doodly drag / resize / click menu
		if (doodly != null)
		{
			if (doodlyMoveMode)
			{
				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(doodly))
				{
					isDraggingDoodly = true;
					doodlyDragOffsetX = FlxG.mouse.x - doodly.x;
					doodlyDragOffsetY = FlxG.mouse.y - doodly.y;
				}
				else if (FlxG.mouse.released)
				{
					isDraggingDoodly = false;
				}

				if (isDraggingDoodly)
				{
					doodly.x = FlxG.mouse.x - doodlyDragOffsetX;
					doodly.y = FlxG.mouse.y - doodlyDragOffsetY;
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
					var dx = FlxG.mouse.x - resizeStartMouseX;
					var dy = FlxG.mouse.y - resizeStartMouseY;
					var delta = (Math.abs(dx) > Math.abs(dy)) ? dx : dy;
					var newW = Math.max(55, Math.min(260, resizeStartWidth + delta));
					var ratio = (resizeStartWidth > 0) ? (resizeStartHeight / resizeStartWidth) : 1.04;
					var newH = Math.max(57, Math.min(270, newW * ratio));
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
					doodlyText.text = "Hey! I'm Doodly! Need Logic Editor Help, a Joke, Move, or Resize?";
				}
			}
		}

		// Start wiring from OUT pin or dragging/selecting a block
		if (FlxG.mouse.justPressed)
		{
			var handledCanvas:Bool = false;

			// 1. Check OUT pins first so wiring doesn't conflict with block dragging
			for (i in 0...outPinsGroup.length)
			{
				var pin = outPinsGroup.members[i];
				if (pin != null && FlxG.mouse.overlaps(pin) && i < placedBlocks.length)
				{
					wiringFromIndex = i;
					selectedPlacedIndex = i;
					paramInput.text = placedBlocks[i].paramValue;
					handledCanvas = true;
					refreshPlacedVisuals();
					break;
				}
			}

			// 2. Otherwise check placed block cards
			if (!handledCanvas)
			{
				for (i in 0...placedBgs.length)
				{
					var bg = placedBgs.members[i];
					if (bg != null && FlxG.mouse.overlaps(bg) && i < placedBlocks.length)
					{
						selectedPlacedIndex = i;
						draggingPlacedIndex = i;
						dragOffsetX = FlxG.mouse.x - placedBlocks[i].x;
						dragOffsetY = FlxG.mouse.y - placedBlocks[i].y;
						paramInput.text = placedBlocks[i].paramValue;
						handledCanvas = true;
						refreshPlacedVisuals();
						break;
					}
				}
			}

			// 3. Otherwise spawn block when clicking a palette block
			if (!handledCanvas)
			{
				for (i in 0...paletteBgs.length)
				{
					if (FlxG.mouse.overlaps(paletteBgs[i]))
					{
						spawnBlockFromPalette(paletteKinds[i], FlxG.mouse.x + 50, FlxG.mouse.y);
						break;
					}
				}
			}
		}

		// Active wire dragging from OUT pin to IN pin
		if (wiringFromIndex >= 0 && wiringFromIndex < placedBlocks.length)
		{
			if (FlxG.mouse.pressed)
			{
				var src = placedBlocks[wiringFromIndex];
				drawWireSprite(tempWireSprite, src.getOutPinX(), src.getOutPinY(), FlxG.mouse.x, FlxG.mouse.y, 0xFFFFD166);
			}
			else
			{
				tempWireSprite.visible = false;
				var srcBlock = placedBlocks[wiringFromIndex];
				for (j in 0...inPinsGroup.length)
				{
					var inPin = inPinsGroup.members[j];
					if (inPin != null && FlxG.mouse.overlaps(inPin) && j < placedBlocks.length && j != wiringFromIndex)
					{
						srcBlock.nextBlockId = placedBlocks[j].id;
						break;
					}
				}
				wiringFromIndex = -1;
				refreshPlacedVisuals();
			}
		}

		// Active block dragging
		if (draggingPlacedIndex >= 0 && draggingPlacedIndex < placedBlocks.length)
		{
			if (FlxG.mouse.pressed)
			{
				var blk = placedBlocks[draggingPlacedIndex];
				blk.x = FlxG.mouse.x - dragOffsetX;
				blk.y = FlxG.mouse.y - dragOffsetY;
				refreshPlacedVisuals();
			}
			else
			{
				draggingPlacedIndex = -1;
				refreshPlacedVisuals();
			}
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (doodlyMenuOpen)
				setDoodlyMenuState(false);
			else
				exitEditor();
		}
	}
}
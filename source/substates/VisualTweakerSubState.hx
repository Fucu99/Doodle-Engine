package substates;

import flixel.FlxSubState;
import flixel.util.FlxSpriteUtil;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.Json;

class VisualTweakerSubState extends MusicBeatSubstate
{
	var bgPanel:FlxSprite;
	var titleText:FlxText;
	var infoText:FlxText;
	var hintText:FlxText;
	var darkBg:FlxSprite;

	var targetElements:Array<FlxSprite> = [];
	var currentIndex:Int = 0;
	var currentSelected:FlxSprite;

	var moveSpeed:Float = 1.0;

	override function create()
	{
		super.create();

		darkBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		darkBg.alpha = 0.4;
		darkBg.scrollFactor.set();
		add(darkBg);

		var panelWidth:Int = Std.int(FlxG.width * 0.85);
		var panelHeight:Int = Std.int(FlxG.height * 0.75);
		
		bgPanel = FlxSpriteUtil.drawRoundRect(new FlxSprite(0, 0).makeGraphic(panelWidth, panelHeight, FlxColor.TRANSPARENT), 0, 0, panelWidth, panelHeight, 16, 16, FlxColor.BLACK);
		bgPanel.alpha = 0.85;
		bgPanel.scrollFactor.set();
		bgPanel.screenCenter();
		add(bgPanel);

		gatherUIElements();

		titleText = new FlxText(bgPanel.x + 25, bgPanel.y + 20, panelWidth - 50, "Visual Tweaker (Per-Song HUD Editor)", 16);
		titleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		titleText.scrollFactor.set();
		add(titleText);

		infoText = new FlxText(bgPanel.x + 25, titleText.y + 40, panelWidth - 50, "", 12);
		infoText.setFormat(Paths.font("vcr.ttf"), 12, 0xCCCCCC, LEFT);
		infoText.scrollFactor.set();
		add(infoText);

		hintText = new FlxText(bgPanel.x + 25, bgPanel.y + panelHeight - 35, panelWidth - 50, "[TAB] Target | [ARROWS] Move | [S] Save All Tweaks | [F6/ESC] Close", 11);
		hintText.setFormat(Paths.font("vcr.ttf"), 11, FlxColor.GRAY, LEFT);
		hintText.scrollFactor.set();
		add(hintText);

		updateInfo();
	}

	function gatherUIElements()
	{
		targetElements = [];
		
		FlxG.state.forEachOfType(FlxSprite, function(sprite:FlxSprite) {
			if (sprite != bgPanel && sprite != darkBg)
			{
				targetElements.push(sprite);
			}
		});

		if (targetElements.length > 0)
		{
			currentIndex = 0;
			currentSelected = targetElements[0];
		}
	}

	function updateInfo()
	{
		if (targetElements.length > 0 && currentSelected != null)
		{
			var objType = Type.getClassName(Type.getClass(currentSelected));
			infoText.text = "Target (" + (currentIndex + 1) + "/" + targetElements.length + "): " + objType + "\n"
				+ "Position X: " + Math.round(currentSelected.x) + " | Y: " + Math.round(currentSelected.y) + "\n"
				+ "Scale X: " + (Math.round(currentSelected.scale.x * 100) / 100) + " | Scale Y: " + (Math.round(currentSelected.scale.y * 100) / 100) + "\n\n"
				+ "Press [S] to save all tweaks to song folder.";
		}
		else
		{
			infoText.text = "No interactive UI elements found in this state.";
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		moveSpeed = FlxG.keys.pressed.SHIFT ? 10.0 : 1.0;

		if (FlxG.keys.justPressed.TAB && targetElements.length > 0)
		{
			currentIndex = (currentIndex + 1) % targetElements.length;
			currentSelected = targetElements[currentIndex];
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if (currentSelected != null)
		{
			if (FlxG.keys.pressed.LEFT) currentSelected.x -= moveSpeed;
			if (FlxG.keys.pressed.RIGHT) currentSelected.x += moveSpeed;
			if (FlxG.keys.pressed.UP) currentSelected.y -= moveSpeed;
			if (FlxG.keys.pressed.DOWN) currentSelected.y += moveSpeed;

			if (FlxG.keys.justPressed.PLUS || FlxG.keys.justPressed.NUMPADPLUS)
			{
				currentSelected.scale.x += 0.1;
				currentSelected.scale.y += 0.1;
			}
			if (FlxG.keys.justPressed.MINUS || FlxG.keys.justPressed.NUMPADMINUS)
			{
				currentSelected.scale.x = Math.max(0.1, currentSelected.scale.x - 0.1);
				currentSelected.scale.y = Math.max(0.1, currentSelected.scale.y - 0.1);
			}
		}

		if (FlxG.keys.justPressed.S)
		{
			saveSongTweaks();
		}

		updateInfo();

		if (FlxG.keys.justPressed.F6 || FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}
	}

	function saveSongTweaks()
	{
		#if sys
		if (PlayState.SONG != null)
		{
			var songName:String = PlayState.SONG.song.toLowerCase();
			var folderPath:String = "mods/data/" + songName + "/";

			if (!FileSystem.exists(folderPath))
			{
				FileSystem.createDirectory(folderPath);
			}

			var filePath:String = folderPath + "ui-tweaks.json";

			// Creiamo un array o mappa di oggetti salvati basato sulla classe/indice
			var tweaksMap:Map<String, Dynamic> = new Map<String, Dynamic>();
			
			for (i in 0...targetElements.length)
			{
				var spr = targetElements[i];
				if (spr != null)
				{
					var key = Type.getClassName(Type.getClass(spr)) + "_" + i;
					tweaksMap.set(key, {
						x: spr.x,
						y: spr.y,
						scaleX: spr.scale.x,
						scaleY: spr.scale.y
					});
				}
			}

			// Convertiamo la mappa in un oggetto anonimo per la serializzazione JSON
			var jsonObj:Dynamic = {};
			for (key => val in tweaksMap)
			{
				Reflect.setField(jsonObj, key, val);
			}

			try
			{
				File.saveContent(filePath, Json.stringify(jsonObj, "\t"));
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);
				titleText.text = "Visual Tweaker [SAVED SUCCESSFULLY]";
			}
			catch (e:Dynamic)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.8);
				titleText.text = "Visual Tweaker [ERROR SAVING]";
			}
		}
		else
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.8);
			infoText.text = "Error: Not currently in a song.";
		}
		#end
	}
}
package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class MainMenuState extends MusicBeatState
{
	var optionShit:Array<String> = ['story mode', 'freeplay', 'options', 'credits'];
	var grpButtons:FlxTypedGroup<FlxText>;
	var curSelected:Int = 0;
	
	var logoBl:FlxSprite;
	var checkerPattern:FlxSprite;

	override function create()
	{
		super.create();

		// Assicura che la musica del menù stia suonando
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
		}

		// 1. Sfondo base del menù
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.color = 0xFF9000FF;
		bg.setGraphicSize(Std.int(bg.width * 1.18));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
		// 2. Checkerboard Pattern SOPRA lo sfondo base ma SOTTO l'interfaccia (UI)
		checkerPattern = new FlxSprite().loadGraphic(Paths.image('menuDesat')); // Cambia 'menuDesat' con l'immagine della tua scacchiera se ha un altro nome
		checkerPattern.antialiasing = ClientPrefs.data.antialiasing;
		checkerPattern.scrollFactor.set(0, 0);
		checkerPattern.alpha = 0.65; // Opacità al 65%
		add(checkerPattern);

		// 3. UI: Opzioni posizionate a SINISTRA
		grpButtons = new FlxTypedGroup<FlxText>();
		add(grpButtons);

		for (i in 0...optionShit.length)
		{
			var optionText:FlxText = new FlxText(90, 180 + (i * 90), 0, optionShit[i], 36);
			optionText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			optionText.borderSize = 3;
			optionText.ID = i;
			grpButtons.add(optionText);
		}

		// 4. UI: Logo posizionato a DESTRA con animazione
		logoBl = new FlxSprite(580, 100);
		logoBl.loadGraphic(Paths.image('logo'));
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.8));
		logoBl.updateHitbox();
		add(logoBl);

		changeSelection(0);
	}

	override function update(elapsed:Float)
	{
		if (checkerPattern != null)
		{
			// Fa scorrere il pattern in diagonale
			checkerPattern.x -= 20 * elapsed;
			checkerPattern.y -= 20 * elapsed;
		}
		
		super.update(elapsed);

		if (controls.UI_UP_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(1);
		}

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));

			switch (optionShit[curSelected])
			{
				case 'story mode':
					MusicBeatState.switchState(new StoryMenuState());
				case 'freeplay':
					MusicBeatState.switchState(mikolka.vslice.freeplay.FreeplayState.build());
				case 'options':
					MusicBeatState.switchState(new options.OptionsState());
				case 'credits':
					MusicBeatState.switchState(new CreditsState());
			}
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = optionShit.length - 1;
		if (curSelected >= optionShit.length) curSelected = 0;

		for (item in grpButtons.members)
		{
			if (item.ID == curSelected)
			{
				item.color = FlxColor.YELLOW;
				item.scale.set(1.1, 1.1);
			}
			else
			{
				item.color = FlxColor.WHITE;
				item.scale.set(1.0, 1.0);
			}
		}
	}

	// Effetto Bumping del logo a tempo di musica
	override function beatHit()
	{
		super.beatHit();

		if (logoBl != null)
		{
			logoBl.scale.set(0.85, 0.85);
			FlxTween.cancelTweensOf(logoBl);
			FlxTween.tween(logoBl.scale, {x: 0.8, y: 0.8}, 0.2, {ease: FlxEase.quadOut});
		}
	}
}
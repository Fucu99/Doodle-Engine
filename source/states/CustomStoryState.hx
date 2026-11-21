package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.Paths;
import backend.ClientPrefs;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import haxe.Json;

class CustomStoryState extends MusicBeatState
{
	// Lista di esempio delle week (puoi regolarla in base alle tue week esistenti)
	var weekList:Array<String> = ['tutorial', 'week1', 'week2', 'week3', 'week4', 'week5', 'week6']; 
	var curSelected:Int = 0;
	var curDifficulty:Int = 1; // 0 = Easy, 1 = Normal, 2 = Hard
	var difficulties:Array<String> = ['EASY', 'NORMAL', 'HARD'];

	// UI Elements
	var albumArtwork:FlxSprite;
	var weekCharacter:FlxSprite;
	var songsText:FlxText;
	var grpWeekList:FlxTypedGroup<FlxText>;

	override function create()
	{
		super.create();

		// Sfondo nero generale della schermata
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		// 1. IN ALTO A SINISTRA: Artwork dell'album
		albumArtwork = new FlxSprite(50, 40);
		add(albumArtwork);

		// 2. IN ALTO A DESTRA: Character della week
		weekCharacter = new FlxSprite(FlxG.width - 450, 40);
		weekCharacter.setGraphicSize(400, 400);
		weekCharacter.updateHitbox();
		add(weekCharacter);

		// 3. IN BASSO A SINISTRA: Lista canzoni e difficoltà
		songsText = new FlxText(50, 420, 600, "", 28);
		songsText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(songsText);

		// 4. IN BASSO A DESTRA: Lista scorrevole delle Week
		grpWeekList = new FlxTypedGroup<FlxText>();
		add(grpWeekList);

		for (i in 0...weekList.length)
		{
			var weekItem:FlxText = new FlxText(FlxG.width - 450, 450 + (i * 45), 400, weekList[i].toUpperCase(), 32);
			weekItem.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.GRAY, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			weekItem.ID = i;
			grpWeekList.add(weekItem);
		}

		updateSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected = FlxMath.wrap(curSelected - 1, 0, weekList.length - 1);
			updateSelection();
		}
		if (controls.UI_DOWN_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curSelected = FlxMath.wrap(curSelected + 1, 0, weekList.length - 1);
			updateSelection();
		}

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curDifficulty += (controls.UI_LEFT_P ? -1 : 1);
			if (curDifficulty < 0) curDifficulty = difficulties.length - 1;
			if (curDifficulty >= difficulties.length) curDifficulty = 0;
			updateSongsDisplay();
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function updateSelection()
	{
		// Aggiorna l'evidenziazione della lista a destra
		for (item in grpWeekList.members)
		{
			if (item.ID == curSelected)
			{
				item.alpha = 1;
				item.color = FlxColor.WHITE;
			}
			else
			{
				item.alpha = 0.5;
				item.color = FlxColor.GRAY;
			}
		}

		// Caricamento Dinamico Album ID dal metadata.json della prima canzone
		var currentWeekName = weekList[curSelected];
		var albumToLoad = "volume2"; // Fallback di sicurezza

		try
		{
			// Legge i dati della week o recupera la prima canzone associata
			// (Adattato sullo standard del motore per leggere il metadata della prima traccia)
			var firstSongPath = getFirstSongOfCurrentWeek(currentWeekName);
			var jsonPath = Paths.getTextFromFile('songs/' + firstSongPath + '/metadata.json');
			if (jsonPath != null)
			{
				var parsedJson:Dynamic = Json.parse(jsonPath);
				if (parsedJson.albumId != null)
				{
					albumToLoad = parsedJson.albumId;
				}
			}
		}
		catch (e:Dynamic)
		{
			trace("Impossibile caricare il metadata, uso l'album di default.");
		}

		// Carica l'immagine dell'album dal percorso esatto: assets/shared/images/freeplay/albumRoll/
		var albumGraphic = Paths.image('freeplay/albumRoll/' + albumToLoad);
		if (albumGraphic != null)
		{
			albumArtwork.loadGraphic(albumGraphic);
		}
		else
		{
			albumArtwork.loadGraphic(Paths.image('freeplay/albumRoll/volume2')); // Fallback
		}
		albumArtwork.setGraphicSize(350, 350);
		albumArtwork.updateHitbox();

		updateSongsDisplay();
	}

	function updateSongsDisplay()
	{
		var diffStr = difficulties[curDifficulty];
		var songListString = "Songs:\n< " + diffStr + " >\n";
		
		// Ottimizzato per mostrare le tracce della week corrente
		var dummySongs = getSongsForWeek(weekList[curSelected]);
		for (song in dummySongs)
		{
			songListString += "- " + song + "\n";
		}
		songsText.text = songListString;
	}

	function getFirstSongOfCurrentWeek(weekName:String):String
	{
		// Restituisce la prima canzone della week (personalizzabile in base alla tua lista brani)
		switch(weekName)
		{
			case 'tutorial': return 'tutorial';
			case 'week1': return 'bopeebo';
			case 'week2': return 'spookeez';
			case 'week3': return 'pico';
			case 'week4': return 'satin-panties';
			case 'week5': return 'cocoa';
			case 'week6': return 'senpai';
			default: return 'bopeebo';
		}
	}

	function getSongsForWeek(weekName:String):Array<String>
	{
		switch(weekName)
		{
			case 'tutorial': return ['Tutorial'];
			case 'week1': return ['Bopeebo', 'Fresh', 'Dadbattle'];
			case 'week2': return ['Spookeez', 'South', 'Monster'];
			case 'week3': return ['Pico', 'Blammed', 'Philly Nice'];
			case 'week4': return ['Satin Panties', 'High', 'M.I.L.F'];
			case 'week5': return ['Cocoa', 'Eggnog', 'Winter Horrorland'];
			case 'week6': return ['Senpai', 'Roses', 'Thorns'];
			default: return ['Song One', 'Song Two'];
		}
	}
}
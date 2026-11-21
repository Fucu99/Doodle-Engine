package substates;

import flixel.FlxSubState;
import flixel.util.FlxSpriteUtil;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;

import states.MainMenuState;
import states.FreeplayState;
import states.CreditsState;
import options.OptionsState;

class ModDebugConsoleSubState extends MusicBeatSubstate
{
	var bgPanel:FlxSprite;
	var consoleText:FlxText;
	var titleText:FlxText;
	var hintText:FlxText;
	var darkBg:FlxSprite;
	
	var currentInput:String = "";
	var timeAlive:Float = 0;

	public static var logs:Array<String> = [];

	public static function log(text:String)
	{
		logs.push(text);
		if (logs.length > 35) logs.shift(); // Aumentato lo storico a 35 righe
	}

	override function create()
	{
		super.create();
		timeAlive = 0;
		currentInput = "";

		if (logs.length == 0)
		{
			log("Doodle Engine Debug Console initialized.");
			log("1 - Type 'help' or 'help 2' to see all commands.");
			log("2 - WARNING: Highly experimental/buggy feature!");
			log("--------------------------------------------------\n");
		}

		darkBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		darkBg.alpha = 0.5;
		darkBg.scrollFactor.set();
		add(darkBg);

		var panelWidth:Int = Std.int(FlxG.width * 0.85);
		var panelHeight:Int = Std.int(FlxG.height * 0.8);
		
		bgPanel = FlxSpriteUtil.drawRoundRect(new FlxSprite(0, 0).makeGraphic(panelWidth, panelHeight, FlxColor.TRANSPARENT), 0, 0, panelWidth, panelHeight, 16, 16, FlxColor.BLACK);
		bgPanel.alpha = 0.9;
		bgPanel.scrollFactor.set();
		bgPanel.screenCenter();
		add(bgPanel);

		titleText = new FlxText(bgPanel.x + 25, bgPanel.y + 20, panelWidth - 50, "Console [Interactive Debugger]", 16);
		titleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		titleText.scrollFactor.set();
		add(titleText);

		hintText = new FlxText(bgPanel.x + 25, bgPanel.y + panelHeight - 35, panelWidth - 50, "Type command & press [ENTER] | [F4] to close", 12);
		hintText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, LEFT);
		hintText.scrollFactor.set();
		add(hintText);

		consoleText = new FlxText(bgPanel.x + 25, titleText.y + 35, panelWidth - 50, "", 11);
		consoleText.setFormat(Paths.font("vcr.ttf"), 11, 0xCCCCCC, LEFT);
		consoleText.scrollFactor.set();
		updateLogDisplay();
		add(consoleText);

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('NONE', 'B');
		#end
	}

	function updateLogDisplay()
	{
		var displayText = "";
		for (logMsg in logs)
		{
			displayText += "> " + logMsg + "\n";
		}
		
		displayText += "\n> " + currentInput + "_";
		consoleText.text = displayText;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		timeAlive += elapsed;

		if (FlxG.keys.justPressed.BACKSPACE && currentInput.length > 0)
		{
			currentInput = currentInput.substr(0, currentInput.length - 1);
			updateLogDisplay();
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			var cmd:String = currentInput;
			while (cmd.length > 0 && cmd.charAt(0) == " ") cmd = cmd.substr(1);
			while (cmd.length > 0 && cmd.charAt(cmd.length - 1) == " ") cmd = cmd.substr(0, cmd.length - 1);

			if (cmd.length > 0)
			{
				log(cmd);
				processCommand(cmd);
				currentInput = "";
			}
			updateLogDisplay();
		}
		else
		{
			var key:FlxKey = FlxG.keys.firstJustPressed();
			if (key != FlxKey.NONE)
			{
				var char:String = getKeyChar(key);
				if (char != "")
				{
					currentInput += char;
					updateLogDisplay();
				}
			}
		}

		if (timeAlive > 0.1 && (FlxG.keys.justPressed.F4 || FlxG.keys.justPressed.ESCAPE))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}
	}

	function getKeyChar(key:FlxKey):String
	{
		switch (key)
		{
			case FlxKey.ZERO, FlxKey.NUMPADZERO: return "0";
			case FlxKey.ONE, FlxKey.NUMPADONE: return "1";
			case FlxKey.TWO, FlxKey.NUMPADTWO: return "2";
			case FlxKey.THREE, FlxKey.NUMPADTHREE: return "3";
			case FlxKey.FOUR, FlxKey.NUMPADFOUR: return "4";
			case FlxKey.FIVE, FlxKey.NUMPADFIVE: return "5";
			case FlxKey.SIX, FlxKey.NUMPADSIX: return "6";
			case FlxKey.SEVEN, FlxKey.NUMPADSEVEN: return "7";
			case FlxKey.EIGHT, FlxKey.NUMPADEIGHT: return "8";
			case FlxKey.NINE, FlxKey.NUMPADNINE: return "9";
			case FlxKey.SPACE: return " ";
			case FlxKey.PERIOD, FlxKey.NUMPADPERIOD: return ".";
			case FlxKey.MINUS, FlxKey.NUMPADMINUS: return "-";
			default:
				var keyName:String = Std.string(key);
				if (keyName.length == 1)
				{
					return FlxG.keys.pressed.SHIFT ? keyName.toUpperCase() : keyName.toLowerCase();
				}
		}
		return "";
	}

	function processCommand(cmd:String)
	{
		var args:Array<String> = cmd.toLowerCase().split(" ");
		var mainCmd:String = args[0];
		var subArg:String = args.length > 1 ? args[1] : "";

		switch (mainCmd)
		{
			case "help":
				if (subArg == "2")
				{
					log("=== HELP PAGE 2/2 ===");
					log("fullscreen - Toggle fullscreen mode");
					log("mute / unmute - Control master audio");
					log("zoom [val] - Set camera zoom (e.g. zoom 1.5)");
					log("resetzoom - Reset camera zoom to 1.0");
					log("shake [dur] [int] - Shake camera");
					log("flash [color] - Flash screen (red/blue/green)");
					log("gravity [val] - Set gravity factor");
					log("echo [text] - Print custom text");
					log("ping, sayhi, author, matrix, potato");
				}
				else
				{
					log("=== HELP PAGE 1/2 (Type 'help 2' for more) ===");
					log("help - Shows command list");
					log("clear - Clears console logs");
					log("reload - Reloads current state");
					log("exit - Closes the console");
					log("menu / freeplay / credits / options - Switch menus");
					log("play [song] - Start a song instantly");
					log("volume [0-100] - Set master volume");
					log("speed [val] - Set game time scale");
					log("framerate [val] - Set FPS limit");
					log("info - Show engine & memory stats");
				}

			case "clear":
				logs = [];

			case "reload":
				log("Reloading current state...");
				FlxG.resetState();

			case "exit":
				close();

			case "menu":
				log("Redirecting to Main Menu...");
				MusicBeatState.switchState(new MainMenuState());

			case "freeplay":
				log("Redirecting to Freeplay State...");
				MusicBeatState.switchState(new FreeplayState());

			case "credits":
				log("Redirecting to Credits...");
				MusicBeatState.switchState(new CreditsState());

			case "options":
				log("Redirecting to Options...");
				MusicBeatState.switchState(new OptionsState());

			case "play":
				if (subArg == "")
				{
					log("Usage: play [song_name]");
				}
				else
				{
					var songName:String = subArg;
					songName = songName.charAt(0).toUpperCase() + songName.substr(1);
					log("Attempting to load song: " + songName);
					try
					{
						PlayState.SONG = backend.Song.loadFromJson(songName.toLowerCase(), songName.toLowerCase());
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = 1;
						MusicBeatState.switchState(new PlayState());
					}
					catch (e:Dynamic)
					{
						log("Error: Could not find song '" + songName + "'!");
					}
				}

			case "volume":
				if (subArg != "")
				{
					var vol:Float = Std.parseFloat(subArg);
					if (!Math.isNaN(vol))
					{
						FlxG.sound.volume = Math.max(0, Math.min(100, vol)) / 100;
						log("Volume set to: " + Std.int(FlxG.sound.volume * 100) + "%");
					}
				}
				else log("Volume: " + Std.int(FlxG.sound.volume * 100) + "%");

			case "speed":
				if (subArg != "")
				{
					var spd:Float = Std.parseFloat(subArg);
					if (!Math.isNaN(spd) && spd > 0)
					{
						FlxG.timeScale = spd;
						log("Time scale set to: " + spd + "x");
					}
				}
				else log("Time scale: " + FlxG.timeScale + "x");

			case "framerate":
				if (subArg != "")
				{
					var fpsVal:Int = Std.parseInt(subArg);
					if (fpsVal > 0)
					{
						FlxG.updateFramerate = fpsVal;
						FlxG.drawFramerate = fpsVal;
						log("Framerate limit set to: " + fpsVal);
					}
				}
				else log("Current Framerate: " + FlxG.drawFramerate);

			case "info":
				log("Engine: Doodle Engine | Res: " + FlxG.width + "x" + FlxG.height);
				log("RAM: " + Std.int(openfl.system.System.totalMemory / 1024 / 1024) + " MB");

			case "fullscreen":
				FlxG.fullscreen = !FlxG.fullscreen;
				log("Fullscreen toggled: " + FlxG.fullscreen);

			case "mute":
				FlxG.sound.muted = true;
				log("Master audio muted.");

			case "unmute":
				FlxG.sound.muted = false;
				log("Master audio unmuted.");

			case "zoom":
				if (subArg != "")
				{
					var z:Float = Std.parseFloat(subArg);
					if (!Math.isNaN(z) && z > 0)
					{
						FlxG.camera.zoom = z;
						log("Camera zoom set to: " + z);
					}
				}
				else log("Current zoom: " + FlxG.camera.zoom);

			case "resetzoom":
				FlxG.camera.zoom = 1;
				log("Camera zoom reset to 1.0");

			case "shake":
				var duration:Float = args.length > 1 ? Std.parseFloat(args[1]) : 0.5;
				var intensity:Float = args.length > 2 ? Std.parseFloat(args[2]) : 0.02;
				FlxG.camera.shake(intensity, duration);
				log("Screen shaken! (Duration: " + duration + "s)");

			case "flash":
				var color:FlxColor = FlxColor.WHITE;
				if (subArg == "red") color = FlxColor.RED;
				else if (subArg == "blue") color = FlxColor.BLUE;
				else if (subArg == "green") color = FlxColor.GREEN;
				FlxG.camera.flash(color, 0.5);
				log("Screen flashed!");

			case "time":
				log("Elapsed time on state: " + Math.round(MusicBeatState.timePassedOnState) + "s");

			case "gravity":
				if (subArg != "") log("Gravity factor set to: " + subArg);
				else log("Gravity command ready.");

			case "kill":
				log("fuck");

			case "suicide":
				log("no");

			case "echo":
				if (args.length > 1)
				{
					log("ECHO: " + cmd.substr(5));
				}
				else log("Usage: echo [your_text]");

			case "sayhi":
				log("hi! are we ready? i don't think so bye");

			case "ping":
				log("pong");

			case "author":
				log("Doodle Engine made by Fucu99");

			case "potato":
				log("potato mode activated");
				log("absolutely nothing happened");

			case "matrix":
				log("bip bop.");

			case "rickroll":
				log("Never gonna give you up, never gonna let you down~");
				
			case "furry":
				log("nyaaaa :3");
				
			case "ifuckingwanttokillyou":
				log("never gonna give you up never gonna let you down");

			default:
				log("Unknown command: '" + mainCmd + "'. Type 'help' for commands.");
		}
	}
}
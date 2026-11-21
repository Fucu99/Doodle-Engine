package options;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.vslice.components.crash.UserErrorSubstate;
import backend.StageData;
import flixel.FlxObject;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay',
		'Accessibilities',
		'P-Slice Options',
		'V-Slice Options',
		'Doodle Engine Options',
		#if TRANSLATIONS_ALLOWED  'Language', #end
		#if (TOUCH_CONTROLS_ALLOWED || mobile)'Mobile Options' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private static var curSelectedPartial:Float = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	var exiting:Bool = false;

	private var mainCam:FlxCamera;
	public static var funnyCam:FlxCamera;
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo")
			funnyCam.visible = persistentUpdate = false;

		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				if (controls.mobileC)
				{
					funnyCam.visible = persistentUpdate = true;
					UserErrorSubstate.makeMessage("Unsupported controls", 
					"You don't need to go there on mobile!\n\nIf you wish to go there anyway\nSet 'Mobile Controls Opacity' to 0%");
				}
				else
					openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Accessibilities':
				openSubState(new AccessibilitiesSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'P-Slice Options':
				openSubState(new PSliceSubState());
			case 'V-Slice Options':
				openSubState(new VSliceSubState());
			case 'Doodle Engine Options':
				openSubState(new DoodleSettingsSubState());
			#if (TOUCH_CONTROLS_ALLOWED || mobile)
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
			#end
			#if TRANSLATIONS_ALLOWED
			case 'Language':
				openSubState(new options.LanguageSubState());
			#end
		}
	}

	override function create()
	{
		mainCam = initPsychCamera();
		funnyCam = new FlxCamera();
		funnyCam.bgColor.alpha = 0;
		FlxG.cameras.add(funnyCam, false);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.cameras.list[FlxG.cameras.list.indexOf(funnyCam)].follow(camFollowPos);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.screenCenter();
			optionText.x -= MobileScaleMode.gameCutoutSize.x / 2;
			optionText.y += (92 * (num - (options.length / 2))) + 45;
			optionText.cameras = [funnyCam];
			grpOptions.add(optionText);
		}

		changeSelection(0,true);
		ClientPrefs.saveSettings();

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'A_B');

		var button = new TouchZone(90,270,FlxG.width,100,FlxColor.PURPLE);
		
		var scroll = new ScrollableObject(-0.01,100,0,FlxG.width-200,FlxG.height,button);
		scroll.onPartialScroll.add(delta -> changeSelection(delta,false));
        scroll.onFullScrollSnap.add(() ->changeSelection(0,true));
		scroll.onTap.add(() ->{
			openSelectedSubstate(options[curSelected]);
		});
		add(scroll);
		add(button);
		#end
		
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		controls.isInSubstate = false;
		persistentUpdate = funnyCam.visible = true;
		
		#if TOUCH_CONTROLS_ALLOWED
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B');
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if(exiting) return;

		if (controls.UI_UP_P){
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(-1,true);
		}
		if (controls.UI_DOWN_P){
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeSelection(1,true);
		}

		var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));
		camFollowPos.setPosition(635, FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			exiting = false;
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(delta:Float,usePrecision:Bool = false) {
		if(usePrecision) {
			if(delta != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curSelected =  FlxMath.wrap(curSelected + Std.int(delta), 0, options.length - 1);
			curSelectedPartial = curSelected;
		}
		else {
			curSelectedPartial = FlxMath.bound(curSelectedPartial + delta, 0, options.length - 1);
			if(curSelected != Math.round(curSelectedPartial)) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curSelected = Math.round(curSelectedPartial);
		}
		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelectedPartial;
			item.alpha = 0.6;
			if (num == curSelected)
			{
				item.alpha = 1;
				var thing:Float = grpOptions.members.length > 6 ? grpOptions.members.length * 2 : 0;
				var partialDiff = (curSelectedPartial-curSelected);
				if(partialDiff > 0 && grpOptions.length > curSelected+1){
					var nextItem = grpOptions.members[curSelected+1];
					var camY = FlxMath.lerp(item.y,nextItem.y,partialDiff);
					camFollow.setPosition(635, camY + 100 - thing);
				}
				else if(partialDiff < 0 && 0 <= curSelected-1) {
					 var prevItem = grpOptions.members[curSelected-1];
					 var camY = FlxMath.lerp(prevItem.y,item.y,1+partialDiff);
					 camFollow.setPosition(635, camY + 100 - thing);
				}
				else camFollow.setPosition(635, item.y + 100 - thing);
			}
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}

class DoodleSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Doodle Engine Options';
		rpcTitle = 'Doodle Engine Options Menu';

		var option1:Option = new Option(
			'Doodle Engine Notes',
			'If disabled, turns off global automatic note coloring.',
			'doodleNotes',
			BOOL
		);
		option1.onChange = () -> ClientPrefs.saveSettings();
		addOption(option1);

		var option2:Option = new Option(
			'Doodle Engine Camera Move',
			'If disabled, turns off the global dynamic camera movement script.',
			'doodleCamMove',
			BOOL
		);
		addOption(option2);

		var option3:Option = new Option(
			'Doodle Engine Strums',
			'If disabled, turns off global automatic strum line coloring.',
			'doodleStrums',
			BOOL
		);
		option3.onChange = () -> ClientPrefs.saveSettings();
		addOption(option3);

		var optionCamStrength:Option = new Option(
			'Camera Move Strength',
			'Changes the intensity/strength of the dynamic camera movement.',
			'doodleCamStrength',
			FLOAT
		);
		optionCamStrength.minValue = 1.0;
		optionCamStrength.maxValue = 100.0;
		optionCamStrength.changeValue = 1.0;
		optionCamStrength.displayFormat = '%v';
		optionCamStrength.decimals = 0;
		addOption(optionCamStrength);

		var optionFullscreen:Option = new Option(
			'Fullscreen',
			'If enabled, puts the game in fullscreen mode.',
			'fullscreen',
			BOOL
		);
		optionFullscreen.onChange = onChangeFullscreen;
		addOption(optionFullscreen);
		
		var optionHandCam:Option = new Option(
			'HandCam',
			'If enabled, adds a realistic handheld camera sway during gameplay.',
			'doodleHandCam',
			BOOL
		);
		optionHandCam.onChange = () -> ClientPrefs.saveSettings();
		addOption(optionHandCam);

		super();
	}

	function onChangeFullscreen()
	{
		FlxG.fullscreen = ClientPrefs.data.fullscreen;
	}
}

class AccessibilitiesSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Accessibilities';
		rpcTitle = 'Accessibilities Options Menu';

		var optHighContrast:Option = new Option(
			'High Contrast Notes',
			'Boosts note outline and brightness contrast against busy backgrounds.',
			'accHighContrastNotes',
			BOOL
		);
		optHighContrast.onChange = () -> ClientPrefs.saveSettings();
		addOption(optHighContrast);

		var optLaneDividers:Option = new Option(
			'Lane Guide Columns',
			'Draws subtle vertical separators between each receptor lane.',
			'accLaneDividers',
			BOOL
		);
		optLaneDividers.onChange = () -> ClientPrefs.saveSettings();
		addOption(optLaneDividers);

		var optDimBg:Option = new Option(
			'Background Dim',
			'Darkens the stage background to improve note readability.',
			'accDimBackground',
			PERCENT
		);
		optDimBg.minValue = 0.0;
		optDimBg.maxValue = 0.9;
		optDimBg.changeValue = 0.05;
		optDimBg.decimals = 2;
		optDimBg.onChange = () -> ClientPrefs.saveSettings();
		addOption(optDimBg);

		var optNoCamShake:Option = new Option(
			'Disable Camera Shake',
			'Prevents sudden screen shake effects from charts and events.',
			'accDisableCameraShake',
			BOOL
		);
		optNoCamShake.onChange = () -> ClientPrefs.saveSettings();
		addOption(optNoCamShake);

		var optNoCamZoom:Option = new Option(
			'Disable Beat Zoom',
			'Locks camera zoom pulsing on beats to reduce motion sickness.',
			'accDisableCameraZoom',
			BOOL
		);
		optNoCamZoom.onChange = () -> ClientPrefs.saveSettings();
		addOption(optNoCamZoom);

		var optOneHanded:Option = new Option(
			'One-Handed Layout Preset',
			'Optimizes input handling for single-hand keyboard play.',
			'accOneHandedMode',
			BOOL
		);
		optOneHanded.onChange = () -> ClientPrefs.saveSettings();
		addOption(optOneHanded);

		var optPauseFocus:Option = new Option(
			'Auto-Pause on Focus Loss',
			'Automatically pauses gameplay when switching away from the window.',
			'accPauseOnFocusLost',
			BOOL
		);
		optPauseFocus.onChange = () -> ClientPrefs.saveSettings();
		addOption(optPauseFocus);

		super();
	}
}
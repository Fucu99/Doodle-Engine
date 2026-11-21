package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;

class FreeplayState extends FlxState {
    
    var waveformBars:Array<FlxSprite> = [];
    var numBars:Int = 16;

    override function create() {
        // 1. Carica la schermata originale di P-Slice
        FlxG.switchState(mikolka.vslice.freeplay.FreeplayState.build());

        // 2. Aggiunge le nostre barre del waveform in basso
        var startX = (FlxG.width - (numBars * 18)) / 2;
        for (i in 0...numBars) {
            var bar = new FlxSprite(startX + (i * 18), FlxG.height - 35).makeGraphic(10, 4, FlxColor.CYAN);
            bar.scrollFactor.set();
            bar.alpha = 0.8;
            bar.origin.y = bar.height;
            add(bar);
            waveformBars.push(bar);
        }

        super.create();
    }

    override function update(elapsed:Float) {
        // Controlla se premi ESC o BACKSPACE per tornare al nostro CustomMenuState
        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new states.MainMenuState());
            return;
        }

        // Anima le barre a tempo di musica se la musica del menu sta suonando
        if (FlxG.sound.music != null) {
            var time = FlxG.sound.music.time / 1000;
            for (i in 0...waveformBars.length) {
                var bar = waveformBars[i];
                var wave = Math.sin(time * 8 + (i * 0.4)) * 0.5 + 0.5;
                var targetHeight = (wave * 35) + 5;
                bar.scale.y = FlxMath.lerp(bar.scale.y, targetHeight, elapsed * 12);
            }
        }
        super.update(elapsed);
    }
}
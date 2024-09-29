library;

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:tekartik_audio_web/src/audio_kit.dart';
import 'package:tekartik_audio_web/src/audio_manager_web.dart';
import 'package:tekartik_audio_web/src/player/player.dart';
import 'package:tekartik_audio_web/src/sequencer/pattern.dart';
import 'package:tekartik_audio_web/src/sequencer/sequencer.dart';
import 'package:tekartik_audio_web/src/sequencer/song.dart';
import 'package:tekartik_test_menu_browser/test_menu_mdl_browser.dart';

var audioManager = AudioManagerWeb();
final audioContext = audioManager.audioContext;

Future main() async {
  await initMenuBrowser(); //js: ['test_menu.js']);

  var assetsTop = 'packages/tekartik_audio_web_app/assets';
  menu('main', () {
    item('write hola', () async {
      write('Hola');
      //write('RESULT prompt: ${await prompt()}');
    });
    item('prompt', () async {
      write('RESULT prompt: ${await prompt('Some text please then [ENTER]')}');
    });
    item('print hi', () {
      print('hi');
    });
    item('can play', () {
      void canPlay(AudioFormatType type) {
        write(
            '${audioFormatInformation[type]} can play ${audioManager.testCanPlayFormatType(type)}');
      }

      canPlay(AudioFormatType.mp3);
      canPlay(AudioFormatType.ogg);

      void canPlayRaw(String type) {
        write('$type can play ${audioManager.testCanPlayRawFormatType(type)}');
        // ignore: invalid_use_of_visible_for_testing_member
        write('Result ${canPlayTypeRawResult(type)}');
      }

      canPlayRaw('audio/wav');
      canPlayRaw('audio/dummy');
      canPlayRaw('audio/mp3');
      canPlayRaw('audio/ogg');
    });
    menu('audio_sample', () {
      item('tac', () async {
        var audioSample = AudioSample(audioContext);
        await audioSample.load('$assetsTop/audio/tac.ogg', true);
        audioSample.noteOn(audioContext.destination, audioContext.currentTime);
      });

      item('tac then tic', () async {
        var audioSample = AudioSample(audioContext);
        var ticAudioSample = AudioSample(audioContext);
        await audioSample.load('$assetsTop/audio/tac.ogg', true);
        await ticAudioSample.load('$assetsTop/audio/tic.ogg', true);
        audioSample.noteOn(audioContext.destination, audioContext.currentTime);
        ticAudioSample.noteOn(
            audioContext.destination, audioContext.currentTime + .2);
      });
    });

    menu('player_init', () {
      Player? player;
      item('init', () async {
        player = Player();
        player!.defUrl = '$assetsTop/audio/drumkit.json';
        await player!.init();
        write('player inited');
      });

      leave(() {
        write('stopping player');
        player?.stop();
      });
      item('simple', () async {
        player = Player();
        player!.defUrl = '$assetsTop/audio/drumkit.json';
        await player!.init();
        write('player inited');
        player!.song = Song()
          ..pattern = (Pattern()
            ..fromMap({
              'instruments': ['tic', 'tac'],
              'steps': [
                [100, 0],
                [0, 100]
              ]
            }));
        player!.start();
      });
    });

    Song getTicTacSong() => Song()
      ..pattern = (Pattern()
        ..fromMap({
          'instruments': ['tic', 'tac'],
          'steps': [
            [100, 0],
            [0, 100]
          ]
        }));

    Song getTicTacTacSong() => Song()
      ..pattern = (Pattern()
        ..fromMap({
          'instruments': ['tic', 'tac'],
          'steps': [
            [100, 0, 0],
            [0, 100, 100],
          ]
        }));

    menu('player', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      // ignore: deprecated_member_use
      Player.debug.on = true;

      Player? player;
      Future init() async {
        if (player == null) {
          player = Player();
          player!.defUrl = '$assetsTop/audio/drumkit.json';
          await player!.init();
          player!.song = getTicTacSong();
        }
      }

      item('start', () async {
        await init();
        player!.start();
      });

      item('stop', () async {
        await init();
        player!.stop();
      });

      item('waltz', () async {
        await init();
        player!.song = getTicTacTacSong();
      });

      item('two_steps', () async {
        await init();
        player!.song = getTicTacSong();
      });

      item('tempo++', () async {
        await init();
        player!.tempo *= 1.2;
      });

      item('tempo--', () async {
        await init();
        player!.tempo /= 1.2;
      });
    });

    menu('audio_kit', () {
      item('load', () async {
        var audioKit = AudioKit();
        await audioKit.loadKit(audioContext, '$assetsTop/audio/drumkit.json');
        write('audioKit loaded ${audioKit.kitUrl}');
      });
    });
  });
}
//import '
/*
Future main() async {
  await initTestMenuBrowser(js: ['test_menu.js']);

  item('write hola', () async {
    write('Hola');
    //write('RESULT prompt: ${await prompt()}');
  });
  item('prompt', () async {
    write('RESULT prompt: ${await prompt('Some text please then [ENTER]')}');
  });
  item('js console.log', () {
    jsTest('testConsoleLog');
  });
  item('crash', () {
    throw 'Hi';
  });
  menu('sub', () {
    item('write hi', () => write('hi'));
  });
}
*/

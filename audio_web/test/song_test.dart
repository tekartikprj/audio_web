import 'dart:core' hide Pattern;

import 'package:tekartik_audio_web/src/instrument.dart';
import 'package:tekartik_audio_web/src/sequencer/pattern.dart';
import 'package:tekartik_audio_web/src/sequencer/song.dart';
import 'package:tekartik_audio_web/src/sequencer/steps_group.dart';
import 'package:test/test.dart';

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

void main() {
  group('song', () {
    Song getSimpleTestSong1() => Song()
      /*
      ..pattern = new Pattern()
      pattern.instrumentNames = [ Instrument.BASS_DRUM, Instrument.SNARE_DRUM ];
      pattern.beats = [ [ 1, 0 ], [ 0, 1 ] ];
      var song = new Song();
      */
      //..tempo = 30
      ..pattern = (Pattern()
        ..instruments = [bassDrumInstrument, snareDrumInstrument]
        ..steps = StepsGroup.fromList([
          [100, 0],
          [0, 100]
        ]));

    test('info', () {
      var song = getSimpleTestSong1();
      //expect(song.beatDuration, equals(0.5));
      equals(2, song.stepCount);
      equals(1, song.pattern!.beatStepCount);
      expect(song.getStepDurationWithTempo(30), closeTo(2.0, 0.00001));
      //equals(30, song.tempo);
    });
  });
}

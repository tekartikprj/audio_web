import 'dart:core' hide Pattern;

import 'package:tekartik_audio_web/src/instrument.dart';
import 'package:tekartik_audio_web/src/sequencer/pattern.dart';
import 'package:tekartik_audio_web/src/sequencer/steps_group.dart';
import 'package:test/test.dart';

void main() {
  Pattern getPattern1() {
    return Pattern.fromJsonString('''{
      "instruments": ["bd", "sn"],
      "steps": [[100, 0, 0, 0],[0, 0, 100, 0]]
    }''');
  }

  Pattern getPattern2() {
    return Pattern.fromJsonString('''{
      "instruments": ["bd", "sn", "rim", "chh", "ohh", "htom", "mtom", "ltom", "splash", "ride"],
      "steps": [[100, 0, 0, 100, 0, 100, 0, 0, 100, 0, 0, 0, 100, 100, 0, 0],[0, 0, 100, 0, 0, 0, 100, 0, 0, 0, 100, 50, 0, 0, 100, 0],[25,18,21,17,25,18,21,17,25,18,21,17,25,18,21,17]]
    }''');
  }

  // All data
  Pattern getPattern3() {
    return Pattern.fromJsonString('''{
      "instruments": ["bd", "sn"],
      "beatStepCount": 3,
      "steps": [[100, 0, 0, 0],[0, 0, 100, 0]]
    }''');
  }

  // For beat step count
  Pattern getPattern4() {
    return Pattern()
      ..instruments = [bassDrumInstrument]
      ..steps = StepsGroup.fromList([
        [100, 75, 50, 25]
      ])
      ..beatStepCount = 2;
  }

  /*
  // For beat step count
  Pattern getPatternTicTac() {
    return new Pattern()
      ..fromMap({
        "instruments": ["tic", "tac"],
        "steps": [
          [100, 0],
          [0, 100]
        ]
      });
  }
  */

  group('pattern', () {
    test('beat_one', () {
      var pattern = (Pattern()
        ..instruments = [bassDrumInstrument, snareDrumInstrument]
        ..steps = StepsGroup.fromList([
          [100, 0],
          [0, 100]
        ]));
      expect(pattern.stepCount, 2);
      expect(pattern.beatStepCount, 1);
    });

    test('beat_2', () {
      var pattern = (Pattern()
        ..instruments = [bassDrumInstrument, snareDrumInstrument]
        ..steps = StepsGroup.fromList([
          [100, 0, 0, 0],
          [0, 0, 100, 0]
        ])
        ..beatStepCount = 2);
      expect(pattern.stepCount, 4);
      expect(pattern.beatStepCount, 2);
    });
    test('Json', () {
      var pattern = getPattern1();
      expect(4, pattern.stepCount);
      expect(1, pattern.beatStepCount);
      expect(100, pattern.steps![1][2]);
      expect(bassDrumInstrument, pattern.instruments![0]);

      pattern = getPattern3();
      expect(4, pattern.stepCount);
      expect(3, pattern.beatStepCount);
      expect(100, pattern.steps![1][2]);
      expect(bassDrumInstrument, pattern.instruments![0]);

      var export = pattern.toMap();
      pattern = Pattern();
      pattern.fromMap(export);
      expect(3, pattern.beatStepCount);
      expect(100, pattern.steps![1][2]);
      expect(bassDrumInstrument, pattern.instruments![0]);

      pattern = getPattern2();
      expect(16, pattern.stepCount);
      expect(100, pattern.steps![1][2]);
      expect(bassDrumInstrument, pattern.instruments![0]);
    });

    test('Update step count', () {
      var pattern = getPattern1();
      expect(4, pattern.stepCount);
      expect(100, pattern.steps![1][2]);
      expect(bassDrumInstrument, pattern.instruments![0]);

      pattern.stepCount = 5;
      expect(5, pattern.stepCount);
      expect(0, pattern.steps![1][4]);
    });

    test('Update beat step count', () {
      var pattern = getPattern4();
      expect(2, pattern.beatStepCount);
      expect(4, pattern.stepCount);
      expect(100, pattern.steps![0][0]);
      expect(75, pattern.steps![0][1]);
      expect(50, pattern.steps![0][2]);
      expect(25, pattern.steps![0][3]);

      pattern.changeBeatStepCount(3);
      expect(3, pattern.beatStepCount);
      expect(6, pattern.stepCount);
      expect(100, pattern.steps![0][0]);
      expect(0, pattern.steps![0][1]);
      expect(75, pattern.steps![0][2]);
      expect(50, pattern.steps![0][3]);
      expect(0, pattern.steps![0][4]);
      expect(25, pattern.steps![0][5]);

      pattern.changeBeatStepCount(4);
      expect(4, pattern.beatStepCount);
      expect(8, pattern.stepCount);
      expect(100, pattern.steps![0][0]);
      expect(0, pattern.steps![0][1]);

      // TODO expect(75, pattern.steps[0][2]);
      /*
      expect(50, pattern.steps[0][3]);
      expect(0, pattern.steps[0][4]);
      expect(0, pattern.steps[0][5]);
      */
    });

    test('toMapFromMap', () {
      // Empty
      var pattern = Pattern();
      var map = pattern.toMap();
      pattern.fromMap(map);
    });

    test('changeStep', () {
      // Empty
      var pattern = getPattern1();
      expect(4, pattern.stepCount);
      expect(1, pattern.beatStepCount);
      expect(100, pattern.steps![1][2]);

      var map = pattern.toMap();
      ((map[Pattern.stepsKey] as List)[1] as List)[2] = 75;
      expect(75, pattern.steps![1][2]);
    });
  });
}

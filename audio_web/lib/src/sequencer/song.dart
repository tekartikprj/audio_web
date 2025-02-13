import 'dart:core' hide Pattern;

import 'package:tekartik_audio_web/src/sequencer/pattern.dart';

class Song {
  // double tempo = 120.0; // bpm
  Pattern? pattern;

  int get stepCount {
    return pattern!.stepCount;
  }

  //Assume beat is a sixteenth
  // duration in seconds
  @Deprecated('Use getStepDurationWithTempo')
  double getBeatDurationWithTempo(num bpm) => getStepDurationWithTempo(bpm);

  double getStepDurationWithTempo(num bpm) {
    return 60.0 / (pattern!.beatStepCount * bpm);
  }

  double getPatternDurationWithTempo(num bpm) {
    return getStepDurationWithTempo(bpm) * stepCount;
  }

  /*
  double getBeatDuration() {
    return Song.getBeatDurationWithTempo(tempo);
  }
  */
  int get instrumentCount => pattern!.instruments!.length;

  @override
  String toString() {
    return '$stepCount steps';
  }
}

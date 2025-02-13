import 'dart:core' hide Pattern;

import 'package:tekartik_audio_web/src/import.dart';
import 'package:tekartik_audio_web/src/sequencer/sequencer_event.dart';
import 'package:tekartik_audio_web/src/sequencer/song.dart';

typedef SequencerCallback = void Function(SequencerEvent event);

// Seconds
num beatDuration(num bpm) {
  return 60.0 / bpm;
}

class Sequencer {
  static DevFlag debug = DevFlag('Sequancer');

  // A step is the smallest unit
  late num stepDuration;

  // total song duration
  num? loopDuration;

  int get stepCount => _song!.stepCount;

  // current step index
  int _currentStepIndex = 0;

  // current loop index
  int _currentLoopIndex = 0;
  Song? _song;

  // Offset for 1st item, modified when changing tempo so that _currentLook and _currentIndex are always incremental
  late double _timeOffset;

  int get currentLoopIndex => _currentLoopIndex;

  int get currentStepIndex => _currentStepIndex;

  // beat per minute
  num _tempo = 120.0;
  bool _done = false;
  bool repeat = true;
  bool playing = false;
  SequencerCallback? callback;

  bool get done => _done;

  num get tempo => _tempo;

  void checkIndex() {
    if (_currentStepIndex >= stepCount) {
      if (!repeat) {
        _done = true;
      } else {
        _currentStepIndex = 0;
        _currentLoopIndex++;
      }
    }
  }

  void nextIndex() {
    ++_currentStepIndex;
    checkIndex();
  }

  num getNoteTime(int loopIndex, num currentStepIndex) {
    return (loopIndex * loopDuration! + currentStepIndex * stepDuration) +
        _timeOffset;
  }

  num getCurrentNoteTime() {
    return getNoteTime(_currentLoopIndex, _currentStepIndex);
  }

  void start() {
    _currentStepIndex = 0;
    _currentLoopIndex = 0;
    _timeOffset = .0;
    _done = false;
    playing = true;
  }

  void stop() {
    _done = true;
    playing = false;
  }

  // Try to set same step in same loop
  void updateSong(Song song, num currentTime) {
    if (playing) {
      var currentStepIndex = _currentStepIndex;
      //num currentNoteTime = getCurrentNoteTime();
      //num previous
      var previousLoopDuration = loopDuration;
      this.song = song;
      if (currentStepIndex < stepCount) {
        // just fix timeOffset
        _timeOffset -=
            (loopDuration! - previousLoopDuration!) * _currentLoopIndex;
      } else {
        _currentStepIndex = 0;
        _currentLoopIndex++;
        _timeOffset -=
            (loopDuration! * _currentLoopIndex) -
            (previousLoopDuration! * (_currentLoopIndex - 1));
        if (debug.on) {
          print(
            '[sequencer] $loopDuration $_currentLoopIndex ${_timeOffset.toStringAsFixed(2)}',
          );
        }
      }

      if (debug.on) {
        print(
          '[sequencer] update song $song at ${currentTime.toStringAsFixed(2)} - current ${getCurrentNoteTime().toStringAsFixed(2)}',
        );
      }
    } else {
      this.song = song;
    }
  }

  void updateTempo(num tempo, num currentTime) {
    if (debug.on) {
      print(
        '[sequencer] update tempo $tempo at ${currentTime.toStringAsFixed(2)}',
      );
    }
    _tempo = tempo;
    if (playing) {
      //beatDuration = Song.getBeatDurationWithTempo(_tempo);
      //loopDuration = beatCount * beatDuration;

      // console.log('Updating tempo to ' + bpm);
      // console.log((this.getCurrentNoteTime()).toFixed(2));

      // Change start time so that previous note time is the same than before
      num newStepDuration = _song!.getStepDurationWithTempo(_tempo);
      var newLoopDuration = stepCount * newStepDuration;

      var previousNoteTime = getNoteTime(
        _currentLoopIndex,
        _currentStepIndex - 1,
      );
      var nextNoteTime = getNoteTime(_currentLoopIndex, _currentStepIndex);

      num ratio =
          (currentTime - previousNoteTime) / (nextNoteTime - previousNoteTime);
      // Don't fix before the last scheduled time
      if (ratio < 0) {
        ratio = 0;
      }

      var currentNoteTime = getNoteTime(
        _currentLoopIndex,
        _currentStepIndex - 1 + ratio,
      );
      // var currentNoteTime = getCurrentNoteTime();

      stepDuration = newStepDuration;
      loopDuration = newLoopDuration;

      var updatedNoteTime = getNoteTime(
        _currentLoopIndex,
        _currentStepIndex - 1 + ratio,
      );
      // var updatedNoteTime = this.getCurrentNoteTime();

      // Calcul the diff between now and before
      var diff = updatedNoteTime - currentNoteTime;
      _timeOffset -= diff;

      // console.log('p ' + previousNoteTime.toFixed(2) + ' c ' + currentTime.toFixed(2) + ' n ' + nextNoteTime.toFixed(2) + ' ratio ' + ratio.toFixed(2) + ' diff ' + diff.toFixed(2) + ' curNT ' + currentNoteTime.toFixed(2) + ' / ' + this.getCurrentNoteTime().toFixed(2));
      //this.beatDuration = newBeatDuration;
      // this.loopDuration = newLoopDuration;

      // console.log((this.getCurrentNoteTime()).toFixed(2));
    }
  }

  set song(Song? song) {
    _song = song;
    // one step is one beat
    stepDuration = _song!.getStepDurationWithTempo(_tempo);
    loopDuration = stepCount * stepDuration;
  }

  Song? get song {
    return _song;
  }

  // Mainly for testing
  void scheduleNSteps(int stepCount) {
    for (var i = 0; i < stepCount; i++) {
      scheduleOneStep();
    }
  }

  void scheduleOneStep([num? time]) {
    checkIndex();

    time ??= getCurrentNoteTime();

    for (var i = 0; i < _song!.instrumentCount; i++) {
      num level = _song!.pattern!.getStepValue(i, _currentStepIndex);

      // Adjust try square 2012-05-14
      //level = level / 100;
      level = level * level / 10000;

      if (level > 0) {
        var event = NoteOnEvent();
        event.volume = level;
        event.instrument = _song!.pattern!.instruments![i];
        event.time = time;

        if (callback != null) {
          callback!(event);
        }
        if (debug.on) {
          print('[sequencer] $event');
        }
        // print(event);

        /*sequencer.playSampleAt(audioKit.getAudioSample(name),
            volume, noteTime);
            */
      }
    }
    // Advance in song
    nextIndex();
  }

  /// end Time exclusive start Time inclusive
  void schedule(num startTime, num? endTime) {
    var pattern = _song!.pattern;

    if (pattern != null) {
      // single pattern song
      /*
      var i;
      var instrumentCount = pattern.instrumentNames.length;
      var beatDuration = this.beatDuration;
      var noteTime;
      // Skip if needed
      */
      //int instrumentCount = pattern.instruments.length;
      num noteTime;

      while (!_done) {
        noteTime = getCurrentNoteTime();
        if (Sequencer.debug.on) {
          print(
            '[sequencer] ${startTime.toStringAsPrecision(2)} < ${noteTime.toStringAsPrecision(2)} < ${endTime!.toStringAsPrecision(2)}',
          );
        }

        if (noteTime >= endTime!) {
          break;
        }

        scheduleOneStep(noteTime);
      }
    }
  }
}

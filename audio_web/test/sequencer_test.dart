import 'package:tekartik_audio_web/src/instrument.dart';
import 'package:tekartik_audio_web/src/sequencer/pattern.dart';
import 'package:tekartik_audio_web/src/sequencer/sequencer.dart';
import 'package:tekartik_audio_web/src/sequencer/sequencer_event.dart';
import 'package:tekartik_audio_web/src/sequencer/song.dart';
import 'package:tekartik_audio_web/src/sequencer/steps_group.dart';
import 'package:test/test.dart';

import 'song_test.dart';

void main() {
  Pattern getPattern1() {
    return Pattern()
      ..instruments = [bassDrumInstrument, snareDrumInstrument]
      ..steps = StepsGroup.fromList([
        [100, 0, 0, 0],
        [0, 0, 10, 0],
      ])
      ..beatStepCount = 2;
  }

  group('sequencer', () {
    test('beatDuration', () {
      expect(beatDuration(60), 1);
      expect(beatDuration(120), .5);
    });
    test('callback', () {
      SequencerEvent? lastEvent;

      var song = Song();
      song.pattern = getPattern1();
      var sequencer = Sequencer();
      sequencer.repeat = false;
      sequencer.song = song;
      sequencer.start();
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event;
      };
      while (!sequencer.done) {
        sequencer.scheduleOneStep();
      }
      expect(sequencer.done, isTrue);
      expect(lastEvent!.time, equals(0.5));
      expect(lastEvent, const TypeMatcher<NoteOnEvent>());
      var noteOnEvent = lastEvent as NoteOnEvent;
      expect(noteOnEvent.instrument, equals(snareDrumInstrument));
      expect(noteOnEvent.volume, equals(0.01));

      sequencer.repeat = true;
      sequencer.start();
      for (var i = 0; i < 5; i++) {
        sequencer.scheduleOneStep();
      }
      expect(sequencer.done, isFalse);
      expect(lastEvent!.time, equals(1.0));
      noteOnEvent = lastEvent as NoteOnEvent;
      expect(noteOnEvent.instrument, equals(bassDrumInstrument));
      expect(noteOnEvent.volume, 1.0);
    });

    test('update_tempo', () {
      //Sequencer.debug.on = true;
      late SequencerEvent lastEvent;
      var song = Song();
      song.pattern = getPattern1();
      var sequencer = Sequencer();
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event;
      };
      sequencer.start();
      sequencer.scheduleOneStep();
      sequencer.scheduleOneStep();
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(0.5));
      sequencer.updateTempo(60, 0.75);
      sequencer.scheduleOneStep();
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(1.25));
    });

    test('update_tempo_stopped', () {
      var sequencer = Sequencer();
      var times = <num>[];
      sequencer.callback = (SequencerEvent event) => times.add(event.time!);
      sequencer.song = getTicTacSong(); // 120 bpm: a step every 0.5 s
      // Changed while stopped: the next start plays at 60 bpm
      sequencer.updateTempo(60, 0);
      expect(sequencer.tempo, 60);
      sequencer.start();
      sequencer.scheduleNSteps(3);
      expect(times, [0, 1, 2]);
      sequencer.stop();
      sequencer.updateTempo(120, 0);
      sequencer.start();
      times.clear();
      sequencer.scheduleNSteps(3);
      expect(times, [0, 0.5, 1]);
    });

    test('update_song_1', () {
      var tester = _UpdateSongTester(getTicTacSong());
      tester.sequencer.scheduleOneStep();
      expect(tester.lastEvent!.time, 0.0);
      tester.expectNextAfterUpdate(getTicTacTacSong(), 0.5, 1.0, 'tac');
      // Past the end of the 2 steps song, its next loop starts at 2
      tester.expectNextAfterUpdate(getTicTacSong(), 1.5, 2.0, 'tic');
    });

    test('update_song_2', () {
      var tester = _UpdateSongTester(getTicTacSong(), steps: 2);
      expect(tester.lastEvent!.time, 1.0);
      tester.expectNextAfterUpdate(getTicTacTacSong(), 1.5, 2.0, 'tic');
    });

    test('update_song_3', () {
      _UpdateSongTester(
        getTicTacSong(),
        steps: 4,
      ).expectNextAfterUpdate(getTicTacTacSong(), 3.5, 4.0, 'tic');
    });

    test('update_song_4', () {
      _UpdateSongTester(
        getTicTacSong(),
        steps: 5,
      ).expectNextAfterUpdate(getTicTacTacSong(), 4.5, 5.0, 'tac');
    });

    test('update_song_3_to_2_at_3', () {
      _UpdateSongTester(
        getTicTacTacSong(),
        steps: 3,
      ).expectNextAfterUpdate(getTicTacSong(), 2.5, 3.0, 'tic');
    });

    test('update_song_3_to_2_at_2', () {
      _UpdateSongTester(
        getTicTacTacSong(),
        steps: 2,
      ).expectNextAfterUpdate(getTicTacSong(), 1.5, 2.0, 'tic');
    });

    test('update_song_3_to_2_at_5', () {
      _UpdateSongTester(
        getTicTacTacSong(),
        steps: 5,
      ).expectNextAfterUpdate(getTicTacSong(), 4.5, 5.0, 'tic');
    });

    test('update_song_3_to_2_at_6', () {
      _UpdateSongTester(
        getTicTacTacSong(),
        steps: 6,
      ).expectNextAfterUpdate(getTicTacSong(), 5.5, 6.0, 'tic');
    });

    test('update_song_3_to_2_at_32', () {
      _UpdateSongTester(
        getTicTacTacSong(),
        steps: 32,
      ).expectNextAfterUpdate(getTicTacSong(), 31.5, 32.0, 'tic');
    });

    test('update_song_every_step', () {
      var tester = _UpdateSongTester(getTicTacTacSong());
      var sequencer = tester.sequencer;
      var threeStepsOn = true;
      var times = <num>[];
      for (var i = 0; i < 50; i++) {
        sequencer.scheduleOneStep();
        times.add(tester.lastEvent!.time!);
        var nextNoteTime = sequencer.getCurrentNoteTime();
        sequencer.updateSong(
          threeStepsOn ? getTicTacSong() : getTicTacTacSong(),
          nextNoteTime,
        );
        // The next note does not move
        expect(sequencer.getCurrentNoteTime(), nextNoteTime);
        threeStepsOn = !threeStepsOn;
      }
      // One note per second, whatever the song
      expect(times, List.generate(50, (i) => i.toDouble()));
    });
  });
}

/// A playing sequencer at 60 bpm (one step per second) on [song] with
/// [steps] steps already scheduled.
class _UpdateSongTester {
  final sequencer = Sequencer();
  NoteOnEvent? lastEvent;

  _UpdateSongTester(Song song, {int steps = 0}) {
    sequencer.updateTempo(60, 0);
    sequencer.repeat = true;
    sequencer.song = song;
    sequencer.callback = (SequencerEvent event) {
      lastEvent = event as NoteOnEvent;
    };
    sequencer.start();
    sequencer.scheduleNSteps(steps);
  }

  /// Switch to [song] at [currentTime], the next note is expected at [time]
  /// with [instrument].
  void expectNextAfterUpdate(
    Song song,
    num currentTime,
    num time,
    String instrument,
  ) {
    sequencer.updateSong(song, currentTime);
    sequencer.scheduleOneStep();
    expect(lastEvent!.time, time);
    expect(lastEvent!.instrument!.name, instrument);
  }
}

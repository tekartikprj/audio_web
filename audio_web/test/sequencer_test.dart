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

    test('update_song_1', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(0.0));
      sequencer.updateSong(getTicTacTacSong(), 0.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(1.0));
      expect(lastEvent.instrument!.name, 'tac');
      sequencer.updateSong(getTicTacSong(), 1.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(0.0));
      expect(lastEvent.instrument!.name, 'tic');
      /*
      sequencer.updateSong(getTicTacTacSong(), 1.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(2));
      */
    });

    test('update_song_2', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleOneStep();
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(1.0));
      sequencer.updateSong(getTicTacTacSong(), 1.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(2.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_3', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(4);
      sequencer.updateSong(getTicTacTacSong(), 3.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(4.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_4', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(5);
      sequencer.updateSong(getTicTacTacSong(), 4.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(5.0));
      expect(lastEvent.instrument!.name, 'tac');
    });

    test('update_song_3_to_2_at_3', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(3);
      sequencer.updateSong(getTicTacSong(), 2.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(3.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_3_to_2_at_2', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(2);
      sequencer.updateSong(getTicTacSong(), 1.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(0.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_3_to_2_at_5', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(5);
      sequencer.updateSong(getTicTacSong(), 4.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(3.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_3_to_2_at_6', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(6);
      sequencer.updateSong(getTicTacSong(), 5.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(6.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_3_to_2_at_32', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      late NoteOnEvent lastEvent;
      var song = getTicTacTacSong();
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.callback = (SequencerEvent event) {
        lastEvent = event as NoteOnEvent;
      };
      sequencer.start();
      sequencer.scheduleNSteps(32);
      sequencer.updateSong(getTicTacSong(), 5.5);
      sequencer.scheduleOneStep();
      expect(lastEvent.time, equals(30.0));
      expect(lastEvent.instrument!.name, 'tic');
    });

    test('update_song_every_step', () {
      // ignore: deprecated_member_use
      Sequencer.debug.on = true;
      var song = getTicTacTacSong();
      var threeStepsOn = true;
      var sequencer = Sequencer();
      sequencer.updateTempo(60, 0);
      sequencer.repeat = true;
      sequencer.song = song;
      sequencer.start();

      for (var i = 0; i < 50; i++) {
        sequencer.scheduleOneStep();
        sequencer.updateSong(
          threeStepsOn ? getTicTacSong() : getTicTacTacSong(),
          sequencer.getCurrentNoteTime(),
        );
        threeStepsOn = !threeStepsOn;
      }
    });
  });
}

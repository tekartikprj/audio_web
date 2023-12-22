import 'package:tekartik_audio_web/src/instrument.dart';

class SequencerEvent {
  num? time;
}

class NoteOnEvent extends SequencerEvent {
  Instrument? instrument;
  num? volume;

  @override
  String toString() {
    return '$instrument:$volume at $time';
  }
}

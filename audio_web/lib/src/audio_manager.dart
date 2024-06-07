import 'audio_format.dart';

abstract class AudioManager {
  Set<AudioFormatType> get supportedTypes;
}

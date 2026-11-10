import 'audio_format.dart';

/// The audio of an app, see `AudioManagerWeb`.
abstract class AudioManager {
  /// The formats the platform can play.
  Set<AudioFormatType> get supportedTypes;
}

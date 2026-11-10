/// The audio file formats checked by `AudioManagerWeb.supportedTypes`.
enum AudioFormatType { mp3, ogg }

/// What is known of an [AudioFormatType].
abstract class AudioFormatInformation {
  /// The mime type checked (`audio/mp3`, `audio/ogg`).
  String get mimeType;
}

class _AudioFormatInformation implements AudioFormatInformation {
  @override
  String toString() => mimeType;
  @override
  final String mimeType;

  _AudioFormatInformation({required this.mimeType});
}

/// The information of each [AudioFormatType].
final audioFormatInformation = <AudioFormatType, AudioFormatInformation>{
  AudioFormatType.mp3: _AudioFormatInformation(mimeType: 'audio/mp3'),
  AudioFormatType.ogg: _AudioFormatInformation(mimeType: 'audio/ogg'),
};

enum AudioFormatType { mp3, ogg }

abstract class AudioFormatInformation {
  String get mimeType;
}

class _AudioFormatInformation implements AudioFormatInformation {
  @override
  String toString() => mimeType;
  @override
  final String mimeType;

  _AudioFormatInformation({required this.mimeType});
}

final audioFormatInformation = <AudioFormatType, AudioFormatInformation>{
  AudioFormatType.mp3: _AudioFormatInformation(mimeType: 'audio/mp3'),
  AudioFormatType.ogg: _AudioFormatInformation(mimeType: 'audio/ogg')
};

import 'dart:html';
import 'dart:web_audio';

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:tekartik_audio_web/src/common_utils.dart';

import 'import.dart';

class AudioManagerWeb implements AudioManager {
  final AudioContext audioContext = AudioContext();

  AudioManagerWeb() {
    init();
  }

  void init() {
    /// Check for browser support for various codecs and cache the results.
    /// @return {Howler}

    AudioElement audioTest;

    // Must wrap in a try/catch because IE11 in server mode throws an error.
    try {
      audioTest = AudioElement();
    } catch (err) {
      print('Audio not supported');
      return;
    }

    void checkAndAdd(AudioFormatType type) {
      if (canPlayType(audioTest, audioFormatInformation[type]!.mimeType)) {
        _supportedTypes.add(type);
      }
    }

    for (var type in AudioFormatType.values) {
      checkAndAdd(type);
    }
    // canPlayType(audioTest, 'audio/mpeg;');
/*
    this._codecs = {
      'mp3': (mpegTest || canPlayType(audioTest,'audio/mp3;') ) ,
      'mpeg': mpegTest,
      'opus': canPlayType(audioTest, 'audio/ogg; codecs="opus"') ,
      'ogg': canPlayType(audioTest, 'audio/ogg; codecs="vorbis"') ,
      'oga': canPlayType(audioTest, 'audio/ogg; codecs="vorbis"') ,
      'wav': canPlayType(audioTest, 'audio/wav; codecs="1"') ,
      'aac': canPlayType(audioTest, 'audio/aac;') ,
      'caf': canPlayType(audioTest, 'audio/x-caf;') ,
      'm4a': canPlayType(audioTest, 'audio/x-m4a;') || canPlayType(audioTest, 'audio/m4a;') || canPlayType(audioTest, 'audio/aac;') ,
      'mp4': canPlayType(audioTest, 'audio/x-mp4;') || canPlayType(audioTest, 'audio/mp4;') || canPlayType(audioTest, 'audio/aac;') ,
      'weba': canPlayType(audioTest, 'audio/webm; codecs="vorbis"') ,
      'webm': canPlayType(audioTest, 'audio/webm; codecs="vorbis"') ,
      'dolby': canPlayType(audioTest, 'audio/mp4; codecs="ec-3"') ,
      'flac': canPlayType(audioTest, 'audio/x-flac;') || canPlayType(audioTest,'audio/flac;')
    };
*/
    //  return this;
  }

  final _supportedTypes = <AudioFormatType>{};

  @override
  Set<AudioFormatType> get supportedTypes => _supportedTypes;

  bool testCanPlayRawFormatType(String type) {
    try {
      var audioTest = AudioElement();
      return canPlayType(audioTest, type);
    } catch (err) {
      print('Audio not supported');
    }
    return false;
  }

  bool testCanPlayFormatType(AudioFormatType type) {
    try {
      var audioTest = AudioElement();

      return canPlayType(audioTest, audioFormatInformation[type]!.mimeType);
    } catch (err) {
      print('Audio not supported');
    }
    return false;
  }
}

@visibleForTesting
String canPlayTypeRawResult(String type) {
  try {
    var audioTest = AudioElement();

    var result = audioTest.canPlayType(type);
    return result;
  } catch (err) {
    print('Audio not supported');
    rethrow;
  }
}

bool canPlayType(AudioElement audioTest, String type) {
  // audio/mp3 probably
  // audio/ogg maybe
  // audio/wav maybe
  // audio/dummy
  try {
    var canPlayTypeResult = audioTest.canPlayType(type);
    return canPlayTypeResultCheck(canPlayTypeResult);
  } catch (e) {
    if (isDebug) {
      print('canPlayType($type) error $e');
    }
    return false;
  }
}

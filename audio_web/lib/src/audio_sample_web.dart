import 'dart:typed_data';
import 'dart:web_audio';

import 'package:tekartik_browser_utils/browser_utils_import.dart';

class AudioSample {
  bool loaded = false;
  AudioBuffer? buffer;

  final AudioContext? _audioContext;

  AudioSample(this._audioContext);

  Future get ready => _readyCompleter.future;
  final _loadLock = Lock();
  final _readyCompleter = Completer<void>.sync();

  /// TODO remove mixToMono
  Future load(String url, [bool? mixToMono]) async {
    await _loadLock.synchronized(() async {
      if (loaded) {
        return;
      }
      loaded = true;
      var request = await HttpRequest.request(url, responseType: 'arraybuffer');
      buffer = await _audioContext!
          .decodeAudioData(request.response as ByteBuffer); //, mixToMono);
      _readyCompleter.complete();
    });
  }

  AudioBufferSourceNode noteOn(AudioNode destination, num? time) {
    var node = _audioContext!.createBufferSource();
    node.connectNode(destination);
    node.buffer = buffer;
    node.start(time);
    return node;
  }

  /// Simple helper to play a sample
  void play() {
    noteOn(_audioContext!.destination!, _audioContext!.currentTime);
  }

  Future loadBytes(Uint8List bytes) async {
    await _loadLock.synchronized(() async {
      buffer ??=
          await _audioContext!.decodeAudioData(bytes.buffer); //, mixToMono);
      _readyCompleter.complete();
    });
  }
}

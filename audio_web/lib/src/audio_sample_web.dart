import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tekartik_browser_utils/browser_utils_import.dart';
import 'package:web/web.dart' as web;

class AudioSample {
  bool loaded = false;
  web.AudioBuffer? buffer;

  final web.AudioContext? _audioContext;

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
      var request =
          // ignore: deprecated_member_use
          await web.HttpRequest.request(url, responseType: 'arraybuffer');
      buffer = await _audioContext!
          .decodeAudioData(request.response as JSArrayBuffer)
          .toDart; //, mixToMono);
      _readyCompleter.complete();
    });
  }

  web.AudioBufferSourceNode noteOn(web.AudioNode destination, num? time) {
    var node = _audioContext!.createBufferSource();
    node.connect(destination);
    node.buffer = buffer;
    if (time != null) {
      node.start(time);
    } else {
      node.start();
    }
    return node;
  }

  /// Simple helper to play a sample
  void play() {
    noteOn(_audioContext!.destination, _audioContext.currentTime);
  }

  Future loadBytes(Uint8List bytes) async {
    await _loadLock.synchronized(() async {
      buffer ??= (await _audioContext!
          .decodeAudioData(bytes.buffer.toJS)
          .toDart); //, mixToMono);
      _readyCompleter.complete();
    });
  }
}

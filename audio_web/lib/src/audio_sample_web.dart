import 'dart:js_interop';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'import.dart';

/// A sound decoded in an [web.AudioContext], played as many times as needed.
///
/// One sample per sound: [load] (a url) or [loadBytes] (the bytes of a file)
/// once, then [play] or [noteOn].
class AudioSample {
  /// True once decoded (a failed load leaves it false).
  bool loaded = false;

  /// The decoded sound, null until loaded.
  web.AudioBuffer? buffer;

  final web.AudioContext? _audioContext;

  /// A sample played in an audio context (the one of `AudioManagerWeb`).
  AudioSample(this._audioContext);

  /// Completes once loaded.
  Future get ready => _readyCompleter.future;
  final _loadLock = Lock();
  final _readyCompleter = Completer<void>.sync();

  /// Downloads [url] and decodes it, once: does nothing when already loaded
  /// (by [load] or [loadBytes]). Throws when the download or the decoding
  /// fails; it can then be called again.
  ///
  /// [mixToMono] is ignored (TODO remove).
  Future load(String url, [bool? mixToMono]) async {
    await _loadLock.synchronized(() async {
      if (loaded) {
        return;
      }
      var data = await http.readBytes(Uri.parse(url));
      await _decode(data);
    });
  }

  /// Decodes [bytes] into [buffer], marks the sample loaded (only on
  /// success, a failed load can be retried) and completes [ready] once.
  Future<void> _decode(Uint8List bytes) async {
    // decodeAudioData reads the whole ArrayBuffer it is given and detaches
    // it: decode a copy of exactly these bytes (a view can be part of a
    // bigger buffer, and the caller keeps its bytes).
    var copy = Uint8List.fromList(bytes);
    buffer = await _audioContext!.decodeAudioData(copy.buffer.toJS).toDart;
    loaded = true;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  /// Plays the sample at [time] (seconds on the `currentTime` clock of the
  /// context, now when null or past) through [destination] (a gain node or
  /// the context `destination`). Returns the source node, single use, to
  /// `stop()` it. Plays nothing when not loaded yet.
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

  /// Plays the sample now on the context destination.
  void play() {
    noteOn(_audioContext!.destination, _audioContext.currentTime);
  }

  /// Loads the sample from the bytes of an audio file (wav, ogg, mp3...),
  /// once: does nothing when already loaded (by [load] or [loadBytes]).
  Future loadBytes(Uint8List bytes) async {
    await _loadLock.synchronized(() async {
      if (loaded) {
        return;
      }
      await _decode(bytes);
    });
  }
}

@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// A silent 16 bit mono PCM wav of [count] samples at 8000 Hz (0.1 s).
Uint8List wavBytes([int count = 800]) {
  var data = ByteData(44 + count * 2);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + count * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 16000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, count * 2, Endian.little);
  return data.buffer.asUint8List();
}

/// A data url of [bytes].
String dataUrl(List<int> bytes) =>
    'data:audio/wav;base64,${base64Encode(bytes)}';

void main() {
  // Not resumed: decoding needs no user gesture.
  late web.AudioContext audioContext;
  setUpAll(() {
    audioContext = web.AudioContext();
  });
  tearDownAll(() async {
    await audioContext.close().toDart;
  });
  const timeout = Timeout(Duration(seconds: 30));

  group('AudioSample', () {
    test('loadBytes', () async {
      var sample = AudioSample(audioContext);
      await sample.loadBytes(wavBytes());
      await sample.ready;
      expect(sample.loaded, isTrue);
      expect(sample.buffer!.duration, closeTo(0.1, 0.001));
    }, timeout: timeout);

    test('a second load is a no-op', () async {
      var sample = AudioSample(audioContext);
      await sample.loadBytes(wavBytes());
      var buffer = sample.buffer;
      // Used to throw 'Bad state: Future already completed'
      await sample.loadBytes(wavBytes(1600));
      await sample.load(dataUrl(wavBytes(1600)));
      expect(sample.buffer, same(buffer));

      sample = AudioSample(audioContext);
      await sample.load(dataUrl(wavBytes()));
      await sample.loadBytes(wavBytes(1600));
      expect(sample.buffer!.duration, closeTo(0.1, 0.001));
    }, timeout: timeout);

    test('loadBytes keeps the caller bytes', () async {
      var bytes = wavBytes();
      await AudioSample(audioContext).loadBytes(bytes);
      // decodeAudioData detaches the buffer it is given (dart2js)
      expect(bytes.length, 44 + 1600);
      var other = AudioSample(audioContext);
      await other.loadBytes(bytes);
      expect(other.buffer!.duration, closeTo(0.1, 0.001));
    }, timeout: timeout);

    test('loadBytes of a view', () async {
      var wav = wavBytes();
      var padded = Uint8List(wav.length + 20)..setAll(10, wav);
      var sample = AudioSample(audioContext);
      await sample.loadBytes(
        Uint8List.sublistView(padded, 10, 10 + wav.length),
      );
      expect(sample.buffer!.duration, closeTo(0.1, 0.001));
    }, timeout: timeout);

    test('a failed load can be retried', () async {
      var sample = AudioSample(audioContext);
      await expectLater(sample.load(dataUrl([1, 2, 3, 4])), throwsA(anything));
      expect(sample.loaded, isFalse);
      expect(sample.buffer, isNull);
      await sample.load(dataUrl(wavBytes()));
      await sample.ready;
      expect(sample.loaded, isTrue);
      expect(sample.buffer!.duration, closeTo(0.1, 0.001));
    }, timeout: timeout);
  });
}

// Browser only: `dart compile js example/main.dart -o main.dart.js` and a
// page with `<script defer src="main.dart.js"></script>`.
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:web/web.dart' as web;

/// One manager, one AudioContext, for the whole app.
final audioManager = AudioManagerWeb();

/// A 0.2 s 440 Hz beep, as the bytes of a 16 bit mono wav file.
Uint8List beepWav({int sampleRate = 8000, double seconds = 0.2}) {
  var count = (sampleRate * seconds).round();
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
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, count * 2, Endian.little);
  for (var i = 0; i < count; i++) {
    var value = sin(2 * pi * 440 * i / sampleRate) * 8000;
    data.setInt16(44 + i * 2, value.round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

Future<void> main() async {
  var audioContext = audioManager.audioContext;
  var sample = AudioSample(audioContext);
  // A file would be `await sample.load('sounds/beep.ogg');`
  await sample.loadBytes(beepWav());

  var button = web.HTMLButtonElement()..textContent = 'Play';
  web.document.body!.append(button);
  button.onClick.listen((_) async {
    // The context stays suspended until a user gesture.
    await audioContext.resume().toDart;
    // Now, then twice more on the audio clock.
    var now = audioContext.currentTime;
    for (var i = 0; i < 3; i++) {
      sample.noteOn(audioContext.destination, now + i * 0.3);
    }
  });
}

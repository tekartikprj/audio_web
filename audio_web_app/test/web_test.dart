@TestOn('browser')
library;

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:test/test.dart';

var assetsTop = 'packages/tekartik_audio_web_app/assets';

final audioManager = AudioManagerWeb();
var audioContext = audioManager.audioContext;

void main() {
  test('format', () async {
    var audioSample = AudioSample(audioContext);
    await audioSample.load('$assetsTop/audio/tac.ogg', true);
    audioSample.noteOn(audioContext.destination, audioContext.currentTime);
    await Future<void>.delayed(Duration(seconds: 5));
  });
}

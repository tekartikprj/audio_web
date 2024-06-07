import 'package:tekartik_audio_web/audio_web.dart';

final audioManager = AudioManagerWeb();
var audioContext = audioManager.audioContext;

Future main() async {
  var audioSample = AudioSample(audioContext);
  await audioSample.load('my_audio.ogg', true);
  audioSample.noteOn(audioContext.destination, audioContext.currentTime);
}

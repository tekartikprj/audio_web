---
name: tekartik-audio-web-setup
description: >-
  Use when playing sounds in a dart web app on top of the Web Audio API with
  tekartik_audio_web: AudioManagerWeb (audioContext, supportedTypes,
  testCanPlayFormatType, testCanPlayRawFormatType), AudioSample (load,
  loadBytes, ready, noteOn, play, buffer), AudioManager, AudioFormatType and
  audioFormatInformation, the package:tekartik_audio_web/audio_web.dart import,
  sample scheduling with audioContext.currentTime and browser codec detection.
---

# Web audio samples (tekartik_audio_web)

`tekartik_audio_web` is a thin dart layer over the browser Web Audio API
(`package:web`): one `AudioManagerWeb` owns the `AudioContext` and reports
which codecs the browser can play, and one `AudioSample` per sound downloads,
decodes and schedules it. Browser only.

## Guidelines

* The package lives in a private repository and is not on pub.dev; depend on
  it from git (as the package README shows):

  ```yaml
  dependencies:
    tekartik_audio_web:
      git:
        url: https://github.com/tekartikprj/audio_web
        path: audio_web
      version: '>=0.1.0'
  ```

* One public library: `package:tekartik_audio_web/audio_web.dart`. It exports
  exactly `AudioManager`, `AudioManagerWeb`, `AudioSample`, `AudioFormatType`
  and `audioFormatInformation`. Add `package:web/web.dart` when you name an
  `AudioContext`, an `AudioNode` or an `AudioBuffer`.
* Everything else under `lib/src` (the `sequencer/`, `player/`,
  `instrument.dart`, `audio_kit.dart` files: `Pattern`, `Song`, `Sequencer`,
  `Steps`, `StepsGroup`, `TempoList`, `Player`, `Instrument`, `AudioKit`) is
  unexported work in progress covered only by the package's own tests. Do not
  import `package:tekartik_audio_web/src/...` from an app; copy what you need
  or ask for it to be exported first.
* Web only: `AudioManagerWeb` and `AudioSample` use `dart:js_interop` and
  `package:web`, so this package compiles for the browser (`dart compile js`,
  flutter web), not for the VM or a flutter native target. The package's own
  `dart_test.yaml` lists `vm` and `chrome`; anything touching an
  `AudioContext` must run with `dart test -p chrome`.
* Create exactly one `AudioManagerWeb()` for the whole app (a top level
  `final audioManager = AudioManagerWeb();` is the idiom used by the package
  example). Its constructor builds the single `AudioContext` and probes codec
  support; share `audioManager.audioContext` with every sample. Browsers cap
  the number of audio contexts, so never build one per sound.
* Codec support: `audioManager.supportedTypes` is the `Set<AudioFormatType>`
  ({`mp3`, `ogg`}) the browser said it can play, computed at construction.
  `testCanPlayFormatType(AudioFormatType)` and
  `testCanPlayRawFormatType('audio/wav; codecs="1"')` probe again on demand.
  `audioFormatInformation[AudioFormatType.ogg]!.mimeType` gives the mime type
  (`audio/mp3`, `audio/ogg`) of an enum value. Pick the url extension from
  `supportedTypes` instead of hardcoding one format.
* `AudioManager` is the tiny abstract interface (`supportedTypes` only) —
  type a field with it if you want to keep non-web code compiling, but the
  only implementation is `AudioManagerWeb`.
* `AudioSample(audioContext)` takes the context positionally. `load(url)`
  fetches the url with `package:http` and decodes it with
  `decodeAudioData`; `loadBytes(Uint8List)` decodes bytes you already have
  (a generated wav, an asset you read yourself). `await sample.ready` (or
  await the `load` future) before playing; `sample.loaded` and
  `sample.buffer` (a `web.AudioBuffer?`) expose the state.
* One `AudioSample` per sound file: `load` is guarded by a lock and by the
  `loaded` flag, so a second `load('other.ogg')` on the same instance
  silently returns without loading anything. Call `loadBytes` at most once
  per instance too (the internal ready completer would complete twice and
  throw a `StateError`).
* `noteOn(destination, time)` creates a fresh `AudioBufferSourceNode`,
  connects it to `destination` and starts it: `time` is an `AudioContext`
  clock value in seconds (`audioContext.currentTime` for now,
  `currentTime + 0.5` for half a second ahead, `null` for immediately). A
  source node is single use, so call `noteOn` once per hit and keep the
  returned node when you need `stop()`. `play()` is the shortcut for
  `noteOn(audioContext.destination, audioContext.currentTime)`.
* Schedule ahead on the audio clock (`currentTime + offset`) rather than with
  `Timer`/`Future.delayed`: only the audio clock is sample accurate.
* Autoplay policy: the context starts suspended until the page gets a user
  gesture. `await audioManager.audioContext.resume().toDart` (needs
  `dart:js_interop` for `toDart`) inside the first click handler, otherwise
  the first sounds are silently dropped.
* Volume, panning or effects: insert your own `package:web` nodes and pass
  the head of the chain as the `noteOn` destination (`createGain()`,
  `createStereoPanner()`...). The package itself does no mixing.
* Anti-patterns: several `AudioManagerWeb` instances; reusing one
  `AudioSample` for several urls; playing before `ready` completes (`buffer`
  is still null, nothing is heard); loading a format missing from
  `supportedTypes`; serving samples from an origin without CORS headers (the
  `http` fetch fails).

## Examples

Load and play one sample, honouring the browser autoplay policy.

```dart
import 'dart:js_interop';

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:web/web.dart' as web;

final audioManager = AudioManagerWeb();

Future<void> main() async {
  var audioContext = audioManager.audioContext;
  var sample = AudioSample(audioContext);
  await sample.load('sounds/click.ogg');

  web.document.querySelector('#play')!.onClick.listen((_) async {
    // Browsers keep the context suspended until a user gesture.
    await audioContext.resume().toDart;
    sample.play();
  });
}
```

Pick the file extension the browser actually supports.

```dart
import 'package:tekartik_audio_web/audio_web.dart';

/// Loads `<name>.ogg` or `<name>.mp3` depending on the browser.
Future<AudioSample> loadSound(AudioManagerWeb manager, String name) async {
  var types = manager.supportedTypes;
  if (types.isEmpty) {
    throw StateError('no supported audio format');
  }
  var type = types.contains(AudioFormatType.ogg)
      ? AudioFormatType.ogg
      : AudioFormatType.mp3;
  print('using ${audioFormatInformation[type]!.mimeType}');

  var sample = AudioSample(manager.audioContext);
  await sample.load('sounds/$name.${type.name}');
  return sample;
}

void main() async {
  var manager = AudioManagerWeb();
  print(manager.testCanPlayRawFormatType('audio/wav; codecs="1"'));
  await loadSound(manager, 'kick');
}
```

Schedule a loop on the audio clock, through a gain node.

```dart
import 'package:tekartik_audio_web/audio_web.dart';
import 'package:web/web.dart' as web;

/// Plays [sample] [count] times, every [interval], at half volume.
void scheduleLoop(
  web.AudioContext audioContext,
  AudioSample sample, {
  int count = 8,
  double interval = 0.5,
}) {
  var gain = audioContext.createGain();
  gain.gain.value = 0.5;
  gain.connect(audioContext.destination);

  var start = audioContext.currentTime + 0.1; // a little scheduling margin
  for (var i = 0; i < count; i++) {
    var node = sample.noteOn(gain, start + i * interval);
    node.stop(start + i * interval + interval); // no overlap
  }
}

Future<void> main() async {
  var manager = AudioManagerWeb();
  var sample = AudioSample(manager.audioContext);
  await sample.load('sounds/kick.ogg');
  scheduleLoop(manager.audioContext, sample);
}
```

Decode bytes you already have (generated audio, asset bundle, cache).

```dart
import 'dart:typed_data';

import 'package:tekartik_audio_web/audio_web.dart';

/// Decodes [bytes] (a wav/mp3/ogg file) into a ready to play sample.
Future<AudioSample> sampleFromBytes(
  AudioManagerWeb manager,
  Uint8List bytes,
) async {
  var sample = AudioSample(manager.audioContext);
  // Once only: loadBytes() must not be called twice on the same sample.
  await sample.loadBytes(bytes);
  await sample.ready;
  print('${sample.buffer!.duration}s decoded');
  return sample;
}
```

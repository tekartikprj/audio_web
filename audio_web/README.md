# tekartik_audio_web

Play short sounds (samples) in a Dart web app, on top of the browser Web
Audio API (`package:web`): one `AudioManagerWeb` owns the `AudioContext` and
tells which codecs the browser plays, one `AudioSample` per sound downloads,
decodes and schedules it.

## Getting started

Not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  tekartik_audio_web:
    git:
      url: https://github.com/tekartikprj/audio_web
      path: audio_web
```

Platforms: browser only (dart2js and dart2wasm, a Flutter web app). The
library uses `dart:js_interop` and `package:web`: it does not compile for the
VM nor a Flutter mobile or desktop target.

```dart
import 'dart:js_interop';

import 'package:tekartik_audio_web/audio_web.dart';
import 'package:web/web.dart' as web;

/// One manager, one AudioContext, for the whole app.
final audioManager = AudioManagerWeb();

Future<void> main() async {
  var audioContext = audioManager.audioContext;
  var sample = AudioSample(audioContext);
  await sample.load('sounds/click.ogg');

  web.document.querySelector('#play')!.onClick.listen((_) async {
    // The context stays suspended until a user gesture.
    await audioContext.resume().toDart;
    sample.play();
  });
}
```

## What to use

- `AudioManagerWeb()`: create one for the app. `audioContext` is shared by
  every sample, `supportedTypes` is the set of `AudioFormatType` (`mp3`,
  `ogg`) the browser can play, `testCanPlayRawFormatType('audio/wav')` probes
  any mime type.
- `AudioSample(audioContext)`: one per sound.
  - `load(url)` downloads (`package:http`) and decodes the file,
    `loadBytes(bytes)` decodes the bytes of a file you already have (an
    asset, a generated wav). Each sample loads once: a second `load` or
    `loadBytes` does nothing. A failed load throws and can be retried.
  - `ready` completes once loaded, `loaded` and `buffer` give the state.
  - `noteOn(destination, time)` plays it at `time` (seconds on the
    `audioContext.currentTime` clock) through `destination` (a gain node, or
    `audioContext.destination`) and returns the source node (`stop()`);
    `play()` plays it now.

The sequencer, player and pattern classes under `lib/src` are not exported:
they are used by the package's own tests and its demo app only.

## Pitfalls

- Autoplay policy: a context created before a user gesture is suspended,
  nothing is heard. Call `audioContext.resume()` from a click handler.
- Schedule with the audio clock (`currentTime + 0.5`), not with a `Timer`:
  only the audio clock is sample accurate.
- `noteOn` before the sample is loaded plays nothing (`buffer` is null):
  await `load` or `ready` first.
- Samples from another origin need CORS headers.

## Example

[example/main.dart](example/main.dart) loads and plays one sample on a
click. The `audio_web_app` package of this repository holds a test menu
(samples, the drum kit player, tempo changes).

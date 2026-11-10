# tekartik_audio_web_app

A browser test app of `tekartik_audio_web` (in this repository): a web menu
(`tekartik_test_menu_browser`) playing the bundled samples
(`lib/assets/audio/`: `tic.ogg`, `tac.ogg`, `drumkit.json`) through
`AudioSample`, `AudioKit` and the `Player` sequencer. Not a library.

## Run the menu

From this package:

```bash
dart run build_runner serve example:8060
# or webdev serve example:8060
```

Then open http://localhost:8060/menu/index.html and click the items (a
click lets the browser start the audio):

* `can play`: the formats the browser plays.
* `audio_sample`: `tac` (one sample), `tac then tic` (two, 0.2 s apart).
* `player_init`: `init` (loads the kit), `simple` (a tic tac loop, stopped
  when leaving the menu).
* `player`: `start`, `stop`, `waltz`, `two_steps`, `tempo++`, `tempo--` on
  one player (prints each scheduled note).
* `audio_kit`: `load` the kit.

The menu code is `example/menu/main.dart`; the assets are served at
`packages/tekartik_audio_web_app/assets/`.

## Tests

```bash
dart test -p chrome
```

`test/web_test.dart` loads and plays `tac.ogg` in Chrome (dart2js; add
`-c dart2wasm` for wasm). The tests of the library itself are in
`../audio_web/test`.

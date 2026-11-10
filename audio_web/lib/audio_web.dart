/// Short sounds (samples) on the Web Audio API, browser only:
/// [AudioManagerWeb] (one per app, it owns the AudioContext) and
/// [AudioSample] (one per sound: load, then play or schedule).
library;

export 'src/audio_format.dart' show AudioFormatType, audioFormatInformation;
export 'src/audio_manager.dart' show AudioManager;
export 'src/audio_manager_web.dart' show AudioManagerWeb;
export 'src/audio_sample_web.dart' show AudioSample;

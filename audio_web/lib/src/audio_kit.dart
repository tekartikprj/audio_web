import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:web_audio';
import 'package:path/path.dart';
import 'package:tekartik_audio_web/audio_web.dart';
import 'package:tekartik_audio_web/src/instrument.dart';

class AudioKit {
  Map<Instrument, AudioSample> samples = {};
  //List<List<String>> groups;
  Map<Instrument, String> instrumentUrls = {};
  late String kitUrl;
  // Map from each instrument to a group of instrument that cannot be played together (open/closed hit-hat for example)
  Map<Instrument, List<Instrument>> groupMap = {};

  Future loadKit(AudioContext? audioContext, String? defUrl, [String? kitUrl]) {
    this.kitUrl = kitUrl ?? url.dirname(defUrl!);

    return HttpRequest.getString('$defUrl').then((String content) {
      var result = jsonDecode(content) as Map;

      var instruments = result[r'instruments'] as Map;
      instruments.forEach((key, value) {
        var instrument = Instrument(key?.toString());
        instrumentUrls[instrument] = value as String;
      });

      /*
      groups = result[r'groups'];

      groupMap = new Map();

      groups.forEach((group) {
        group.forEach((instrument) {
          groupMap[instrument] = group;
        });
      });
      */
      // print(groupMap);
      return loadInstruments(audioContext);
    });
  }

  Future loadInstruments(AudioContext? audioContext) {
    // List<String> instruments = <String> ['bd', 'sn', 'rim', 'chh', 'ohh', 'htom', 'mtom', 'ltom', 'splash', 'ride'];

    var futures = <Future>[];

    var samples = <Instrument, AudioSample>{};

    for (var instrument in instrumentUrls.keys) {
      var instrumentUrl = instrumentUrls[instrument];

      var sample = AudioSample(audioContext);
      //sample.name = instrument;
      samples[instrument] = sample;
      //console.log('loading ' + instrument + ' ' + url);
      //futures.add(sample.load(url + r'/' + instrument + '.ogg', true));
      futures.add(sample.load(url.join(kitUrl, instrumentUrl), true));
    }
    this.samples = samples;

    return Future.wait(futures);
  }
}

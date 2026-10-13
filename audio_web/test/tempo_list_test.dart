import 'package:tekartik_audio_web/src/sequencer/tempo_list.dart';
import 'package:test/test.dart';

void main() {
  group('tempo_list', () {
    test('addRange', () {
      var tempoList = TempoList();
      tempoList.addRange(60, 3);
      tempoList.addRange(40, 2);
      tempoList.addRange(120, 6);
      tempoList.addRange(72, 4);
      expect(tempoList.ranges!.map((range) => range.value), [40, 60, 72, 120]);
      expect(tempoList.ranges!.map((range) => range.diff), [2, 3, 4, 6]);
    });
  });
}

import 'package:tekartik_audio_web/src/common_utils.dart';
import 'package:test/test.dart';

void main() {
  test('format', () {
    expect(canPlayTypeResultCheck('no'), isFalse);
    expect(canPlayTypeResultCheck('NO'), isFalse);
    expect(canPlayTypeResultCheck('yes'), true);
    expect(canPlayTypeResultCheck('maybe'), true);
    expect(canPlayTypeResultCheck('propably'), true);
  });
}

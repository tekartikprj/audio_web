/// Instrument
library;

class Instrument {
  final String? name;
  const Instrument(this.name);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Instrument && other.name == name;
  }

  @override
  String toString() => name!;
}

const Instrument bassDrumInstrument = Instrument('bd');
const Instrument snareDrumInstrument = Instrument('sn');
const Instrument ticInstrument = Instrument('tic');
const Instrument tacInstrument = Instrument('tac');

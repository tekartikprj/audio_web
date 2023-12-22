int _zeroGenerator(int index) {
  return 0;
}

/// wrapper around list
class Steps {
  Steps([int initialSize = 0]) {
    values = <int>[];
    if (initialSize > 0) {
      values!.addAll(Iterable.generate(initialSize, _zeroGenerator));
    }
  }

  Steps.fromList(List stepsDef) {
    values = stepsDef.cast<int>();
  }

  List<int>? values;

  int get length => values!.length;

  void add(int value) {
    values!.add(value);
  }

  int operator [](int index) {
    return values![index];
  }

  void operator []=(int index, int value) {
    values![index] = value;
  }

  List<int>? toList() {
    return values;
  }

  @override
  String toString() {
    return toList().toString();
  }
}

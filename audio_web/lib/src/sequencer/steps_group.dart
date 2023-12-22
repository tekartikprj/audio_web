import 'package:tekartik_audio_web/src/sequencer/steps.dart';

class StepsGroup {
  StepsGroup() {
    values = <Steps>[];
  }

  // from json array
  StepsGroup.fromList(List list) {
    values = <Steps>[];

    for (var stepsDef in list) {
      values.add(Steps.fromList(stepsDef as List));
    }
  }

  late List<Steps> values;

  int get length => values.length;

  int get stepsLength => values[0].length;

  void add(Steps value) {
    values.add(value);
  }

  Steps operator [](int index) {
    return values[index];
  }

  void operator []=(int index, Steps steps) {
    values[index] = steps;
  }

  List<List<int>?> toList() {
    var list = <List<int>?>[];
    for (var step in values) {
      list.add(step.toList());
    }
    return list;
  }

  @override
  String toString() {
    return toList().toString();
  }
}

import 'package:tekartik_audio_web/src/import.dart';
import 'package:tekartik_audio_web/src/instrument.dart';
import 'package:tekartik_audio_web/src/sequencer/steps.dart';
import 'package:tekartik_audio_web/src/sequencer/steps_group.dart';

class Pattern {
  int? version = 1;
  int? id;
  String? name;

  static final String idKey = r'_id';
  static final String nameKey = r'name';
  static final String stepsKey = r'steps';

  // total number of steps in the pattern
  int? _stepCount;
  List<Instrument>? instruments;
  StepsGroup? _steps;

  StepsGroup? get steps => _steps;

  // total number of step in the beat (1 for metronome, 2 or 4 for standard drum beat)
  int? _beatStepCount;
  static int maxStepCount = 128;
  static int defaultStepCount = 16;

  int get stepCount {
    return _stepCount!;
  }

  int? getInstrumentIndex(Instrument instrument) {
    for (var i = 0; i < instruments!.length; i++) {
      if (instruments![i] == instrument) {
        return i;
      }
    }
    return null;
  }

  set stepCount(int newStepCount) {
    if (newStepCount > maxStepCount) {
      newStepCount = maxStepCount;
    }
    if (newStepCount == _stepCount) {
      return;
    }

    var currentStepCount = stepCount;

    // Check allocated
    if (_steps != null) {
      currentStepCount = _steps!.stepsLength;
    }
    if (newStepCount > currentStepCount) {
      for (var j = 0; j < instruments!.length; j++) {
        for (var i = 0; i < newStepCount - currentStepCount; i++) {
          _steps![j].add(0);
        }
      }
    }

    _stepCount = newStepCount;
  }

  // number of step in a beat
  int get beatStepCount {
    return _beatStepCount ?? 1;
  }

  // this stop change also the total number of beat in the song
  void changeBeatStepCount(int newBeatStepCount) {
    if (newBeatStepCount == _beatStepCount) {
      return;
    }
    var currentStepCount = stepCount;

    num ratio = newBeatStepCount / beatStepCount;
    num ratioInv = 1 / ratio;

    // update step count...OR NOT finally...
    stepCount = (stepCount * ratio).round().toInt();

    // Fix tap at the proper location
    for (var j = 0; j < instruments!.length; j++) {
      var newSteps = Steps();
      var oldSteps = _steps![j];
      num oldIReal = 0;
      var oldI = 0;
      var oldITaken = false;
      for (var i = 0; i < stepCount; i++) {
        int oldIRound;
        if ((i % newBeatStepCount) == 0) {
          oldIRound = oldIReal.round().toInt();
        } else {
          oldIRound = oldIReal.floor().toInt();
        }
        if (oldIRound > oldI) {
          oldI = oldIRound;
          oldITaken = false;
        }

        // print('-${i} ${oldIReal} ${oldI} ${oldITaken}');

        if (oldI >= currentStepCount) {
          newSteps.add(0);
        } else {
          if ((oldIRound == oldI) && (!oldITaken)) {
            newSteps.add(oldSteps[oldI]);
            oldITaken = true;
          } else {
            newSteps.add(0);
          }
        }

        // print('+${i} ${oldIReal} ${oldI} ${oldITaken} ${realIInOld}');

        oldIReal += ratioInv;
      }

      _steps![j] = newSteps;
    }

    _beatStepCount = newBeatStepCount;
  }

  set beatStepCount(int newBeatStepCount) {
    _beatStepCount = newBeatStepCount;
  }

  Map toMap() {
    var map = <String, dynamic>{};
    map['version'] = version;
    if (instruments != null) {
      var instrumentNames = <String?>[];
      for (var instrument in instruments!) {
        instrumentNames.add(instrument.name);
      }
      map['instruments'] = instrumentNames;
    }

    map['beatStepCount'] = beatStepCount;
    map['name'] = name;
    map[idKey] = id;

    // Make sure to cut the beats where needed
    if (_steps != null) {
      if ((instruments!.isNotEmpty) && (_stepCount != _steps![0].length)) {
        var newSteps = StepsGroup();
        for (var instrument = 0;
            instrument < instruments!.length;
            instrument++) {
          var instrumentSteps = Steps();
          newSteps.add(instrumentSteps);
          for (var i = 0; i < _stepCount!; i++) {
            instrumentSteps.add(getStepValue(instrument, i));
          }
        }
        map['steps'] = newSteps.toList();
      } else {
        map['steps'] = _steps!.toList();
      }
    }
    return map;
  }

  /// Empty pattern.
  Pattern();

  Pattern.fromJsonString(String json) {
    _fromJsonString(json);
  }

  /// After importing from map
  int addInstrument(Instrument instrument) {
    var index = instruments!.length;
    instruments!.add(instrument);
    _addNewInstrumentSteps();
    return index;
  }

  int findInstrument(Instrument instrument) {
    return instruments!.indexOf(instrument);
  }

  void removeInstrument(Instrument instrument) {
    var index = findInstrument(instrument);
    if (index >= 0) {
      removeInstrumentByIndex(index);
    }
  }

  void removeInstrumentByIndex(int instrumentIndex) {
    instruments!.removeRange(instrumentIndex, instrumentIndex + 1);
    _steps!.values.removeRange(instrumentIndex, instrumentIndex + 1);
  }

  void _fromJsonString(String json) {
    var map = jsonDecode(json) as Map;
    fromMap(map);
  }

  void _addNewInstrumentSteps() {
    var instrumentSteps = Steps(_stepCount!);
    _steps!.add(instrumentSteps);
  }

  set steps(StepsGroup? steps) {
    _steps = steps;
    if ((_steps != null) && (_steps!.length > 0)) {
      _stepCount = _steps![0].length;
    } else {
      _stepCount = defaultStepCount;
    }
  }

  void fromMap(Map map) {
    id = map[idKey] as int?;
    name = map[nameKey] as String?;
    version = map['version'] as int?;
    version ??= 1;

    var instrumentNameList = map['instruments'];
    if (instrumentNameList is List) {
      instruments = [];

      for (var instrumentName in instrumentNameList) {
        instruments!.add(Instrument(instrumentName as String?));
      }
    }
    var stepsDef = map['steps'] as List?;
    if (stepsDef == null) {
      // compat
      if (map['beats'] != null) {
        print('WARNING OLD PATTERN FORMAT');
        stepsDef = map['beats'] as List?;
      }
    }
    if (stepsDef != null) {
      steps = StepsGroup.fromList(cloneList(stepsDef));
    }

    var stepCount = map['stepCount'] as int?;
    if (stepCount != null) {
      _stepCount = stepCount;
    }
    /*
    _stepCount = map['stepCount'];

    if (_stepCount == null) {
      if ((_steps != null) && (_steps.length > 0)) {
        _stepCount = _steps[0].length;
      } else {
        _stepCount = DEFAULT_STEP_COUNT;
      }
    }
    */

    // Fill missing steps
    if (instruments != null) {
      while (_steps!.length < instruments!.length) {
        _addNewInstrumentSteps();
      }
    }

    _beatStepCount = map['beatStepCount'] as int?;
    _beatStepCount ??= 1; //_stepCount;

    if (_stepCount != null && _beatStepCount! > _stepCount!) {
      _beatStepCount = _stepCount;
    }
  }

  int getStepValue(int instrumentIndex, int stepIndex) {
    return _steps![instrumentIndex][stepIndex];
  }

  void setStepValue(int instrumentIndex, int stepIndex, int value) {
    _steps![instrumentIndex][stepIndex] = value;
  }

  /*
  int getLevel10000(int instrumentIndex, int stepIndex) {
    return (levels[instrumentIndex] * getStepValue(instrumentIndex, stepIndex));
  }
  */
  @override
  String toString() {
    return toMap().toString();
  }
}

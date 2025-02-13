class TempoListRange {
  late int value;
  int? diff;
}

class TempoList {
  /*
TempoList.prototype.initDefault = function() {
  this.addRange(40, 2);
  this.addRange(60, 3);
  this.addRange(72, 4);
  this.addRange(120, 6);
  this.addRange(144, 8);
  this.addRange(240, 10);
  this.addRange(320, 0);
};
*/
  int findInsertionPosition(int value) {
    for (var i = 0; i < ranges!.length; i++) {
      var currentRange = ranges![i];
      if (currentRange.value > value) {
        return i;
      }
    }
    return ranges!.length + 1;
  }

  /*
TempoList.prototype.findValueIndex = function(value) {
  this.generateIfNeeded();
  return this.values.indexOf(value);
};


TempoList.prototype.findValueNearestIndex = function(value) {
  var index = this.findValueIndex(value);
  if (index !== -1) {
    return index;
  }
  // Slow way
  var count = this.getCount();
  var i1 = 0;
  var i2 = count - 1;
  var v1 = this.getValue(i1);
  var v2 = this.getValue(i2);

  while (i2 > i1 + 1) {
    
    index = Math.round((i1 + i2) / 2);
    
    if (this.getValue(index) > value) {
      i2 = index;
      v2 = this.getValue(i2);
    } else {
      i1 = index;
      v1 = this.getValue(i1);
    }
  }
  
  // Nearest win
  if (v2 - value < value - v1) {
    return i2;
  } else {
    return i1;
  }
};

TempoList.prototype.generateIfNeeded = function() {
  if (!this.values) {
    this.generateValues();
  }
};
*/
  //var values;
  List<TempoListRange>? ranges;

  void addRange(int value, int diff) {
    // Invalidation existings
    //values = null;

    ranges ??= <TempoListRange>[];

    var range = TempoListRange();
    range.value = value;
    range.diff = diff;

    var pos = findInsertionPosition(value);
    ranges!.insert(
      pos,
      range,
    ); //, element)setRange(start, end, iterable)in(pos, 1);
    //ranges[pos] = range;
  }

  /*
TempoList.prototype.generateValues = function() {
  this.values = [];
  var ranges = this.ranges;
  var value = undefined;
  var i, j;
  
  if (ranges.length === 0) {
    return;
  }
  for (i = 0; i < ranges.length - 1; i++) {
    var nextLimit = ranges[i + 1].value;
    var currentRange = ranges[i];

    value = currentRange.value;
    do {
      this.values.push(value);
      value += currentRange.diff;
    } while (value < nextLimit);
  }
  
  // Push last
  this.values.push(ranges[i].value);
};

TempoList.prototype.getCount = function() {
  if (!this.values) {
    this.generateValues();
  }
  return this.values.length;
};

TempoList.prototype.getValue = function(index) {
  this.generateIfNeeded();
  return this.values[index];
};

TempoList.prototype.getMin = function() {
  return this.getValue(0);
};

TempoList.prototype.getMax = function() {
  return this.getValue(this.getCount() - 1);
};
*/
}

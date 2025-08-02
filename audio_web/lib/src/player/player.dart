import 'package:tekartik_audio_web/audio_web.dart';
import 'package:tekartik_audio_web/src/audio_kit.dart';
import 'package:tekartik_audio_web/src/import.dart';
import 'package:tekartik_audio_web/src/instrument.dart';
import 'package:tekartik_audio_web/src/sequencer/sequencer.dart';
import 'package:tekartik_audio_web/src/sequencer/sequencer_event.dart';
import 'package:tekartik_audio_web/src/sequencer/song.dart';
import 'package:tekartik_common_utils/log_utils.dart';
import 'package:web/web.dart' as web;

typedef PlayerCallback = void Function();

/// Single gain and source node for all items in a group
class GroupedInstrumentNode {
  web.AudioBufferSourceNode? source;
  Player player;
  late web.GainNode gain;

  GroupedInstrumentNode(this.player) {
    var ctx = player.audioContext!;

    // Single gain node and source node for all items in the same group
    gain = ctx.createGain();
    var mixNode = player.mixNode!;
    gain.connect(mixNode);
  }
}

class InstrumentNode {
  GroupedInstrumentNode? group;
  Player player;
  AudioSample? sample;

  static double faceDuration = 0.05;

  InstrumentNode(this.player, this.sample, [this.group]) {
    group ??= GroupedInstrumentNode(player);
  }

  void noteOn(num time, num volume) {
    var ctx = player.audioContext!;
    var gain = group!.gain.gain;

    gain.setValueAtTime(gain.value, time - faceDuration);
    gain.linearRampToValueAtTime(0, time);
    gain.setValueAtTime(volume, time);
    if (group!.source != null) {
      group!.source!.stop(time);
    }
    // source.noteOff(time); // + Math.random() / 50);
    group!.source = ctx.createBufferSource();
    group!.source!.connect(group!.gain);
    group!.source!.buffer = sample!.buffer;
    group!.source!.start(time); // + Math.random() / 50);
    //    if (player.logger.debugEnabled) {
    //      player.logger.debug('${time} ${volume}');
    //    }
  }
}

class Player {
  static DevFlag debug = DevFlag('Player');

  // Url to drumkit sound folder (and .json file corresponding)
  String? url;

  // drumkit json
  String? defUrl;

  web.AudioContext? audioContext;

  late AudioKit audioKit;

  web.AudioNode? mixNode;

  web.GainNode? gainNode;

  late Sequencer _sequencer;

  Timer? _timer;

  num? startTime;

  bool windowHasFocus = true;

  late Logger logger;

  bool get playing => _sequencer.playing;

  // Each instrument has a gain node
  late Map<Instrument?, InstrumentNode> instrumentNodes;
  late Map<Instrument?, GroupedInstrumentNode?> groupInstrumentNodes;

  Player({this.defUrl}) {
    logger = Logger('Player');
    // logger.debugEnabled = true;
    // logger.debug('Player:debug');

    instrumentNodes = <Instrument?, InstrumentNode>{};
    groupInstrumentNodes = <Instrument?, GroupedInstrumentNode?>{};

    // windowAsFocus = window..h
    _sequencer = Sequencer();
    _sequencer.callback = (SequencerEvent e) {
      onSequencerEvent(e);
    };
    web.EventStreamProviders.focusEvent.forTarget(web.window).listen((
      web.Event event,
    ) {
      windowHasFocus = true;
    });
    web.EventStreamProviders.blurEvent.forTarget(web.window).listen((
      web.Event event,
    ) {
      windowHasFocus = false;
    });
  }

  set tempo(num tempo) {
    _sequencer.updateTempo(tempo, getCurrentTime());
  }

  num get tempo => _sequencer.tempo;

  set volume(num volume) {
    // _sequencer.updateTempo(tempo, getCurrentTime());
    gainNode!.gain.value = (volume * volume) / 10000;
  }

  static final int scheduleDelayMs = 50;
  static final double firstTimeDelay = 0.25;
  static final double scheduleDuration = 0.2;

  void onSequencerEvent(SequencerEvent e) {
    //print(e);
    if (logger.isLoggable(Level.FINER)) {
      logger.finer(e.toString());
    }
    if (e is NoteOnEvent) {
      var noteOnEvent = e;
      playInstrument(noteOnEvent.instrument, noteOnEvent.volume!, e.time!);
    }
  }

  Future init() async {
    audioContext = web.AudioContext();
    if (audioContext != null) {
      // Default
      mixNode = audioContext!.destination;

      var compressor = audioContext!.createDynamicsCompressor();

      compressor.connect(mixNode!, 0, 0);
      mixNode = compressor;

      gainNode = audioContext!.createGain();
      gainNode!.gain.value = 1;
      gainNode!.connect(mixNode!, 0, 0);
      mixNode = gainNode;

      audioKit = AudioKit();

      // defUrl must be set at this point!
      await audioKit.loadKit(audioContext, defUrl!, url);
      // audioKit.loadInstruments(audioContext, () => callback());
    }
  }

  num? nextScheduleTime;
  late num lastScheduleTime;

  void _scheduleAt(num time) {
    //if (debug.on) {
    //  print('[player] scheduling at ${time.toStringAsPrecision(3)}');
    //}
    nextScheduleTime = time + scheduleDuration;
    lastScheduleTime = time;

    _sequencer.schedule(time, nextScheduleTime);
  }

  num getCurrentTime() {
    if (startTime == null) {
      setStartTime();
    }
    return _getCurrentTime();
  }

  num _getCurrentTime() {
    return audioContext!.currentTime - startTime!;
  }

  set song(Song song) {
    _sequencer.updateSong(song, getCurrentTime());
  }

  void _schedule() {
    var currentTime = _getCurrentTime();

    // Handle inactive tab with poor refresh
    if (currentTime > nextScheduleTime!) {
      print('Sequencer timer called too late - TODO handle tab switching');

      if (!windowHasFocus) {
        /*
        this.delegate.notify({
          err : Sequencer.ERR_TIMER_LATE
        });
        this.delegate.onStop();
        return;
        */
        stop();
        return;
      }
    }

    if (currentTime > lastScheduleTime) {
      _scheduleAt(currentTime);
    }
    _nextSchedule();
  }

  void _nextSchedule() {
    if (playing) {
      _timer = Timer(Duration(milliseconds: scheduleDelayMs), _schedule);
    }
  }

  void stop() {
    _sequencer.stop();
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void setStartTime() {
    startTime = audioContext!.currentTime;
    if (startTime! < firstTimeDelay) {
      startTime = firstTimeDelay;
    }
  }

  void start() {
    stop();
    setStartTime();

    _sequencer.start();
    _scheduleAt(0.0);
    _nextSchedule();
  }

  void playInstrument(Instrument? instrument, num volume, num time) {
    if (Player.debug.on) {
      print(
        '[player] play $instrument vol ${volume.toStringAsPrecision(1)} at ${time.toStringAsFixed(2)}',
      );
    }
    //Instrument instrument = new Instrument(instrumentName);
    var audioSample = audioKit.samples[instrument!];

    var instrumentNode = instrumentNodes[instrument];
    if (instrumentNode == null) {
      // Belongs to a group?
      var group = audioKit.groupMap[instrument];
      GroupedInstrumentNode? groupedInstrumentNode;
      if (group != null) {
        // find existing group instrument nodes

        for (var groupInstrument in group) {
          groupedInstrumentNode = groupInstrumentNodes[groupInstrument];
          if (groupedInstrumentNode != null) {
            groupInstrumentNodes[instrument] = groupedInstrumentNode;
          }
        }
        groupedInstrumentNode = groupInstrumentNodes[instrument] ??=
            GroupedInstrumentNode(this);

        // print(groupedInstrumentNode);
      }
      instrumentNode = InstrumentNode(this, audioSample, groupedInstrumentNode);
      instrumentNodes[instrument] = instrumentNode;
    }
    instrumentNode.noteOn(time + startTime!, volume);
    /*
    GainNode gainNode = instrumentGainNode[instrument];
    if (gainNode == null) {
      gainNode = audioContext.createGainNode();
    }
    _playSample(audioSample, volume, time);
    */
  }

  /*
  void _playSample(AudioSample audioSample, num volume, num time) {
    GainNode noteGainNode = audioContext.createGain();
    noteGainNode.gain.value = volume; // + Math.random() / 10;
    noteGainNode.connectNode(mixNode, 0);

    AudioBufferSourceNode source = audioContext.createBufferSource();
    source.buffer = audioSample.buffer;
    source.connectNode(noteGainNode, 0);
    source.start(time + startTime); // + Math.random() / 50);
  }
  */
}

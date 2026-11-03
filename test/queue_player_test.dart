import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:insta_playlist/models/song.dart';
import 'package:insta_playlist/state/queue_player.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stands in for the native player: keeps the current index in step with
/// playlist edits the way the real ones do, and reports it back.
class _FakePlayer extends AudioPlayerPlatform {
  final _events = StreamController<PlaybackEventMessage>.broadcast();
  int _index = 0;
  int _length = 0;

  _FakePlayer(super.id);

  void _emit() => _events.add(
    PlaybackEventMessage(
      processingState: ProcessingStateMessage.ready,
      updateTime: DateTime.now(),
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      duration: const Duration(minutes: 3),
      icyMetadata: null,
      currentIndex: _index,
      androidAudioSessionId: null,
    ),
  );

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final playlist = request.audioSourceMessage as ConcatenatingAudioSourceMessage;
    _length = playlist.children.length;
    _index = request.initialIndex ?? 0;
    _emit();
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
    ConcatenatingInsertAllRequest request,
  ) async {
    if (request.index <= _index) _index += request.children.length;
    _length += request.children.length;
    _emit();
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
    ConcatenatingRemoveRangeRequest request,
  ) async {
    final removed = request.endIndex - request.startIndex;
    if (request.endIndex <= _index) _index -= removed;
    _length -= removed;
    _emit();
    return ConcatenatingRemoveRangeResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    if (request.index != null) _index = request.index!.clamp(0, _length - 1);
    _emit();
    return SeekResponse();
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();
  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();
  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async => SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async => SetSpeedResponse();
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async => SetPitchResponse();
  @override
  Future<SetSkipSilenceResponse> setSkipSilence(SetSkipSilenceRequest request) async =>
      SetSkipSilenceResponse();
  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(SetShuffleModeRequest request) async =>
      SetShuffleModeResponse();
  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(SetShuffleOrderRequest request) async =>
      SetShuffleOrderResponse();
  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async => DisposeResponse();
}

class _FakePlatform extends JustAudioPlatform with MockPlatformInterfaceMixin {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async => _FakePlayer(request.id);

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest request) async =>
      DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(DisposeAllPlayersRequest request) async =>
      DisposeAllPlayersResponse();
}

Song _song(String name) => Song(filePath: '/music/$name.mp3', title: name);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => JustAudioPlatform.instance = _FakePlatform());

  final a = _song('a'), b = _song('b'), c = _song('c'), d = _song('d'), e = _song('e');

  List<String> titlesOf(QueuePlayer player) => [for (final s in player.queue) s.title];

  Future<QueuePlayer> playing(List<Song> queue, int start, QueueSource source) async {
    final player = QueuePlayer();
    await player.setQueue(queue, startIndex: start, source: source);
    await pumpEventQueue();
    return player;
  }

  test('a Mix queue follows new results around the playing song', () async {
    final player = await playing([a, b, c], 1, QueueSource.mix);
    expect(player.currentSong?.title, 'b');

    await player.updateMixQueue([d, b, e, a]);
    await pumpEventQueue();
    expect(titlesOf(player), ['d', 'b', 'e', 'a']);
    expect(player.currentSong?.title, 'b');
    expect(player.queueIndex, 1);
  });

  test('if the playing song drops out, it finishes and the new results follow', () async {
    final player = await playing([a, b, c], 1, QueueSource.mix);

    await player.updateMixQueue([d, e]);
    await pumpEventQueue();
    expect(titlesOf(player), ['b', 'd', 'e']);
    expect(player.currentSong?.title, 'b');
    expect(player.hasPrevious, isFalse);
  });

  test('no matches leaves just the playing song', () async {
    final player = await playing([a, b, c], 2, QueueSource.mix);

    await player.updateMixQueue([]);
    await pumpEventQueue();
    expect(titlesOf(player), ['c']);
    expect(player.hasNext, isFalse);
  });

  test('a Library queue ignores Mix changes', () async {
    final player = await playing([a, b, c], 0, QueueSource.library);

    await player.updateMixQueue([d]);
    await pumpEventQueue();
    expect(titlesOf(player), ['a', 'b', 'c']);
  });

  test('next and previous move through the queue', () async {
    final player = await playing([a, b, c], 0, QueueSource.library);
    await player.next();
    await pumpEventQueue();
    expect(player.currentSong?.title, 'b');
    await player.previous();
    await pumpEventQueue();
    expect(player.currentSong?.title, 'a');
  });
}

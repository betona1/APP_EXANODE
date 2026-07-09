/// 효과음 재생 — 프로토타입(crdl.html)의 WebAudio beep/물소리를 미리 합성한
/// WAV 에셋으로 재생. 짧은 효과음이 겹칠 수 있어 플레이어 풀을 라운드로빈.
library;

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

enum Sfx { start, move, eat, clear, lose, thud, water, splash, bubble, star }

const _asset = {
  Sfx.start: 'sfx/start.wav',
  Sfx.move: 'sfx/move.wav',
  Sfx.eat: 'sfx/eat.wav',
  Sfx.clear: 'sfx/clear.wav',
  Sfx.lose: 'sfx/lose.wav',
  Sfx.thud: 'sfx/thud.wav',
  Sfx.water: 'sfx/water.wav',
  Sfx.splash: 'sfx/splash.wav',
  Sfx.bubble: 'sfx/bubble.wav',
  Sfx.star: 'sfx/star.wav',
};

class AudioService {
  bool enabled;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _waterLoop;
  bool _ready = false;

  AudioService({this.enabled = true});

  Future<void> init() async {
    // 저지연 효과음용 플레이어 풀
    for (var i = 0; i < 6; i++) {
      final p = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
    }
    _waterLoop = AudioPlayer()..setPlayerMode(PlayerMode.mediaPlayer);
    await _waterLoop!.setReleaseMode(ReleaseMode.stop);
    _ready = true;
  }

  void play(Sfx s, {double volume = 1.0}) {
    if (!enabled || !_ready) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    // fire-and-forget
    p.stop().then((_) {
      p.setVolume(volume);
      p.play(AssetSource(_asset[s]!), volume: volume);
    }).catchError((_) {});
  }

  double _waterVol = 0.7;
  Timer? _fade;

  /// 물 흐르는 소리 (클리어 연출 동안 한 번 재생, 루프 없음 — 이음새 클릭 방지).
  void startWater({double volume = 0.7}) {
    if (!enabled || !_ready) return;
    _fade?.cancel();
    _waterVol = volume;
    _waterLoop
      ?..setReleaseMode(ReleaseMode.stop)
      ..setVolume(volume)
      ..play(AssetSource(_asset[Sfx.water]!), volume: volume).catchError((_) {});
  }

  /// 급정지 클릭음을 없애려 볼륨을 부드럽게 낮춘 뒤 정지.
  void stopWater() {
    if (_waterLoop == null) return;
    _fade?.cancel();
    var v = _waterVol;
    _fade = Timer.periodic(const Duration(milliseconds: 40), (t) {
      v -= _waterVol / 8; // ~320ms 페이드
      if (v <= 0) {
        t.cancel();
        _waterLoop?.stop().catchError((_) {});
      } else {
        _waterLoop?.setVolume(v).catchError((_) {});
      }
    });
  }

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    await _waterLoop?.dispose();
  }
}

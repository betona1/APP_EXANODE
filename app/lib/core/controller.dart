/// 게임 진행 컨트롤러 — GameState + 타이머 + 별점 + 기록 저장.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'game.dart';
import 'levelgen.dart';
import 'progress.dart';

enum ClearPhase { none, playing, waterFlow, banner }

class GameController extends ChangeNotifier {
  final Progress progress;
  Genre genre;
  int stage;

  late Level level;
  late GameState game;
  Timer? _tick;
  final Stopwatch _watch = Stopwatch();
  double elapsed = 0;
  ClearPhase phase = ClearPhase.none;
  int earnedStars = 0;
  bool newRecord = false;
  MoveResult? lastResult;
  String? loseReason;

  GameController(this.progress)
      : genre = progress.genre,
        stage = progress.stage(progress.genre) {
    _newBoard();
  }

  StageConfig get config => stageConfig(stage);
  bool get tutorial => config.tutorial;
  int get unlocked => progress.maxStage(genre) + 1;

  void _newBoard() {
    level = generateStage(genre == Genre.fill ? 'fill' : 'path', stage);
    game = GameState(level, genre);
    _watch
      ..stop()
      ..reset();
    _tick?.cancel();
    elapsed = 0;
    phase = ClearPhase.none;
    earnedStars = 0;
    newRecord = false;
    lastResult = null;
    loseReason = null;
  }

  void selectStage(int s) {
    stage = s;
    progress.setStage(genre, s);
    _newBoard();
    notifyListeners();
  }

  void setGenre(Genre g) {
    genre = g;
    progress.setGenre(g);
    stage = progress.stage(g);
    _newBoard();
    notifyListeners();
  }

  void retry() {
    _newBoard();
    notifyListeners();
  }

  void nextStage() => selectStage(stage + 1);

  void _startTimer() {
    if (_watch.isRunning) return;
    _watch.start();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      elapsed = _watch.elapsedMilliseconds / 1000.0;
      notifyListeners();
    });
  }

  bool tapCell(int r, int c) {
    if (game.over || phase != ClearPhase.none && phase != ClearPhase.playing) {
      return false;
    }
    if (game.head == null) {
      if (game.startAt(r, c)) {
        _startTimer();
        phase = ClearPhase.playing;
        notifyListeners();
        return true;
      }
      return false;
    }
    // 인접 칸 탭 → 그 방향으로 한 칸
    final dr = r - game.head!.$1, dc = c - game.head!.$2;
    if (dr.abs() + dc.abs() != 1) return false;
    final dir =
        MoveDir.values.firstWhere((d) => d.dr == dr && d.dc == dc);
    return move(dir);
  }

  bool move(MoveDir dir) {
    if (game.over) return false;
    if (game.head == null) return false;
    _startTimer();
    final res = game.move(dir);
    lastResult = res;
    if (res == MoveResult.blocked) return false;
    if (res == MoveResult.won) {
      _watch.stop();
      _tick?.cancel();
      elapsed = _watch.elapsedMilliseconds / 1000.0;
      _onWin();
    } else if (res != MoveResult.moved) {
      _watch.stop();
      _tick?.cancel();
      loseReason = switch (res) {
        MoveResult.lostDeadEnd => '막다른 길! 더 이상 이동할 수 없어요.',
        MoveResult.lostTrapped => '미로처럼 엉켰어요. 갇힌 칸이 생겼습니다.',
        MoveResult.lostNumberCut => '다음 숫자로 가는 길이 막혔어요.',
        _ => null,
      };
      phase = ClearPhase.banner;
    }
    notifyListeners();
    return true;
  }

  int _starsFor() {
    final base = game.total.toDouble();
    final p3 = genre == Genre.fill ? base * 0.8 + 2 : base * 0.5 + 2;
    final p2 = genre == Genre.fill ? base * 1.8 + 5 : base * 1.2 + 4;
    return elapsed <= p3 ? 3 : elapsed <= p2 ? 2 : 1;
  }

  void _onWin() {
    earnedStars = _starsFor();
    final b = progress.best(genre, stage);
    final bStars = b?.stars ?? 0;
    if (b == null ||
        earnedStars > bStars ||
        (earnedStars == bStars && elapsed < b.time)) {
      progress.setBest(
          genre,
          stage,
          BestRecord(game.path.length - 1, elapsed,
              earnedStars > bStars ? earnedStars : bStars));
      newRecord = true;
    }
    if (stage > progress.maxStage(genre)) {
      progress.setMaxStage(genre, stage);
    }
    phase = ClearPhase.waterFlow; // UI가 물 연출 후 banner 로 전환
  }

  void waterFlowDone() {
    phase = ClearPhase.banner;
    notifyListeners();
  }

  void undo() {
    if (phase == ClearPhase.waterFlow) return;
    if (game.path.isEmpty) return;
    game.undo();
    phase = game.head == null ? ClearPhase.none : ClearPhase.playing;
    loseReason = null;
    notifyListeners();
  }

  /// 튜토리얼 안내: 플레이어 경로가 정답 접두사와 일치할 때 다음 정답 칸.
  (int, int)? get guideCell {
    if (!tutorial || stage != 1) return null;
    if (game.head == null || game.over) return null;
    for (var i = 0; i < game.path.length; i++) {
      if (game.path[i] != level.solution[i]) return null;
    }
    if (game.path.length >= level.solution.length) return null;
    return level.solution[game.path.length];
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}

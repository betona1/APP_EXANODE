/// CRDL 레벨 생성기 — 프로토타입(crdl.html)의 backbite 해밀턴 경로 생성과
/// **동일한 난수 소비 순서**로 포팅. 같은 시드 → 같은 레벨 보장.
library;

import 'rng.dart';

const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];

List<(int, int)> neighbors(int r, int c, int rows, int cols) {
  final o = <(int, int)>[];
  for (final (dr, dc) in dirs) {
    final nr = r + dr, nc = c + dc;
    if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) o.add((nr, nc));
  }
  return o;
}

int cellKey(int r, int c, int cols) => r * cols + c;

/// 지그재그 해밀턴 경로.
List<(int, int)> snakePath(int rows, int cols) {
  final p = <(int, int)>[];
  for (var r = 0; r < rows; r++) {
    if (r.isEven) {
      for (var c = 0; c < cols; c++) {
        p.add((r, c));
      }
    } else {
      for (var c = cols - 1; c >= 0; c--) {
        p.add((r, c));
      }
    }
  }
  return p;
}

/// backbite: 해밀턴 성질을 유지한 채 경로 무작위화 (JS와 동일한 rng 소비 순서).
List<(int, int)> backbite(List<(int, int)> path, int rows, int cols, int iters, Mulberry32 rng) {
  final len = path.length;
  final pos = List<int>.filled(rows * cols, 0);
  for (var i = 0; i < len; i++) {
    pos[cellKey(path[i].$1, path[i].$2, cols)] = i;
  }
  for (var it = 0; it < iters; it++) {
    if (rng.nextDouble() < .5) {
      final (hr, hc) = path[0];
      final cs = neighbors(hr, hc, rows, cols)
          .where((p) => pos[cellKey(p.$1, p.$2, cols)] >= 2)
          .toList();
      if (cs.isEmpty) continue;
      final pick = cs[(rng.nextDouble() * cs.length).floor()];
      final j = pos[cellKey(pick.$1, pick.$2, cols)];
      for (var a = 0, b = j - 1; a < b; a++, b--) {
        final t = path[a];
        path[a] = path[b];
        path[b] = t;
      }
      for (var i = 0; i < j; i++) {
        pos[cellKey(path[i].$1, path[i].$2, cols)] = i;
      }
    } else {
      final (tr, tc) = path[len - 1];
      final cs = neighbors(tr, tc, rows, cols)
          .where((p) => pos[cellKey(p.$1, p.$2, cols)] <= len - 3)
          .toList();
      if (cs.isEmpty) continue;
      final pick = cs[(rng.nextDouble() * cs.length).floor()];
      final j = pos[cellKey(pick.$1, pick.$2, cols)];
      for (var a = j + 1, b = len - 1; a < b; a++, b--) {
        final t = path[a];
        path[a] = path[b];
        path[b] = t;
      }
      for (var i = j + 1; i < len; i++) {
        pos[cellKey(path[i].$1, path[i].$2, cols)] = i;
      }
    }
  }
  return path;
}

class Level {
  final int rows, cols, count;
  final Map<int, int> numAt; // cellKey -> 숫자(1..count)
  final List<(int, int)> solution;
  Level(this.rows, this.cols, this.count, this.numAt, this.solution);
}

/// 경로를 먼저 만들고 숫자를 심는다 → 반드시 풀리는 레벨.
Level generate(int rows, int cols, int count, Mulberry32 rng) {
  final path = backbite(snakePath(rows, cols), rows, cols, 8 * rows * cols, rng);
  final len = path.length;
  count = count < len ? count : len;
  final idxSet = <int>{};
  for (var k = 0; k < count; k++) {
    idxSet.add((k * (len - 1) / (count - 1)).round());
  }
  final idx = idxSet.toList()..sort();
  final numAt = <int, int>{};
  for (var k = 0; k < idx.length; k++) {
    final (r, c) = path[idx[k]];
    numAt[cellKey(r, c, cols)] = k + 1;
  }
  return Level(rows, cols, idx.length, numAt, path);
}

/// 스테이지 → 보드 크기/숫자 개수/티어 (프로토타입 stageConfig와 동일).
class StageConfig {
  final int rows, cols, numbers;
  final String tier;
  final bool tutorial;
  const StageConfig(this.rows, this.cols, this.numbers, this.tier, {this.tutorial = false});
}

StageConfig stageConfig(int s) {
  if (s == 1) return const StageConfig(3, 3, 3, '튜토리얼 1/3', tutorial: true);
  if (s == 2) return const StageConfig(3, 4, 3, '튜토리얼 2/3', tutorial: true);
  if (s == 3) return const StageConfig(4, 4, 4, '튜토리얼 3/3', tutorial: true);
  if (s == 4) return const StageConfig(5, 4, 5, '첫 실전');
  if (s <= 10) return const StageConfig(5, 4, 5, '초급');
  if (s <= 25) return const StageConfig(6, 5, 6, '쉬움');
  if (s <= 45) return const StageConfig(8, 6, 10, '보통');
  if (s <= 70) return const StageConfig(11, 7, 12, '어려움');
  return const StageConfig(13, 8, 14, '고수');
}

/// 스테이지용 레벨 생성 (프로토타입과 동일한 시드 규칙).
Level generateStage(String genre, int stage) {
  final cfg = stageConfig(stage);
  final rng = Mulberry32(stageSeed(genre, stage));
  return generate(cfg.rows, cfg.cols, cfg.numbers, rng);
}

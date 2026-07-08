/// 프로토타입(crdl.html) JS에서 추출한 골든 벡터와 Dart 포팅의 동일성 검증.
/// golden_levels.json 은 scratchpad/golden.js 가 실제 프로토타입 코드를 실행해 생성.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crdl/core/rng.dart';
import 'package:crdl/core/levelgen.dart';
import 'package:crdl/core/game.dart';

void main() {
  final golden = jsonDecode(
    File('test/golden_levels.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  group('JS 프로토타입과의 동일성 (골든 벡터 ${golden.length}개)', () {
    for (final entry in golden.entries) {
      test(entry.key, () {
        final g = entry.value as Map<String, dynamic>;
        final parts = entry.key.split('|');
        final genre = parts[0];
        final stage = int.parse(parts[1]);

        // 1) 시드 동일
        expect(stageSeed(genre, stage), g['seed'], reason: 'stageSeed 불일치');

        // 2) 보드 구성 동일
        final cfg = stageConfig(stage);
        expect(cfg.rows, g['R']);
        expect(cfg.cols, g['C']);
        expect(cfg.numbers, g['N']);

        // 3) 생성 결과(정답 경로 + 숫자 배치) 동일
        final lv = generateStage(genre, stage);
        final expSol = (g['solution'] as List)
            .map((p) => ((p as List)[0] as int, p[1] as int))
            .toList();
        expect(lv.solution, expSol, reason: 'solution 경로 불일치');
        final expNum = (g['numAt'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int));
        expect(lv.numAt, expNum, reason: 'numAt 배치 불일치');
        expect(lv.count, g['count']);
      });
    }
  });

  group('규칙 엔진', () {
    test('정답 경로를 따라가면 fill 클리어', () {
      final lv = generateStage('fill', 12);
      final game = GameState(lv, Genre.fill);
      final sol = lv.solution;
      expect(game.startAt(sol[0].$1, sol[0].$2), isTrue);
      MoveResult? last;
      for (var i = 1; i < sol.length; i++) {
        final dr = sol[i].$1 - sol[i - 1].$1, dc = sol[i].$2 - sol[i - 1].$2;
        final dir = MoveDir.values.firstWhere((d) => d.dr == dr && d.dc == dc);
        last = game.move(dir);
        if (i < sol.length - 1) {
          expect(last, MoveResult.moved, reason: '이동 $i에서 중단: $last');
        }
      }
      expect(last, MoveResult.won);
      expect(game.won, isTrue);
    });

    test('숫자 순서 게이트: 다음 숫자가 아니면 밟을 수 없음', () {
      final lv = generateStage('fill', 1); // 3x3, 숫자 3개
      final game = GameState(lv, Genre.fill);
      final sol = lv.solution;
      game.startAt(sol[0].$1, sol[0].$2);
      // 숫자 3(마지막)이 인접해 있어도 target이 2인 동안은 blocked 여야 함
      // → 전체 칸 중 숫자3 위치를 찾아 인접 시도(가능한 경우에만 의미 검증)
      final k3 = lv.numAt.entries.firstWhere((e) => e.value == 3).key;
      final r3 = k3 ~/ lv.cols, c3 = k3 % lv.cols;
      expect(game.canMove(r3, c3), isFalse,
          reason: 'target=2인데 숫자3 칸이 이동 가능하면 안 됨');
    });

    test('재통과 금지 + undo 복원', () {
      final lv = generateStage('fill', 4);
      final game = GameState(lv, Genre.fill);
      final sol = lv.solution;
      game.startAt(sol[0].$1, sol[0].$2);
      final dr = sol[1].$1 - sol[0].$1, dc = sol[1].$2 - sol[0].$2;
      final dir = MoveDir.values.firstWhere((d) => d.dr == dr && d.dc == dc);
      game.move(dir);
      // 방금 온 칸으로 되돌아가기는 금지
      final back = MoveDir.values.firstWhere((d) => d.dr == -dr && d.dc == -dc);
      expect(game.move(back), MoveResult.blocked);
      // undo 하면 머리가 시작칸으로, target 복원
      game.undo();
      expect(game.head, sol[0]);
      expect(game.path.length, 1);
    });

    test('번들 levels.json 형식과 동일한 검증: 솔루션이 항상 규칙을 통과', () {
      for (final stage in [2, 3, 8, 30, 50, 77]) {
        final lv = generateStage('fill', stage);
        final game = GameState(lv, Genre.fill);
        game.startAt(lv.solution[0].$1, lv.solution[0].$2);
        for (var i = 1; i < lv.solution.length; i++) {
          final dr = lv.solution[i].$1 - lv.solution[i - 1].$1;
          final dc = lv.solution[i].$2 - lv.solution[i - 1].$2;
          final dir = MoveDir.values.firstWhere((d) => d.dr == dr && d.dc == dc);
          final res = game.move(dir);
          expect(res == MoveResult.moved || res == MoveResult.won, isTrue,
              reason: 'stage $stage 이동 $i 실패: $res');
        }
        expect(game.won, isTrue, reason: 'stage $stage 미클리어');
      }
    });
  });
}

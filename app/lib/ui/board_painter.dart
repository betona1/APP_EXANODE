/// 게임 보드 렌더링 — 프로토타입의 renderPipes/trailD(구불구불 뱀 몸통),
/// 토큰, 물 클리어 연출을 CustomPainter로 이식.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/game.dart';
import 'mascot.dart';
import 'theme.dart';

class BoardGeometry {
  final int rows, cols;
  final double cell, pad;
  const BoardGeometry(this.rows, this.cols, this.cell, {this.pad = 6});

  Size get size =>
      Size(cols * cell + pad * 2, rows * cell + pad * 2);

  Offset center(int r, int c) =>
      Offset(pad + c * cell + cell / 2, pad + r * cell + cell / 2);

  Rect cellRect(int r, int c) => Rect.fromLTWH(
      pad + c * cell + 1.5, pad + r * cell + 1.5, cell - 3, cell - 3);

  (int, int)? cellAt(Offset p) {
    final c = ((p.dx - pad) / cell).floor();
    final r = ((p.dy - pad) / cell).floor();
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return (r, c);
  }
}

class BoardPainter extends CustomPainter {
  final GameController ctl;
  final BoardGeometry geo;
  final double animT; // 연속 티커 0~1 (펄스류)
  final double waterP; // 물 연출 진행 0~1 (연출 아닐 땐 0)
  final bool coachSpot; // 튜토리얼 스포트라이트 (시작 칸 하이라이트)

  BoardPainter(this.ctl, this.geo,
      {required this.animT, required this.waterP, this.coachSpot = false});

  GameState get g => ctl.game;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoardBase(canvas, size);
    _drawCells(canvas);
    final trail = _trailPath();
    if (trail != null) _drawSnake(canvas, trail);
    if (waterP > 0 && trail != null) _drawWater(canvas, trail);
    _drawTokens(canvas);
    _drawGuideArrow(canvas);
    if (g.head != null) _drawHead(canvas);
    if (coachSpot) _drawSpotlight(canvas, size);
  }

  void _drawBoardBase(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(14));
    canvas.drawRRect(
        rrect.shift(const Offset(0, 6)),
        Paint()
          ..color = Colors.black.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawRRect(rrect, Paint()..color = C.grid2);
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = C.grid);
  }

  void _drawCells(Canvas canvas) {
    for (var r = 0; r < geo.rows; r++) {
      for (var c = 0; c < geo.cols; c++) {
        final rect = geo.cellRect(r, c);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));
        final filled = g.filled[r][c];
        if (!filled) {
          canvas.drawRRect(rr, Paint()..color = C.ink2);
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * .45),
                  const Radius.circular(7)),
              Paint()..color = Colors.white.withValues(alpha: .025));
        } else if (waterP > 0) {
          // 물이 지나간 칸: 젖은 색
          final idx = g.path.indexWhere((p) => p.$1 == r && p.$2 == c);
          final reach = _reachedIndex();
          if (idx >= 0 && idx <= reach) {
            canvas.drawRRect(
                rr, Paint()..color = C.water.withValues(alpha: .12));
          }
        }
      }
    }
  }

  int _reachedIndex() =>
      math.min(g.path.length - 1, (waterP * (g.path.length - 1) + 1e-4).floor());

  /// trailD 포팅: 칸 중심 + 직선 구간 sine 웨이브 → 중점 스무딩 곡선.
  Path? _trailPath() {
    final pts = g.path.map((p) => geo.center(p.$1, p.$2)).toList();
    if (pts.isEmpty) return null;
    final amp = geo.cell * 0.11;
    for (var i = 1; i < pts.length - 1; i++) {
      final d1 = pts[i] - pts[i - 1];
      final d2 = pts[i + 1] - pts[i];
      if ((d1.dx - d2.dx).abs() < .01 && (d1.dy - d2.dy).abs() < .01) {
        final len = d1.distance;
        if (len > 0) {
          final s = i.isOdd ? 1.0 : -1.0;
          pts[i] += Offset(-d1.dy / len, d1.dx / len) * amp * s;
        }
      }
    }
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    if (pts.length == 1) {
      path.lineTo(pts[0].dx, pts[0].dy + .01);
      return path;
    }
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  void _drawSnake(Canvas canvas, Path trail) {
    final sw = math.max(7.0, geo.cell * 0.62);
    // 외곽
    canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF04121A));
    // 몸통 그라데이션
    final bounds = Offset.zero & geo.size;
    canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw * 0.68
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6FE89A), Color(0xFF3AD0A8), Color(0xFF2FA8C9)],
          ).createShader(bounds));
    // 비늘 (경로 대시)
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.52
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF032A2C).withValues(alpha: .28);
    final dashLen = 2.2, gapLen = math.max(6.0, geo.cell * 0.42);
    for (final metric in trail.computeMetrics()) {
      var d = gapLen / 2;
      while (d < metric.length) {
        final seg = metric.extractPath(d, math.min(d + dashLen, metric.length));
        canvas.drawPath(seg, dashPaint);
        d += dashLen + gapLen;
      }
    }
    // 등 광택
    canvas.save();
    canvas.translate(-sw * 0.11, -sw * 0.13);
    canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw * 0.16
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .34));
    canvas.restore();
  }

  void _drawWater(Canvas canvas, Path trail) {
    final sw = math.max(7.0, geo.cell * 0.62);
    final metrics = trail.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remain = total * Curves.easeInOut.transform(waterP);
    ui.Offset? tip;
    for (final m in metrics) {
      if (remain <= 0) break;
      final len = math.min(remain, m.length);
      final seg = m.extractPath(0, len);
      canvas.drawPath(
          seg,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw * 0.78
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = C.water.withValues(alpha: .96)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3));
      final tan = m.getTangentForOffset(len);
      if (tan != null) tip = tan.position;
      remain -= len;
    }
    // 물방울 헤드
    if (tip != null && waterP < 1) {
      canvas.drawCircle(
          tip,
          math.max(3, sw * 0.32),
          Paint()
            ..color = const Color(0xFFEAFCFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4));
    }
  }

  void _drawTokens(Canvas canvas) {
    final reach = waterP > 0 ? _reachedIndex() : -1;
    g.level.numAt.forEach((k, n) {
      final r = k ~/ geo.cols, c = k % geo.cols;
      final rect = geo.cellRect(r, c).deflate(geo.cell * 0.10);
      final eaten = n < g.target;
      final isNext = n == g.target && !g.over;
      final pathIdx = g.path.indexWhere((p) => p.$1 == r && p.$2 == c);
      final wet = reach >= 0 && pathIdx >= 0 && pathIdx <= reach;

      var scale = 1.0;
      if (isNext) scale = 1 + 0.09 * math.sin(animT * 2 * math.pi * 2.2);
      if (wet && waterP < 1) {
        // 물 도달 직후 스플래시 확대
        final hitP = pathIdx / math.max(1, g.path.length - 1);
        final since = (waterP - hitP).clamp(0.0, 0.12) / 0.12;
        scale = 1 + math.sin(since * math.pi) * 0.35;
      }
      final center = rect.center;
      final radius = rect.width / 2 * scale;

      final colors = wet
          ? const [Color(0xFFD8F6FF), C.water]
          : eaten
              ? const [Color(0xFFD5FFE6), C.eaten]
              : const [Color(0xFFFFF2C9), C.token];
      canvas.drawCircle(
          center.translate(0, 2),
          radius,
          Paint()
            ..color = Colors.black.withValues(alpha: .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.3, -.4),
              colors: colors,
            ).createShader(Rect.fromCircle(center: center, radius: radius)));
      if (isNext) {
        canvas.drawCircle(
            center,
            radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = C.gold.withValues(
                  alpha: .5 + .4 * math.sin(animT * 2 * math.pi * 2.2)));
      }
      final locked = !eaten && !isNext && !wet;
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            fontFamily: numFont,
            fontWeight: FontWeight.w600,
            fontSize: rect.width * 0.62,
            color: wet
                ? const Color(0xFF063A52)
                : eaten
                    ? const Color(0xFF04351D)
                    : C.tokenInk.withValues(alpha: locked ? .55 : 1),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2 + 1));
      if (locked) {
        canvas.drawCircle(center, radius,
            Paint()..color = C.ink.withValues(alpha: .25));
      }
    });
  }

  void _drawGuideArrow(Canvas canvas) {
    final cell = ctl.guideCell;
    if (cell == null || g.head == null) return;
    final (nr, nc) = cell;
    final center = geo.center(nr, nc);
    final dr = nr - g.head!.$1, dc = nc - g.head!.$2;
    final angle = math.atan2(dr.toDouble(), dc.toDouble());
    final pulse = .85 + .3 * math.sin(animT * 2 * math.pi * 2.5);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(pulse);
    final s = geo.cell * 0.22;
    final tri = Path()
      ..moveTo(s, 0)
      ..lineTo(-s * .7, -s * .85)
      ..lineTo(-s * .7, s * .85)
      ..close();
    canvas.drawPath(
        tri,
        Paint()
          ..color = C.gold
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4));
    canvas.restore();
  }

  void _drawHead(Canvas canvas) {
    final (r, c) = g.head!;
    final center = geo.center(r, c);
    final s = geo.cell * 1.6;
    canvas.save();
    canvas.translate(center.dx - s / 2, center.dy - s / 2);
    MascotPainter(animT).paint(canvas, Size(s, s));
    canvas.restore();
  }

  void _drawSpotlight(Canvas canvas, Size size) {
    // 숫자 1 칸만 밝게, 나머지 어둡게
    final k1 = g.level.numAt.entries.firstWhere((e) => e.value == 1).key;
    final r = k1 ~/ geo.cols, c = k1 % geo.cols;
    final hole = geo.cellRect(r, c).inflate(geo.cell * 0.18);
    final dim = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(14)))
      ..addOval(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: .55));
    canvas.drawOval(
        hole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = C.gold.withValues(
              alpha: .5 + .45 * math.sin(animT * 2 * math.pi * 1.6)));
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}

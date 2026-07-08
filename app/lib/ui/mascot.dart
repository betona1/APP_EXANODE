/// 두 마리 파이썬 마스코트 — 프로토타입 SVG(mascotSVG)를 CustomPainter로 이식.
/// 노랑/파랑 뱀이 고리를 이루며 서로 쫓고, 혀를 매롱거리고, 10초마다
/// 파이썬 로고처럼 몸을 겹쳤다 풀어진다.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// 키프레임 보간: [(위치 0~1, 값)] 목록에서 t 위치의 값을 easeInOut으로.
double _kf(List<(double, double)> keys, double t) {
  if (t <= keys.first.$1) return keys.first.$2;
  for (var i = 1; i < keys.length; i++) {
    if (t <= keys[i].$1) {
      final a = keys[i - 1], b = keys[i];
      final span = b.$1 - a.$1;
      final u = span <= 0 ? 1.0 : (t - a.$1) / span;
      final e = Curves.easeInOut.transform(u.clamp(0, 1));
      return a.$2 + (b.$2 - a.$2) * e;
    }
  }
  return keys.last.$2;
}

class Mascot extends StatefulWidget {
  final double size;
  const Mascot({super.key, required this.size});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: MascotPainter(_c.value)),
      ),
    );
  }
}

class MascotPainter extends CustomPainter {
  /// 0~1, 10초 주기.
  final double t;
  MascotPainter(this.t);

  static const _deg = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // 100x100 로컬 좌표계 (SVG와 동일), 약간의 여백 포함 스케일
    final s = size.shortestSide / 112;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    canvas.translate(-50, -50);

    // CSS wigA/wigB: 평소 ±2.4°, 66~82%에 ±36° (파이썬 로고 겹침)
    final wigA = _kf(const [
      (0, -2.4), (.14, 2.4), (.40, 2.4), (.52, -2.4),
      (.66, 36), (.82, 36), (1, -2.4),
    ], t);
    final wigB = _kf(const [
      (0, 2.4), (.14, -2.4), (.40, -2.4), (.52, 2.4),
      (.66, -36), (.82, -36), (1, 2.4),
    ], t);
    final squash = _kf(const [(0, 1), (.52, 1), (.66, .97), (.82, .97), (1, 1)], t);

    // ---- 파랑 몸통 ----
    _withRotation(canvas, wigB * _deg, squash, () {
      _body(canvas, startDeg: -30, blue: true);
    });
    // ---- 노랑 몸통 ----
    _withRotation(canvas, wigA * _deg, squash, () {
      _body(canvas, startDeg: 150, blue: false);
    });
    // ---- 머리 (몸통 위에) ----
    _withRotation(canvas, wigB * _deg, squash, () {
      canvas.save();
      canvas.translate(20.3, 57.3);
      canvas.rotate(245 * _deg);
      _head(canvas, blue: true);
      canvas.restore();
    });
    _withRotation(canvas, wigA * _deg, squash, () {
      canvas.save();
      canvas.translate(79.7, 42.7);
      canvas.rotate(65 * _deg);
      _head(canvas, blue: false);
      canvas.restore();
    });
  }

  void _withRotation(Canvas canvas, double rad, double scale, VoidCallback draw) {
    canvas.save();
    canvas.translate(50, 50);
    canvas.rotate(rad);
    canvas.scale(scale);
    canvas.translate(-50, -50);
    draw();
    canvas.restore();
  }

  void _body(Canvas canvas, {required double startDeg, required bool blue}) {
    final rect = Rect.fromCircle(center: const Offset(50, 50), radius: 30);
    const sweep = 185.0;
    final start = startDeg * _deg;
    final sw = sweep * _deg;

    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: blue
          ? const [Color(0xFF7FB8E6), C.pyBlue, Color(0xFF245A8C)]
          : const [Color(0xFFFFE873), C.pyYellow, Color(0xFFD9A02C)],
      stops: const [0, .6, 1],
    );
    final body = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..shader = grad.createShader(rect.inflate(10));
    canvas.drawArc(rect, start, sw, false, body);

    // 비늘 줄무늬 (dash)
    final scalePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = (blue ? const Color(0xFF041926) : const Color(0xFF422804))
          .withValues(alpha: .15);
    const dashRad = 2.6 / 30; // 호 길이 → 라디안 (r=30)
    const gapRad = 8.5 / 30;
    var a = start + gapRad;
    final end = start + sw;
    while (a < end - dashRad) {
      canvas.drawArc(rect, a, dashRad, false, scalePaint);
      a += dashRad + gapRad;
    }

    // 등 광택
    final sheen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: blue ? .24 : .32);
    canvas.save();
    canvas.translate(-1.4, -2);
    canvas.drawArc(rect, start, sw, false, sheen);
    canvas.restore();
  }

  void _head(Canvas canvas, {required bool blue}) {
    // headbob: 3.4s 주기, 파랑은 +0.9s 지연
    final hb = ((t * 10 + (blue ? 10 - 0.9 : 0)) % 3.4) / 3.4;
    final rot = _kf(const [(0, 0), (.22, -8), (.5, 6), (.76, -3), (1, 0)], hb);
    final sc = _kf(const [(0, 1), (.22, 1.05), (.5, 1), (.76, 1.04), (1, 1)], hb);
    canvas.rotate(rot * _deg);
    canvas.scale(sc);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..color = C.outline;

    // 두개골 (탑뷰 물방울형, 주둥이 +x)
    final skull = Path()
      ..moveTo(-12, -8.5)
      ..quadraticBezierTo(-2, -13.8, 6, -11.2)
      ..quadraticBezierTo(13.5, -8.2, 15.2, -2.5)
      ..quadraticBezierTo(16, 0, 15.2, 2.5)
      ..quadraticBezierTo(13.5, 8.2, 6, 11.2)
      ..quadraticBezierTo(-2, 13.8, -12, 8.5)
      ..quadraticBezierTo(-15.8, 0, -12, -8.5)
      ..close();
    final grad = RadialGradient(
      center: const Alignment(-.2, -.4),
      radius: 1.2,
      colors: blue
          ? const [Color(0xFF7FB8E6), C.pyBlue, Color(0xFF245A8C)]
          : const [Color(0xFFFFE873), C.pyYellow, Color(0xFFD9A02C)],
      stops: const [0, .6, 1],
    );
    canvas.drawPath(
      skull,
      Paint()..shader = grad.createShader(const Rect.fromLTRB(-16, -14, 16, 14)),
    );
    canvas.drawPath(skull, outline);

    // 정수리 하이라이트
    final crown = Path()
      ..moveTo(-10.5, -6)
      ..quadraticBezierTo(-1, -11, 6.5, -8.6)
      ..quadraticBezierTo(11.5, -6.4, 13.5, -2.6)
      ..quadraticBezierTo(6, -6.6, -2, -5.4)
      ..quadraticBezierTo(-7.5, -4.6, -10.5, -6)
      ..close();
    canvas.drawPath(crown, Paint()..color = Colors.white.withValues(alpha: .30));

    // 턱 그림자
    final jaw = Path()
      ..moveTo(-11, 7)
      ..quadraticBezierTo(0, 12, 8.5, 8.6)
      ..quadraticBezierTo(3, 12.6, -5, 11.8)
      ..quadraticBezierTo(-9.8, 10.8, -11, 7)
      ..close();
    canvas.drawPath(jaw, Paint()..color = Colors.black.withValues(alpha: .20));

    // 비늘 라인
    final ridge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round
      ..color = C.outline.withValues(alpha: .45);
    canvas.drawPath(
        Path()
          ..moveTo(-1, -9.8)
          ..quadraticBezierTo(3.5, -11.2, 7.5, -9.3),
        ridge);
    canvas.drawPath(
        Path()
          ..moveTo(-1, 9.8)
          ..quadraticBezierTo(3.5, 11.2, 7.5, 9.3),
        ridge);

    // 콧구멍
    final nose = Paint()..color = C.outline;
    canvas.drawCircle(const Offset(12.4, -2.7), .75, nose);
    canvas.drawCircle(const Offset(12.4, 2.7), .75, nose);

    // 눈 (호박색 홍채 + 세로 동공)
    for (final sign in [-1.0, 1.0]) {
      final ec = Offset(3.2, 6.1 * sign);
      canvas.drawCircle(ec, 3.9, Paint()..color = const Color(0xFFFFF8E0));
      canvas.drawCircle(
          ec,
          3.9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = C.outline);
      final ic = Offset(3.9, 5.8 * sign);
      canvas.drawCircle(
        ic,
        2.9,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.3, -.4),
            colors: [Color(0xFFFFE08A), Color(0xFFE8912B), Color(0xFF9C5510)],
            stops: [0, .55, 1],
          ).createShader(Rect.fromCircle(center: ic, radius: 2.9)),
      );
      canvas.drawOval(
          Rect.fromCenter(center: ic, width: 2.1, height: 5),
          Paint()..color = const Color(0xFF0B1C24));
      canvas.drawCircle(
          Offset(5, (5.8 - 1.2) * sign), .85, Paint()..color = Colors.white);
      // 볼터치
      canvas.drawOval(
          Rect.fromCenter(center: Offset(-4, 10.2 * sign), width: 4.4, height: 2.6),
          Paint()..color = C.blush.withValues(alpha: .5));
    }

    // 입선
    canvas.drawPath(
        Path()
          ..moveTo(15.2, 1)
          ..quadraticBezierTo(9, 3.6, 3, 2.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round
          ..color = C.outline.withValues(alpha: .55));

    // 매롱 혀 (1.5s 주기, 파랑 +0.75s)
    final tg = ((t * 10 + (blue ? 10 - 0.75 : 0)) % 1.5) / 1.5;
    final tx = _kf(const [(0, -3), (.45, 0), (.6, 0), (1, -3)], tg);
    final tsx = _kf(const [(0, .55), (.45, 1), (.6, 1), (1, .55)], tg);
    final trot = _kf(const [(0, 2), (.45, -4), (.6, 3), (1, 2)], tg);
    canvas.save();
    canvas.translate(15 + tx, .5);
    canvas.rotate(trot * _deg);
    canvas.scale(tsx, 1);
    final tonguePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..color = C.tongue;
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(6.5, -.5, 11.5, -4.3),
        tonguePaint);
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(6.5, .5, 11.5, 3.7),
        tonguePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MascotPainter old) => old.t != t;
}

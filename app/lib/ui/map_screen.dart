/// 스테이지 맵 — 구불구불한 길을 따라 노드(클리어✅/현재🟡/잠금🔒)가 이어지는
/// 게임식 진행 화면. 프로토타입 buildMap 이식.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/game.dart';
import 'game_screen.dart';
import 'mascot.dart';
import 'theme.dart';

class MapScreen extends StatefulWidget {
  final GameController ctl;
  const MapScreen({super.key, required this.ctl});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _scroll = ScrollController();
  static const _spacing = 96.0, _padTop = 130.0, _padBottom = 90.0;

  GameController get ctl => widget.ctl;

  int get _nodeCount => math.max(ctl.unlocked + 11, 30);
  double get _mapHeight => _padTop + _padBottom + (_nodeCount - 1) * _spacing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent(false));
  }

  void _scrollToCurrent(bool animate) {
    if (!_scroll.hasClients) return;
    final y = _nodeY(ctl.unlocked) - MediaQuery.sizeOf(context).height * .55;
    final target = y.clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
  }

  double _nodeY(int s) => _mapHeight - _padBottom - (s - 1) * _spacing;
  double _nodeX(int s, double w) => w / 2 + (w * 0.30) * math.sin((s - 1) * 0.85);

  static String? _tierLabel(int s) => switch (s) {
        1 => '🎓 튜토리얼',
        4 => '🌱 첫 실전',
        5 => '🥉 초급',
        11 => '🥈 쉬움',
        26 => '🥇 보통',
        46 => '🔥 어려움',
        71 => '👑 고수',
        _ => null,
      };

  void _openStage(int s) async {
    if (s > ctl.unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔒 이전 판을 먼저 클리어하세요!'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    ctl.selectStage(s);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameScreen(ctl: ctl)));
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent(true));
  }

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.sizeOf(context).width, 440.0);
    return Scaffold(
      body: Container(
        decoration: bgDecoration(),
        child: SafeArea(
          child: Column(children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Center(
                  child: SizedBox(
                    width: w,
                    height: _mapHeight,
                    child: Stack(children: [
                      CustomPaint(
                        size: Size(w, _mapHeight),
                        painter: _MapPathPainter(
                          nodeCount: _nodeCount,
                          unlocked: ctl.unlocked,
                          x: (s) => _nodeX(s, w),
                          y: _nodeY,
                        ),
                      ),
                      for (var s = 1; s <= _nodeCount; s++) ..._node(s, w),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(children: [
        const Mascot(size: 28),
        const SizedBox(width: 8),
        const Text('스테이지',
            style: TextStyle(
                fontFamily: numFont,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: C.head)),
        const Spacer(),
        _genreTab('⛏ 땅파기', Genre.fill),
        const SizedBox(width: 5),
        _genreTab('✏ 길잇기', Genre.path),
        const SizedBox(width: 10),
        Text('⭐${ctl.progress.totalStars(ctl.genre)}',
            style: const TextStyle(
                fontFamily: numFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: C.gold)),
      ]),
    );
  }

  Widget _genreTab(String label, Genre g) {
    final on = ctl.genre == g;
    return GestureDetector(
      onTap: () => setState(() => ctl.setGenre(g)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  colors: [Color(0xFF16B79A), Color(0xFF0E8F7C)])
              : null,
          color: on ? null : C.ink2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? const Color(0xFF1EE0BD) : C.grid),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                color: on ? const Color(0xFF002222) : C.muted)),
      ),
    );
  }

  List<Widget> _node(int s, double w) {
    final x = _nodeX(s, w), y = _nodeY(s);
    final unlocked = ctl.unlocked;
    final done = s < unlocked;
    final cur = s == unlocked;
    final stars = done ? (ctl.progress.best(ctl.genre, s)?.stars ?? 1) : 0;
    final chip = _tierLabel(s);

    return [
      if (chip != null)
        Positioned(
          left: w / 2 - (x - w / 2) * 0.72 - 50,
          top: y - 14,
          child: Container(
            width: 100,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: C.ink2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.grid),
            ),
            child: Text(chip,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: C.accent)),
          ),
        ),
      if (cur)
        Positioned(
            left: x - 26, top: y - 96, child: const Mascot(size: 52)),
      Positioned(
        left: x - 29,
        top: y - 29,
        child: GestureDetector(
          onTap: () => _openStage(s),
          child: Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2FE08D), Color(0xFF14A45F)])
                  : cur
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE27A), Color(0xFFFFB62E)])
                      : null,
              color: done || cur ? null : const Color(0xFF0C222B),
              border: Border.all(
                  width: 3,
                  color: done
                      ? const Color(0xFF7DFFC0)
                      : cur
                          ? const Color(0xFFFFF0B3)
                          : const Color(0xFF1B3D48)),
              boxShadow: [
                if (done)
                  BoxShadow(
                      color: const Color(0xFF14C86E).withValues(alpha: .35),
                      blurRadius: 14,
                      offset: const Offset(0, 4)),
                if (cur)
                  BoxShadow(
                      color: const Color(0xFFFFB428).withValues(alpha: .45),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
              ],
            ),
            child: Text(
              done || cur ? '$s' : '🔒',
              style: TextStyle(
                fontFamily: numFont,
                fontSize: done || cur ? 20 : 16,
                fontWeight: FontWeight.w600,
                color: done
                    ? const Color(0xFF03361C)
                    : cur
                        ? const Color(0xFF4A2F00)
                        : const Color(0xFF3F626D),
              ),
            ),
          ),
        ),
      ),
      if (stars > 0)
        Positioned(
          left: x - 40,
          top: y + 31,
          child: SizedBox(
            width: 80,
            child: Text('⭐' * stars,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, letterSpacing: -1)),
          ),
        ),
    ];
  }
}

class _MapPathPainter extends CustomPainter {
  final int nodeCount, unlocked;
  final double Function(int) x, y;
  _MapPathPainter(
      {required this.nodeCount,
      required this.unlocked,
      required this.x,
      required this.y});

  Path _smooth(int from, int to) {
    final pts = [for (var s = from; s <= to; s++) Offset(x(s), y(s))];
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      p.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    if (pts.length > 1) p.lineTo(pts.last.dx, pts.last.dy);
    return p;
  }

  void _dashed(Canvas canvas, Path path, Paint paint,
      {double dash = 1.5, double gap = 12}) {
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(
            m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final all = _smooth(1, nodeCount);
    canvas.drawPath(
        all,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .06));
    _dashed(
        canvas,
        all,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF1B4550));
    if (unlocked >= 2) {
      _dashed(
          canvas,
          _smooth(1, math.min(unlocked, nodeCount)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF2FE08D).withValues(alpha: .4));
    }
  }

  @override
  bool shouldRepaint(_MapPathPainter old) =>
      old.unlocked != unlocked || old.nodeCount != nodeCount;
}

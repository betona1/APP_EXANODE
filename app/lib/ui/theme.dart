/// CRDL 팔레트 — 프로토타입(crdl.html)의 CSS 변수를 그대로 이식.
library;

import 'package:flutter/material.dart';

abstract final class C {
  static const ink = Color(0xFF071A20);
  static const ink2 = Color(0xFF0C2530);
  static const ink3 = Color(0xFF08171C);
  static const grid = Color(0xFF17414D);
  static const grid2 = Color(0xFF0D2A33);
  static const head = Color(0xFFEAFFF7);
  static const token = Color(0xFFFFCF5A);
  static const tokenInk = Color(0xFF3A2600);
  static const eaten = Color(0xFF3AD07A);
  static const text = Color(0xFFD6F3EC);
  static const muted = Color(0xFF7AA5A0);
  static const danger = Color(0xFFFF6B6B);
  static const accent = Color(0xFF54E6C8);
  static const water = Color(0xFF3EC9F0);
  static const gold = Color(0xFFFFD43B);
  static const pyBlue = Color(0xFF3776AB);
  static const pyYellow = Color(0xFFFFD43B);
  static const blush = Color(0xFFFF9EC7);
  static const tongue = Color(0xFFFF5C8A);
  static const outline = Color(0xFF0D2833);
}

const numFont = 'Fredoka';
const uiFont = 'Jua';

ThemeData crdlTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: C.ink,
    fontFamily: uiFont,
    colorScheme: const ColorScheme.dark(
      primary: C.accent,
      secondary: C.token,
      surface: C.ink2,
      error: C.danger,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: C.text, fontFamily: uiFont),
    ),
  );
}

/// 배경 라디얼 그라데이션 (프로토타입 body 배경).
BoxDecoration bgDecoration() {
  return const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0, -1.2),
      radius: 1.6,
      colors: [Color(0xFF10333E), C.ink, Color(0xFF040D11)],
      stops: [0.0, 0.55, 1.0],
    ),
  );
}

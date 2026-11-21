import 'package:flutter/material.dart';

/// Типографика: крупные игровые заголовки и плотный читаемый текст.
class AppText {
  static const title = TextStyle(
    fontSize: 26,
    height: 1.12,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
    color: Colors.white,
  );
  static const h1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15);
  static const h2 = TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2);
  static const body = TextStyle(fontSize: 14, height: 1.35, color: Color(0xFFF3E9FF), fontWeight: FontWeight.w600);
  static const small = TextStyle(fontSize: 12, height: 1.3, color: Color(0xFFCDB9EE), fontWeight: FontWeight.w600);
  static const tiny = TextStyle(fontSize: 10.5, height: 1.25, color: Color(0xFFB9A6DC), fontWeight: FontWeight.w700);
  static const number = TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1);
}

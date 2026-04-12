import 'package:flutter/material.dart';

class AppUI {
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r18 = 18;
  static const double r24 = 24;

  static List<BoxShadow> shadow() => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}

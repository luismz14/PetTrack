import 'package:flutter/material.dart';

class AppColors {
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF3E3E3E);
  static const Color primary = Color(0xFF00327c);
  static const Color secondary = Color(0xFF000069);
  static const Color accent = Color(0xFF1c6a97);

  static const Color background = Colors.white;
  static const Color backgroundComponent = Color(0xFFf5f5f5);
  static const Color backgroundComponentHover = Color(0xFFA0A0A0);

  static const LinearGradient gradient = LinearGradient(
    colors: [Color(0xFF1b6f99), Color(0xFF000a69)],
    begin: Alignment(-0.5, -1),
    end: Alignment.bottomCenter,
  );
}

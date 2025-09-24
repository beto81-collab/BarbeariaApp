import 'package:flutter/material.dart';

class LogoCorteReal extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const LogoCorteReal({
    super.key,
    this.size = 120,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/corte real.png',
      width: size,
      height: size * 0.75, // Mantendo proporção
      fit: BoxFit.contain,
    );
  }
}

class LogoCorteRealHorizontal extends StatelessWidget {
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;

  const LogoCorteRealHorizontal({
    super.key,
    this.height = 60,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/corte real.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}

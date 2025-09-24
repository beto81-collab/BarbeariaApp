import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveBackground extends StatefulWidget {
  final Widget child;

  const InteractiveBackground({super.key, required this.child});

  @override
  State<InteractiveBackground> createState() => _InteractiveBackgroundState();
}

class _InteractiveBackgroundState extends State<InteractiveBackground>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _rippleController;

  final List<TapRipple> _ripples = [];
  final int maxRipples = 8;

  @override
  void initState() {
    super.initState();

    // Animação de brilho constante
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Controlador para efeitos de toque
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _addRipple(Offset position) {
    setState(() {
      if (_ripples.length >= maxRipples) {
        _ripples.removeAt(0);
      }

      _ripples.add(
        TapRipple(
          position: position,
          startTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });

    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _addRipple(details.globalPosition);
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: InteractiveBackgroundPainter(
            shimmerAnimation: _shimmerController,
            rippleAnimation: _rippleController,
            ripples: _ripples,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class TapRipple {
  final Offset position;
  final int startTime;

  TapRipple({required this.position, required this.startTime});
}

class InteractiveBackgroundPainter extends CustomPainter {
  final Animation<double> shimmerAnimation;
  final Animation<double> rippleAnimation;
  final List<TapRipple> ripples;

  InteractiveBackgroundPainter({
    required this.shimmerAnimation,
    required this.rippleAnimation,
    required this.ripples,
  }) : super(repaint: Listenable.merge([shimmerAnimation, rippleAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo base preto
    final basePaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Brilho constante - gradiente animado
    _drawShimmerEffect(canvas, size);

    // Efeitos de toque
    _drawTouchEffects(canvas, size);
  }

  void _drawShimmerEffect(Canvas canvas, Size size) {
    final shimmerValue = shimmerAnimation.value;

    // Gradiente diagonal animado
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + 2.0 * shimmerValue, -1.0),
      end: Alignment(1.0 + 2.0 * shimmerValue, 1.0),
      colors: [
        Colors.transparent,
        const Color(0xFF1A1A1A).withOpacity(0.3),
        const Color(0xFF2D2D2D).withOpacity(0.2),
        const Color(0xFF1A1A1A).withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );

    final shimmerPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmerPaint);
  }

  void _drawTouchEffects(Canvas canvas, Size size) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    for (int i = ripples.length - 1; i >= 0; i--) {
      final ripple = ripples[i];
      final elapsed = currentTime - ripple.startTime;
      final duration = 1500; // milliseconds

      if (elapsed > duration) {
        ripples.removeAt(i);
        continue;
      }

      final progress = elapsed / duration;
      final opacity = (1.0 - progress) * 0.6;

      // Efeito de onda expandindo
      final radius = progress * 120;

      // Onda principal
      final ripplePaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(ripple.position, radius, ripplePaint);

      // Onda secundária menor
      if (progress > 0.3) {
        final secondaryRadius = (progress - 0.3) * 60;
        final secondaryPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawCircle(ripple.position, secondaryRadius, secondaryPaint);
      }

      // Partículas ao redor do toque
      _drawParticles(canvas, ripple.position, progress, opacity);
    }
  }

  void _drawParticles(
    Canvas canvas,
    Offset center,
    double progress,
    double opacity,
  ) {
    final particlePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(opacity * 0.7);

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final distance = progress * 40 + math.sin(progress * math.pi * 4) * 10;

      final particleX = center.dx + math.cos(angle) * distance;
      final particleY = center.dy + math.sin(angle) * distance;

      final particleSize = (1.0 - progress) * 3;

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveBackgroundPainter oldDelegate) {
    return shimmerAnimation != oldDelegate.shimmerAnimation ||
        rippleAnimation != oldDelegate.rippleAnimation ||
        ripples.length != oldDelegate.ripples.length;
  }
}

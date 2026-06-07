import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Premium programmatic illustrations for SafePick empty and decorative states.
/// All art is drawn using Flutter's CustomPaint for zero-dependency, hardware-accelerated rendering.

// ─── Empty State: No Students Linked ─────────────────────
class NoStudentsIllustration extends StatelessWidget {
  final double size;
  const NoStudentsIllustration({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _NoStudentsPainter()),
      ),
    );
  }
}

class _NoStudentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Soft background circle
    final bgPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Dashed orbit ring
    final orbitPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedCircle(canvas, Offset(cx, cy), r * 0.85, orbitPaint);

    // Central figure (parent silhouette)
    final figurePaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(Offset(cx, cy - r * 0.2), r * 0.14, figurePaint);
    // Body (rounded rect)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.1), width: r * 0.32, height: r * 0.35),
      Radius.circular(r * 0.1),
    );
    canvas.drawRRect(bodyRect, figurePaint);

    // Small "+" indicators floating around
    final plusPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final angle = (i * 2.1) + 0.5;
      final px = cx + r * 0.75 * math.cos(angle);
      final py = cy + r * 0.75 * math.sin(angle);
      final s = r * 0.08;
      canvas.drawLine(Offset(px - s, py), Offset(px + s, py), plusPaint);
      canvas.drawLine(Offset(px, py - s), Offset(px, py + s), plusPaint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 36;
    const gapFraction = 0.4;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweepAngle = (1 - gapFraction) * (2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─── Empty State: No Trips Assigned ──────────────────────
class NoTripsIllustration extends StatelessWidget {
  final double size;
  const NoTripsIllustration({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _NoTripsPainter()),
      ),
    );
  }
}

class _NoTripsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Soft background
    final bgPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Road path
    final roadPaint = Paint()
      ..color = AppTheme.textMuted.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(cx - r * 0.8, cy + r * 0.4)
      ..quadraticBezierTo(cx - r * 0.2, cy - r * 0.2, cx + r * 0.3, cy - r * 0.1)
      ..quadraticBezierTo(cx + r * 0.7, cy + 0.0, cx + r * 0.8, cy - r * 0.35);
    canvas.drawPath(roadPath, roadPaint);

    // Dashed center line
    final dashPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerPath = Path()
      ..moveTo(cx - r * 0.8, cy + r * 0.4)
      ..quadraticBezierTo(cx - r * 0.2, cy - r * 0.2, cx + r * 0.3, cy - r * 0.1)
      ..quadraticBezierTo(cx + r * 0.7, cy + 0.0, cx + r * 0.8, cy - r * 0.35);

    _drawDashedPath(canvas, centerPath, dashPaint, 6, 6);

    // Van silhouette
    final vanPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final vanX = cx - r * 0.05;
    final vanY = cy - r * 0.1;
    final vanW = r * 0.32;
    final vanH = r * 0.2;

    // Van body
    final vanBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(vanX, vanY), width: vanW, height: vanH),
      Radius.circular(r * 0.06),
    );
    canvas.drawRRect(vanBody, vanPaint);

    // Van cab (windshield section)
    final cabRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(vanX + vanW * 0.25, vanY - vanH * 0.7, vanW * 0.28, vanH * 0.55),
      topLeft: Radius.circular(r * 0.04),
      topRight: Radius.circular(r * 0.08),
    );
    canvas.drawRRect(cabRect, vanPaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(vanX - vanW * 0.25, vanY + vanH * 0.5), r * 0.04, wheelPaint);
    canvas.drawCircle(Offset(vanX + vanW * 0.25, vanY + vanH * 0.5), r * 0.04, wheelPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLen, double gapLen) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLen, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─── Decorative: Live Tracking Active ────────────────────
class LiveTrackingIllustration extends StatelessWidget {
  final double size;
  const LiveTrackingIllustration({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LiveTrackingPainter()),
      ),
    );
  }
}

class _LiveTrackingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    // Pulse rings
    for (var i = 3; i >= 1; i--) {
      final ringPaint = Paint()
        ..color = AppTheme.primaryGold.withValues(alpha: 0.06 * i)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r * (0.5 + i * 0.2), ringPaint);
    }

    // Pin body (teardrop)
    final pinPaint = Paint()
      ..color = AppTheme.primaryGold
      ..style = PaintingStyle.fill;

    final pinPath = Path()
      ..moveTo(cx, cy + r * 0.45)
      ..quadraticBezierTo(cx - r * 0.3, cy - r * 0.1, cx, cy - r * 0.45)
      ..quadraticBezierTo(cx + r * 0.3, cy - r * 0.1, cx, cy + r * 0.45)
      ..close();
    canvas.drawPath(pinPath, pinPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - r * 0.1), r * 0.1, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─── Decorative: Student Profile Card Accent ─────────────
class StudentProfileAccent extends StatelessWidget {
  final double size;
  final Color accentColor;
  const StudentProfileAccent({super.key, this.size = 56, this.accentColor = AppTheme.primaryGold});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StudentProfilePainter(accentColor)),
      ),
    );
  }
}

class _StudentProfilePainter extends CustomPainter {
  final Color accent;
  _StudentProfilePainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    // Outer ring
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // Inner highlight ring
    final innerRing = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.75, innerRing);

    // Backpack shape
    final bpPaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final bp = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.08), width: r * 0.55, height: r * 0.7),
      Radius.circular(r * 0.15),
    );
    canvas.drawRRect(bp, bpPaint);

    // Top flap
    final flapRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - r * 0.2, cy - r * 0.35, r * 0.4, r * 0.2),
      topLeft: Radius.circular(r * 0.15),
      topRight: Radius.circular(r * 0.15),
    );
    canvas.drawRRect(flapRect, bpPaint);

    // Straps
    final strapPaint = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - r * 0.15, cy - r * 0.15), Offset(cx - r * 0.15, cy + r * 0.35), strapPaint);
    canvas.drawLine(Offset(cx + r * 0.15, cy - r * 0.15), Offset(cx + r * 0.15, cy + r * 0.35), strapPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─── Decorative: Calm Shield (Security / Safety) ─────────
class SafetyShieldIllustration extends StatelessWidget {
  final double size;
  const SafetyShieldIllustration({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SafetyShieldPainter()),
      ),
    );
  }
}

class _SafetyShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = size.width * 0.42;

    // Shield shape
    final shieldPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final shieldPath = Path()
      ..moveTo(cx, size.height * 0.1)
      ..quadraticBezierTo(cx + r, size.height * 0.15, cx + r, size.height * 0.4)
      ..quadraticBezierTo(cx + r * 0.9, size.height * 0.75, cx, size.height * 0.9)
      ..quadraticBezierTo(cx - r * 0.9, size.height * 0.75, cx - r, size.height * 0.4)
      ..quadraticBezierTo(cx - r, size.height * 0.15, cx, size.height * 0.1)
      ..close();
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield outline
    final outlinePaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(shieldPath, outlinePaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = AppTheme.successGreen.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(cx - r * 0.25, size.height * 0.48)
      ..lineTo(cx - r * 0.05, size.height * 0.58)
      ..lineTo(cx + r * 0.3, size.height * 0.35);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ─── Error State Illustration ────────────────────────────
class ErrorStateIllustration extends StatelessWidget {
  final double size;
  const ErrorStateIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ErrorStatePainter()),
      ),
    );
  }
}

class _ErrorStatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Soft background
    final bgPaint = Paint()
      ..color = AppTheme.errorRed.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Triangle warning
    final triPaint = Paint()
      ..color = AppTheme.errorRed.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    final triPath = Path()
      ..moveTo(cx, cy - r * 0.5)
      ..lineTo(cx + r * 0.5, cy + r * 0.35)
      ..lineTo(cx - r * 0.5, cy + r * 0.35)
      ..close();
    canvas.drawPath(triPath, triPaint);

    // Exclamation mark
    final exPaint = Paint()
      ..color = AppTheme.errorRed.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - r * 0.2), Offset(cx, cy + r * 0.08), exPaint);

    final dotPaint = Paint()
      ..color = AppTheme.errorRed.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + r * 0.22), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Calm Login Illustration ────────────────────────────
class LoginIllustration extends StatelessWidget {
  final double size;
  const LoginIllustration({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LoginIllustrationPainter()),
      ),
    );
  }
}

class _LoginIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    // Soft breathable background circle
    final bgPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Orbit rings for "calm connection"
    for (var i = 1; i <= 2; i++) {
      final ringPaint = Paint()
        ..color = AppTheme.primaryGold.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset(cx, cy), r * (0.6 + i * 0.2), ringPaint);
    }

    // Bus silhouette
    final busPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final busW = r * 0.6;
    final busH = r * 0.45;
    
    final busRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: busW, height: busH),
      Radius.circular(r * 0.1),
    );
    canvas.drawRRect(busRect, busPaint);

    // Windshield
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + busW * 0.2, cy - busH * 0.1), width: busW * 0.25, height: busH * 0.3),
      Radius.circular(r * 0.05),
    );
    canvas.drawRRect(glassRect, glassPaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - busW * 0.25, cy + busH * 0.5), r * 0.1, wheelPaint);
    canvas.drawCircle(Offset(cx + busW * 0.25, cy + busH * 0.5), r * 0.1, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

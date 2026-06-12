import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class MarkerGenerator {
  /// Generates a distinct van marker (teardrop) indicating the driver's live position.
  static Future<BitmapDescriptor> createDriverVanMarker({String? vehicleNumber}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double iconSize = 56.0; 

    double canvasWidth = iconSize;
    double canvasHeight = iconSize;
    double iconTopY = 0.0;

    TextPainter? pillTextPainter;
    double pillWidth = 0.0;
    double pillHeight = 0.0;
    const double paddingX = 10.0;
    const double paddingY = 4.0;

    if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
      pillTextPainter = TextPainter(textDirection: TextDirection.ltr);
      pillTextPainter.text = TextSpan(
        text: vehicleNumber.trim(),
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      );
      pillTextPainter.layout();
      
      pillWidth = pillTextPainter.width + (paddingX * 2);
      pillHeight = pillTextPainter.height + (paddingY * 2);
      
      canvasWidth = pillWidth > iconSize ? pillWidth : iconSize;
      canvasHeight = iconSize + pillHeight + 6.0;
      iconTopY = pillHeight + 6.0;
    }

    // Draw pill if exists
    if (pillTextPainter != null) {
      final Paint pillPaint = Paint()..color = const Color(0xFF1E293B);
      final RRect pillRect = RRect.fromLTRBR(
        (canvasWidth - pillWidth) / 2,
        0,
        ((canvasWidth - pillWidth) / 2) + pillWidth,
        pillHeight,
        Radius.circular(pillHeight / 2),
      );
      canvas.drawShadow(Path()..addRRect(pillRect), Colors.black, 3.0, true);
      canvas.drawRRect(pillRect, pillPaint);
      pillTextPainter.paint(
        canvas,
        Offset(
          ((canvasWidth - pillWidth) / 2) + paddingX,
          paddingY,
        ),
      );
    }

    final Paint paint = Paint()..color = AppTheme.primaryGold;
    final Path teardropPath = Path();
    
    final double radius = iconSize / 2.8;
    final Offset center = Offset(canvasWidth / 2, iconTopY + radius + 2);
    
    // Draw top arc
    teardropPath.addArc(Rect.fromCircle(center: center, radius: radius), 3.14159, 3.14159);
    // Draw bezier curves to bottom point
    teardropPath.moveTo(center.dx - radius, center.dy);
    teardropPath.quadraticBezierTo(center.dx - radius, center.dy + radius * 1.2, center.dx, iconTopY + iconSize - 2);
    teardropPath.quadraticBezierTo(center.dx + radius, center.dy + radius * 1.2, center.dx + radius, center.dy);
    teardropPath.close();

    canvas.drawShadow(teardropPath, Colors.black, 4.0, true);
    canvas.drawPath(teardropPath, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(teardropPath, borderPaint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
      style: TextStyle(
        fontSize: radius * 1.1,
        fontFamily: Icons.directions_bus_rounded.fontFamily,
        package: Icons.directions_bus_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Generates a student marker with an icon and a text pill containing their short name.
  static Future<BitmapDescriptor> createStudentMarker(String name, Color statusColor) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double iconSize = 40.0;
    const double fontSize = 14.0;
    const double paddingX = 12.0;
    const double paddingY = 6.0;

    // Use short name (first name)
    final shortName = name.split(' ').first;

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: shortName,
      style: const TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Inter',
      ),
    );
    textPainter.layout();

    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;

    final double pillWidth = textWidth + (paddingX * 2);
    final double pillHeight = textHeight + (paddingY * 2);

    final double canvasWidth = pillWidth > iconSize ? pillWidth : iconSize;
    final double canvasHeight = pillHeight + iconSize + 6.0;

    // 1. Draw Text Pill (White background)
    final Paint pillPaint = Paint()..color = Colors.white;
    final RRect pillRect = RRect.fromLTRBR(
      (canvasWidth - pillWidth) / 2,
      0,
      ((canvasWidth - pillWidth) / 2) + pillWidth,
      pillHeight,
      Radius.circular(pillHeight / 2),
    );

    canvas.drawShadow(Path()..addRRect(pillRect), Colors.black, 2.0, true);
    canvas.drawRRect(pillRect, pillPaint);

    textPainter.paint(
      canvas,
      Offset(
        ((canvasWidth - pillWidth) / 2) + paddingX,
        paddingY,
      ),
    );

    // 2. Draw Marker Pin
    final double iconTopY = pillHeight + 6.0;
    final Paint pinPaint = Paint()..color = Colors.white;
    final Offset pinCenter = Offset(canvasWidth / 2, iconTopY + (iconSize / 2));
    
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: pinCenter, radius: iconSize / 2)),
      Colors.black, 3.0, true,
    );
    canvas.drawCircle(pinCenter, iconSize / 2, pinPaint);

    final Paint innerPinPaint = Paint()..color = statusColor;
    canvas.drawCircle(pinCenter, (iconSize / 2) - 4, innerPinPaint);

    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.home_rounded.codePoint),
      style: TextStyle(
        fontSize: iconSize * 0.6,
        fontFamily: Icons.home_rounded.fontFamily,
        package: Icons.home_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (canvasWidth - iconPainter.width) / 2,
        iconTopY + (iconSize - iconPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Maps student status and trip type to the required color logic.
  static Color getStatusColor(String status, String tripType) {
    final isMorning = tripType.toLowerCase() == 'morning';
    final normalizedStatus = status.toLowerCase();

    if (isMorning) {
      if (normalizedStatus == 'at home') return Colors.blue;
      if (normalizedStatus == 'in van') return AppTheme.warningOrange;
      if (normalizedStatus == 'at school') return AppTheme.successGreen;
      if (normalizedStatus == 'absent') return AppTheme.errorRed;
    } else {
      if (normalizedStatus == 'at school') return Colors.blue;
      if (normalizedStatus == 'in van') return AppTheme.warningOrange;
      if (normalizedStatus == 'at home') return AppTheme.successGreen;
      if (normalizedStatus == 'absent') return AppTheme.errorRed;
    }

    return Colors.grey;
  }

  /// Generates a school marker with a school icon and a text pill containing its name.
  static Future<BitmapDescriptor> createSchoolMarker(String name) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double iconSize = 48.0; // Slightly larger for school
    const double fontSize = 14.0;
    const double paddingX = 12.0;
    const double paddingY = 6.0;

    // Use short name for pill
    final shortName = name.length > 15 ? '${name.substring(0, 15)}...' : name;

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: shortName,
      style: const TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
    );
    textPainter.layout();

    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;

    final double pillWidth = textWidth + (paddingX * 2);
    final double pillHeight = textHeight + (paddingY * 2);

    final double canvasWidth = pillWidth > iconSize ? pillWidth : iconSize;
    final double canvasHeight = pillHeight + iconSize + 8.0;

    // 1. Draw Text Pill (Dark Navy background)
    final Paint pillPaint = Paint()..color = const Color(0xFF1E293B); // kAdminNavy
    final RRect pillRect = RRect.fromLTRBR(
      (canvasWidth - pillWidth) / 2,
      0,
      ((canvasWidth - pillWidth) / 2) + pillWidth,
      pillHeight,
      Radius.circular(pillHeight / 2),
    );

    canvas.drawShadow(Path()..addRRect(pillRect), Colors.black, 4.0, true);
    canvas.drawRRect(pillRect, pillPaint);

    textPainter.paint(
      canvas,
      Offset(
        ((canvasWidth - pillWidth) / 2) + paddingX,
        paddingY,
      ),
    );

    // 2. Draw Marker Pin
    final double iconTopY = pillHeight + 8.0;
    final Paint pinPaint = Paint()..color = Colors.white;
    final Offset pinCenter = Offset(canvasWidth / 2, iconTopY + (iconSize / 2));
    
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: pinCenter, radius: iconSize / 2)),
      Colors.black, 4.0, true,
    );
    canvas.drawCircle(pinCenter, iconSize / 2, pinPaint);

    final Paint innerPinPaint = Paint()..color = const Color(0xFF1E293B); // Deep navy
    canvas.drawCircle(pinCenter, (iconSize / 2) - 4, innerPinPaint);

    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.school_rounded.codePoint),
      style: TextStyle(
        fontSize: iconSize * 0.55,
        fontFamily: Icons.school_rounded.fontFamily,
        package: Icons.school_rounded.fontPackage,
        color: AppTheme.primaryGold, // Gold icon on navy background
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (canvasWidth - iconPainter.width) / 2,
        iconTopY + (iconSize - iconPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class MarkerGenerator {
  /// Generates a distinct van marker indicating the driver's live position.
  static Future<BitmapDescriptor> createDriverVanMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0;

    // Draw circular backdrop
    final Paint paint = Paint()..color = AppTheme.primaryGold;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, borderPaint);

    // Draw the bus icon
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: Icons.directions_bus_rounded.fontFamily,
        package: Icons.directions_bus_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Generates a student marker with an icon and a text pill containing their name.
  static Future<BitmapDescriptor> createStudentMarker(String name, Color statusColor) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double iconSize = 90.0;
    const double fontSize = 36.0;
    const double paddingX = 24.0;
    const double paddingY = 16.0;

    // Text configuration
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: name,
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

    // Calculate overall canvas dimensions
    final double pillWidth = textWidth + (paddingX * 2);
    final double pillHeight = textHeight + (paddingY * 2);

    final double canvasWidth = pillWidth > iconSize ? pillWidth : iconSize;
    final double canvasHeight = pillHeight + iconSize + 10.0; // 10px gap

    // 1. Draw Text Pill
    final Paint pillPaint = Paint()..color = statusColor;
    final RRect pillRect = RRect.fromLTRBR(
      (canvasWidth - pillWidth) / 2,
      0,
      ((canvasWidth - pillWidth) / 2) + pillWidth,
      pillHeight,
      Radius.circular(pillHeight / 2),
    );

    // Drop shadow for text pill
    canvas.drawShadow(Path()..addRRect(pillRect), Colors.black, 4.0, true);
    canvas.drawRRect(pillRect, pillPaint);

    // Draw text inside pill
    textPainter.paint(
      canvas,
      Offset(
        ((canvasWidth - pillWidth) / 2) + paddingX,
        paddingY,
      ),
    );

    // 2. Draw Marker Pin
    final double iconTopY = pillHeight + 10.0;
    final Paint pinPaint = Paint()..color = Colors.white;
    final Offset pinCenter = Offset(canvasWidth / 2, iconTopY + (iconSize / 2));
    
    // Draw pin drop shadow
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: pinCenter, radius: iconSize / 2)),
      Colors.black, 4.0, true,
    );
    canvas.drawCircle(pinCenter, iconSize / 2, pinPaint);

    final Paint innerPinPaint = Paint()..color = statusColor;
    canvas.drawCircle(pinCenter, (iconSize / 2) - 8, innerPinPaint);

    // Draw home icon
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
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class WatermarkMetadata {
  final String checkpointType; // 'START' | 'END'
  final String locationName;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double altitudeMsl;
  final String driverId;
  final String driverName;
  final String taskId;
  final DateTime timestamp;

  WatermarkMetadata({
    required this.checkpointType,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.altitudeMsl = 142.0,
    required this.driverId,
    required this.driverName,
    required this.taskId,
    required this.timestamp,
  });
}

class CanvasWatermarkService {
  CanvasWatermarkService._();

  /// Burns the surveyor watermark permanently into the image pixels
  static Future<File> burnWatermarkAndSave({
    required Uint8List rawImageBytes,
    required WatermarkMetadata metadata,
  }) async {
    // 1. Decode raw image into ui.Image
    final codec = await ui.instantiateImageCodec(rawImageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    // 2. Setup PictureRecorder & Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // 3. Draw base photo
    canvas.drawImage(image, Offset.zero, Paint());

    // 4. Calculate responsive dimensions for stamp box
    final boxMargin = width * 0.03;
    final boxWidth = width - (boxMargin * 2);
    final boxHeight = height * 0.22;
    final boxLeft = boxMargin;
    final boxTop = height - boxHeight - boxMargin;

    // Draw solid white stamp card (98% opacity)
    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
      Radius.circular(width * 0.025),
    );

    // Card Shadow
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Card Background
    canvas.drawRRect(
      cardRRect,
      Paint()..color = const Color(0xFAF8FAFC),
    );

    // Card Border
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 5. Draw Left Mini Contour Map Vector (80x96 equivalent)
    final mapWidth = boxWidth * 0.22;
    final mapHeight = boxHeight * 0.82;
    final mapLeft = boxLeft + (boxWidth * 0.03);
    final mapTop = boxTop + (boxHeight * 0.09);

    final mapRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(mapLeft, mapTop, mapWidth, mapHeight),
      Radius.circular(width * 0.015),
    );

    // Map Background
    canvas.drawRRect(mapRect, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(
      mapRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 50m Geofence Tolerance Circle on Mini Map
    final mapCenter = Offset(mapLeft + (mapWidth / 2), mapTop + (mapHeight / 2));
    final circleRadius = mapWidth * 0.35;

    canvas.drawCircle(
      mapCenter,
      circleRadius,
      Paint()..color = const Color(0x3310B981),
    );
    canvas.drawCircle(
      mapCenter,
      circleRadius,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Center Red Pin Dot
    canvas.drawCircle(
      mapCenter,
      circleRadius * 0.25,
      Paint()..color = const Color(0xFFDC2626),
    );

    // 6. Draw Metadata Texts
    final textLeft = mapLeft + mapWidth + (boxWidth * 0.035);
    final textWidth = boxWidth - (mapWidth + (boxWidth * 0.09));

    final isStart = metadata.checkpointType == 'START';
    final timeStr = '${DateFormat('HH:mm:ss').format(metadata.timestamp)} WITA (UTC+8)';
    final dateStr = DateFormat('yyyy-MM-dd').format(metadata.timestamp);

    // Line 1: Badge & Header
    _drawText(
      canvas: canvas,
      text: isStart ? '[START CHECKPOINT]' : '[END CHECKPOINT]',
      offset: Offset(textLeft, boxTop + (boxHeight * 0.09)),
      color: isStart ? const Color(0xFFD97706) : const Color(0xFF15803D),
      fontSize: boxHeight * 0.09,
      fontWeight: FontWeight.w900,
      maxWidth: textWidth,
    );

    // Line 2: Precision Red Monospace Clock
    _drawText(
      canvas: canvas,
      text: '$timeStr • $dateStr',
      offset: Offset(textLeft, boxTop + (boxHeight * 0.23)),
      color: const Color(0xFFDC2626),
      fontSize: boxHeight * 0.13,
      fontWeight: FontWeight.w900,
      fontFamily: 'monospace',
      maxWidth: textWidth,
    );

    // Line 3: Location Name
    _drawText(
      canvas: canvas,
      text: metadata.locationName,
      offset: Offset(textLeft, boxTop + (boxHeight * 0.41)),
      color: const Color(0xFF0F172A),
      fontSize: boxHeight * 0.12,
      fontWeight: FontWeight.w800,
      maxWidth: textWidth,
    );

    // Line 4: GPS Coordinates
    _drawText(
      canvas: canvas,
      text: 'Lat: ${metadata.latitude.toStringAsFixed(6)} • Lng: ${metadata.longitude.toStringAsFixed(6)}',
      offset: Offset(textLeft, boxTop + (boxHeight * 0.58)),
      color: const Color(0xFF334155),
      fontSize: boxHeight * 0.095,
      fontWeight: FontWeight.w700,
      fontFamily: 'monospace',
      maxWidth: textWidth,
    );

    // Line 5: Satellite Accuracy & Driver Identity
    _drawText(
      canvas: canvas,
      text: 'Akurasi: ±${metadata.accuracyMeters.toStringAsFixed(1)}m | ${metadata.driverId} (${metadata.driverName})',
      offset: Offset(textLeft, boxTop + (boxHeight * 0.74)),
      color: const Color(0xFF64748B),
      fontSize: boxHeight * 0.09,
      fontWeight: FontWeight.w600,
      maxWidth: textWidth,
    );

    // 7. Render Picture dengan optimasi dimensi (Max width: 1280px untuk kompresi mobile offline)
    final picture = recorder.endRecording();
    final targetW = width > 1280 ? 1280 : width.toInt();
    final targetH = width > 1280 ? ((height * 1280) / width).toInt() : height.toInt();
    final stampedImage = await picture.toImage(targetW, targetH);
    final byteData = await stampedImage.toByteData(format: ui.ImageByteFormat.png);
    final stampedBytes = byteData!.buffer.asUint8List();

    // 8. Save to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'EVD_${metadata.taskId}_${metadata.checkpointType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(stampedBytes);

    return file;
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    String? fontFamily,
    required double maxWidth,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(minWidth: 0, maxWidth: maxWidth);
    textPainter.paint(canvas, offset);
  }
}

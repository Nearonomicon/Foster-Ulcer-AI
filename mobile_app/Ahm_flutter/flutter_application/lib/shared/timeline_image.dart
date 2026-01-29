import 'package:flutter/material.dart';

/// จะถูก resolve ไปที่
/// - timeline_image_stub.dart (Web)
/// - timeline_image_io.dart   (Mobile / Desktop)
Widget buildTimelineImage({
  required bool isDark,
  String? imagePath,
}) =>
    buildTimelineImageImpl(
      isDark: isDark,
      imagePath: imagePath,
    );

/// function signature ที่ implementation ต้องมี
Widget buildTimelineImageImpl({
  required bool isDark,
  String? imagePath,
});

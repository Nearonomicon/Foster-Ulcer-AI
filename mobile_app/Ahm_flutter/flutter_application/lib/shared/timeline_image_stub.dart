import 'package:flutter/material.dart';
import 'timeline_image.dart';

/// Web implementation
Widget buildTimelineImageImpl({
  required bool isDark,
  String? imagePath,
}) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 6),
          Text(
            "Image preview\n(not available on Web)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'timeline_image.dart';

/// Mobile / Desktop implementation
Widget buildTimelineImageImpl({
  required bool isDark,
  String? imagePath,
}) {
  if (imagePath == null || imagePath.isEmpty) {
    return _placeholder(isDark);
  }

  final file = File(imagePath);

  if (!file.existsSync()) {
    return _broken(isDark);
  }

  return Image.file(
    file,
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
  );
}

Widget _placeholder(bool isDark) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
    child: Center(
      child: Icon(
        Icons.image,
        size: 44,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
    ),
  );
}

Widget _broken(bool isDark) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 44,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:foster_ulcer_ai/services/notification_service.dart';
import 'package:foster_ulcer_ai/widgets/foster_ulcer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FosterUlcerApp());
  unawaited(PushNotificationService.instance.initialize());
}

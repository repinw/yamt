// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupFirebase();
  runApp(ProviderScope(child: const YAMT()));
}

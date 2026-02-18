import 'package:firebase_core/firebase_core.dart';
import 'package:yamt/firebase_options.dart';

// coverage:ignore-file
Future<void> setupFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

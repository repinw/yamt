import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Current wall-clock time. Tests override it with a fixed time.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// The current time. Widgets that show elapsed time or depend on the time of
/// day read it from here so tests can pin it.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

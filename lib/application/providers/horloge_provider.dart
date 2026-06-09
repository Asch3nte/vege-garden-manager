import 'package:riverpod/riverpod.dart';

/// Injectable clock for time-dependent reads (the "now" used to compute a
/// day/week window, etc.).
///
/// Production uses the real wall clock; tests override it to pin a deterministic
/// "now". Shared by every notifier that needs the current time, so they all read
/// the same source and stay testable in isolation.
final horlogeProvider = Provider<DateTime Function()>((ref) => DateTime.now);

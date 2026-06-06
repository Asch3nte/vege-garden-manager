// Runnable entrypoint for the engine demo (see ../bin/demo.dart).
//
// The demo runs an in-memory SQLite database via drift, whose native (FFI)
// bindings crash `dart run`'s JIT compiler on the current SDK. The Flutter test
// toolchain compiles them cleanly, so we expose the demo as a single `test`
// case and run it with:
//
//   flutter test tool/run_demo.dart
//
// It is not an assertion-based test; it just executes [runDemo] end to end (a
// thrown exception fails it), printing the engine's output to the console.
import 'package:flutter_test/flutter_test.dart';

import '../bin/demo.dart';

void main() {
  test('engine demo runs end to end on real data', () => runDemo());
}

/// Default of a port provider: its implementation is bound by the composition
/// root at startup, or by the test.
Never nonBranche(String provider) => throw UnimplementedError(
    '$provider must be overridden by the composition root (or in tests).');

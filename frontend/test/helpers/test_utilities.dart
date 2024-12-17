// Utility functions for testing
class TestUtils {
  static Stream<T> streamFromIterable<T>(Iterable<T> items) async* {
    for (final item in items) {
      yield item;
    }
  }

  static Future<void> delay([Duration? duration]) {
    return Future.delayed(duration ?? const Duration(milliseconds: 100));
  }
}

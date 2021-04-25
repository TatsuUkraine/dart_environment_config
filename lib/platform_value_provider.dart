import 'dart:io';

/// Provider for platform env variables
class PlatformValueProvider {
  final Map<String, String> data = Platform.environment;

  /// Returns value from platform env variable
  String? getValue(String key) {
    if (data.containsKey(key)) {
      return data[key];
    }

    return null;
  }
}

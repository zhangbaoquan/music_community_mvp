extension StringExtension on String {
  /// Converts a URL to use HTTPS if it's currently HTTP.
  /// This is crucial for web apps running on HTTPS to avoid Mixed Content errors.
  String toSecureUrl() {
    if (startsWith('http://')) {
      return replaceFirst('http://', 'https://');
    }
    return this;
  }
}

extension OptionalStringExtension on String? {
  /// Helper for nullable strings
  String? toSecureUrl() {
    if (this == null) return null;
    return this!.toSecureUrl();
  }
}

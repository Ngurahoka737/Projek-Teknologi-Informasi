class AiConfig {
  static const String baseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://10.0.2.2:5050',
  );

  static Uri endpoint(String path) {
    if (baseUrl.endsWith('/') && path.startsWith('/')) {
      return Uri.parse(baseUrl.substring(0, baseUrl.length - 1) + path);
    }
    return Uri.parse(baseUrl + path);
  }
}

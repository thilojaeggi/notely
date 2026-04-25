class Constants {
  static const String baseUrl = 'https://kaschuso.so.ch/public';

  static Uri buildUrl(String path) {
    return Uri.parse('$baseUrl/$path');
  }
}

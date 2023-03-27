class Globals {
  static final Globals _singleton = Globals._internal();

  factory Globals() {
    return _singleton;
  }

  Globals._internal();

  bool debug = false;
  bool isDark = true;
  static const String baseUrl = 'https://kaschuso.so.ch/public';

  static Uri buildUrl(String path) {
    return Uri.parse('$baseUrl/$path');
  }
}

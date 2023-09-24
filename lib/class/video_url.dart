class URL {
  static final URL _singleton = URL._internal();

  factory URL() {
    return _singleton;
  }

  URL._internal();
  String baseURL = 'https://ailyproject.shop/static/video';
  String foldername = '';
  String filename = '';
  String videoURL = '';
}

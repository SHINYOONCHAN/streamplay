class URL {
  static final URL _singleton = URL._internal();

  factory URL() {
    return _singleton;
  }

  URL._internal();
  String baseURL = 'https://ailyproject.shop'; //'http://192.168.75.191:8081';
  String foldername = '';
  String filename = '';
  String videoURL = '';
}

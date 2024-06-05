import 'package:http/http.dart' as http;

class Client {
  http.Client getInstance() {
    return http.Client();
  }
}
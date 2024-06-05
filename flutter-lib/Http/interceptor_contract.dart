import 'package:http/http.dart' as http;
import 'package:prm_go/Constants/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

abstract class InterceptorContract {
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request);
  Future<http.StreamedResponse> interceptResponse(
      http.StreamedResponse response);
}

class LoggingInterceptor implements InterceptorContract {
  @override
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request) async {
    Logger().d("Request: ${request.method} ${request.url}");
    return request;
  }

  @override
  Future<http.StreamedResponse> interceptResponse(
      http.StreamedResponse response) async {
    Logger().d("Response: ${response.statusCode}");
    return response;
  }
}

class BasicInterceptor implements InterceptorContract {
  @override
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request) async {
    http.BaseRequest newRequest = request;
    newRequest.headers['Content-Type'] = 'application/json; charset=UTF-8';
    return newRequest;
  }

  @override
  Future<http.StreamedResponse> interceptResponse(
      http.StreamedResponse response) async {
    return response;
  }
}

class AuthInterceptor implements InterceptorContract {
  final logger = Logger();

  @override
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request) async {
    http.BaseRequest newRequest = request;
    newRequest.headers['Authorization'] =
        'Bearer $loginToken, Basic $refreshToken';
    // logger.d('new headers: ${newRequest.headers}');
    return newRequest;
  }

  @override
  Future<http.StreamedResponse> interceptResponse(
      http.StreamedResponse response) async {
    if (response.headers.containsKey('set-cookie')) {
      final cookies = extractCookies(response.headers['set-cookie']!);
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = true;
      prefs.setBool('isLoggedIn', isLoggedIn);
      loginToken = cookies['token'].toString();
      prefs.setString('token', loginToken);
      if (cookies['refreshToken'] != null) {
        refreshToken = cookies['refreshToken'].toString();
        prefs.setString('refreshToken', refreshToken);
      }
      logger.w('log in token = $loginToken');
      logger.w('ref token = $refreshToken');
    }

    return response;
  }
}

Map<String, String> extractCookies(String cookieHeader) {
  final cookies = cookieHeader.split(','); // Split the cookies into an array
  Map<String, String> extractedCookies = {};

  for (var cookie in cookies) {
    if (cookie.startsWith('token=')) {
      String token = cookie.replaceFirst('token=', '').split(';')[0];
      extractedCookies['token'] = token;
      if (token.startsWith('s%3A')) {
        extractedCookies['token'] = token.replaceFirst('s%3A', '');
      }
    } else if (cookie.startsWith('refreshToken=')) {
      String refreshToken =
          cookie.replaceFirst('refreshToken=', '').split(';')[0];
      extractedCookies['refreshToken'] = refreshToken;
      if (refreshToken.startsWith('s%3A')) {
        extractedCookies['refreshToken'] =
            refreshToken.replaceFirst('s%3A', '');
      }
    }
  }

  return extractedCookies;
}

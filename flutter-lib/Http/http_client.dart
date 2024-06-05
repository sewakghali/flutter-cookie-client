import 'package:http/http.dart' as http;
import 'package:prm_go/Http/http_mobile_client.dart'
    if (dart.library.html) 'package:prm_go/Http/http_browser_client.dart';
import 'package:prm_go/Http/interceptor_contract.dart';

class HttpClient extends http.BaseClient {
  final http.Client _inner = Client().getInstance();
  List<InterceptorContract>? _sendInterceptors;
  List<InterceptorContract>? _receiveInterceptors;

  HttpClient({
    List<InterceptorContract>? sendInterceptors,
    List<InterceptorContract>? receiveInterceptors,
  })  : _sendInterceptors =
            sendInterceptors ?? [LoggingInterceptor(), AuthInterceptor()],
        _receiveInterceptors =
            receiveInterceptors ?? [LoggingInterceptor(), AuthInterceptor()];

  void addSendInterceptors(List<InterceptorContract> interceptors) {
    _sendInterceptors?.addAll(interceptors);
  }

  void addReceiveInterceptors(List<InterceptorContract> interceptors) {
    _receiveInterceptors?.addAll(interceptors);
  }

  void setSendInterceptors(List<InterceptorContract> interceptors) {
    _sendInterceptors = interceptors;
  }

  void setReceiveInterceptors(List<InterceptorContract> interceptors) {
    _receiveInterceptors = interceptors;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    for (final interceptor in _sendInterceptors ?? []) {
      request = await interceptor.interceptRequest(request);
    }

    final response = await _inner.send(request);
    var modifiedResponse = response;
    for (final interceptor in _receiveInterceptors ?? []) {
      modifiedResponse = await interceptor.interceptResponse(modifiedResponse);
    }
    return modifiedResponse;
  }
}
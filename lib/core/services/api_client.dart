// core/services/api_client.dart
/// Base HTTP client — hanya berisi baseUrl dan headers.
class ApiClient {
  static const String baseUrl = 'http://192.168.1.5:8000/api';

  /// Untuk request JSON biasa (GET, POST dengan body JSON)
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> headersMultipart({required String token}) {
    return {
      'Accept':        'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}

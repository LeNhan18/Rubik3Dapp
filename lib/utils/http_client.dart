import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// HTTP Client that bypasses SSL certificate verification
/// ONLY USE IN DEVELOPMENT with self-signed certificates
class InsecureHttpClient {
  static http.Client? _client;

  static http.Client getClient() {
    if (_client != null) return _client!;

    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    _client = IOClient(httpClient);
    return _client!;
  }

  static void close() {
    _client?.close();
    _client = null;
  }
}

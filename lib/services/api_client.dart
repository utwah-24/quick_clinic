import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get baseUrl {
    try {
      final raw = dotenv.env['API_BASE_URL'] ?? '';
      return raw.replaceAll(RegExp(r"/+?$"), '');
    } catch (e) {
      return 'https://quicklink.e-saloon.online';
    }
  }
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _httpClient.get(uri, headers: _defaultHeaders());
    _ensureSuccess(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getJsonList(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _httpClient.get(uri, headers: _defaultHeaders());
    _ensureSuccess(response);
    final decoded = json.decode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'] as List<dynamic>;
    return [decoded];
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.post(uri, headers: _defaultHeaders(), body: json.encode(body));
    _ensureSuccess(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJsonWithAuth(String path, String token, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = _defaultHeaders();
    headers['Authorization'] = 'Bearer $token';
    final response = await _httpClient.get(uri, headers: headers);
    _ensureSuccess(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Map<String, String> _defaultHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}

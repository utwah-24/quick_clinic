import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    print('🔵 [DEBUG] POST JSON → $uri');
    print('🔵 [DEBUG] Request body: ${json.encode(body)}');
    print('🔵 [DEBUG] Response status: ${response.statusCode}');
    print('🔵 [DEBUG] Response body: ${response.body}');
    _ensureSuccess(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJsonWithAuth(String path, Map<String, dynamic> body, String token) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _defaultHeaders();
    headers['Authorization'] = 'Bearer $token';
    final response = await _httpClient.put(uri, headers: headers, body: json.encode(body));
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

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, dynamic> fields, {
    File? file,
    String fileFieldName = 'file',
    List<String>? fileFieldAliases,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    
    // Add headers
    request.headers.addAll({
      'Accept': 'application/json',
    });
    
    // Add fields
    fields.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        for (int index = 0; index < value.length; index++) {
          final fieldName = '$key[' + index.toString() + ']';
          request.fields[fieldName] = value[index].toString();
          print('🔵 [DEBUG] Added list item $fieldName: ${value[index].toString()}');
        }
      } else {
        request.fields[key] = value.toString();
        print('🔵 [DEBUG] Added field $key as string: ${value.toString()}');
      }
    });
    
    // Add file if provided
    if (file != null && await file.exists()) {
      final mediaType = _detectMediaType(file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
        contentType: mediaType,
      );
      request.files.add(multipartFile);
      print('🔵 [DEBUG] Added file $fileFieldName: ${file.path} (${await file.length()} bytes)');
      if (fileFieldAliases != null && fileFieldAliases.isNotEmpty) {
        for (final alias in fileFieldAliases) {
          if (alias == fileFieldName) continue;
          final aliasFile = await http.MultipartFile.fromPath(
            alias,
            file.path,
            contentType: mediaType,
          );
          request.files.add(aliasFile);
          print('🔵 [DEBUG] Added alias file $alias: ${file.path}');
        }
      }
    } else {
      print('🔵 [DEBUG] No file provided or file does not exist');
    }
    
    print('🔵 [DEBUG] Sending multipart request to: $uri');
    print('🔵 [DEBUG] Request fields: ${request.fields}');
    print('🔵 [DEBUG] Request files: ${request.files.map((f) => f.field).toList()}');
    
    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    
    print('🔵 [DEBUG] Multipart response status: ${response.statusCode}');
    print('🔵 [DEBUG] Multipart response body: ${response.body}');
    
    _ensureSuccess(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putMultipartWithAuth(String path, Map<String, dynamic> fields, String token, {File? file, String fileFieldName = 'file'}) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PUT', uri);
    
    // Add headers
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    
    // Add fields
    fields.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        for (int index = 0; index < value.length; index++) {
          final fieldName = '$key[' + index.toString() + ']';
          request.fields[fieldName] = value[index].toString();
        }
      } else {
        request.fields[key] = value.toString();
      }
    });
    
    // Add file if provided
    if (file != null && await file.exists()) {
      final mediaType = _detectMediaType(file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
        contentType: mediaType,
      );
      request.files.add(multipartFile);
    }
    
    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    
    _ensureSuccess(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  MediaType _detectMediaType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('application', 'octet-stream');
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

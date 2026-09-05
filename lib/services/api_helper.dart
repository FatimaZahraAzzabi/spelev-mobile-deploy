import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> headers() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> headersMultipart() async {
    final token = await _storage.read(key: 'jwt_token');
    return {'Authorization': 'Bearer $token'};
  }

  static void checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      String msg = 'Erreur ${res.statusCode}';
      try {
        final json = jsonDecode(res.body);
        if (json is Map && json['message'] != null) msg = json['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  /// Déballe le wrapper ApiResponse { data, message, success }
  static dynamic unwrap(String body) {
    final json = jsonDecode(body);
    if (json is Map && json.containsKey('success')) {
      if (json['success'] == true) return json['data'];
      throw Exception(json['message'] ?? 'Erreur serveur');
    }
    return json;
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';


class EvaluationService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>> creer(Map<String, dynamic> dto) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/evaluation'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return Map<String, dynamic>.from(jsonResponse['data'] ?? jsonResponse);
    } else {
      throw Exception('Erreur: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getMesEvaluations() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/mes-demandes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> all = jsonResponse['data'] ?? jsonResponse;
      return all
          .where((d) => d['typeDemande'] == 'EVALUATION')
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<void> annuler(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id/annuler'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
}
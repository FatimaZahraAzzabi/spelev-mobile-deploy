import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/parc_model.dart';

class ParcService {
  final String baseUrl =
      "${ApiConfig.baseUrl}/api/parcs";

  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception(
        "Utilisateur non connecté (Token manquant)",
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════
  //  RÉCUPÉRER TOUS LES PARCS
  // ═══════════════════════════════════════════════════════════

  /// GET /api/parcs
  Future<List<ParcModel>> getParcs() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final List<dynamic> dataList =
          jsonResponse['data'] ?? jsonResponse;

      return dataList
          .map((json) => ParcModel.fromJson(json))
          .toList();
    }

    throw Exception(
      'Erreur chargement parcs: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CRÉER UN PARC
  // ═══════════════════════════════════════════════════════════

  /// POST /api/parcs
  Future<ParcModel> createParc(String nom) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        'nom': nom,
      }),
    );

    if (response.statusCode == 201 ||
        response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return ParcModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    }

    throw Exception(
      'Erreur création parc: '
      '${response.statusCode} - ${response.body}',
    );
  }
}
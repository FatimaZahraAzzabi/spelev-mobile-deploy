import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/utilisateur_model.dart';

class UtilisateurService {
  final String baseUrl = '${ApiConfig.baseUrl}/api/utilisateurs';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Token manquant");
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Récupérer tous les utilisateurs
  // ═══════════════════════════════════════════════════════════

  Future<List<UtilisateurModel>> getUtilisateurs() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList =
          jsonResponse['data'] ?? jsonResponse;

      return dataList
          .map((json) => UtilisateurModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Erreur récupération utilisateurs: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Récupérer un utilisateur par ID
  // ═══════════════════════════════════════════════════════════

  Future<UtilisateurModel> getUtilisateurById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return UtilisateurModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    } else {
      throw Exception(
        'Erreur récupération utilisateur: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Créer un utilisateur
  // ═══════════════════════════════════════════════════════════

  Future<UtilisateurModel> createUtilisateur(
    UtilisateurCreateDTO dto,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode(dto.toMap()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      return UtilisateurModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    } else {
      throw Exception(
        'Erreur création utilisateur: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Modifier un utilisateur
  // ═══════════════════════════════════════════════════════════

  Future<UtilisateurModel> updateUtilisateur(
    int id,
    UtilisateurUpdateDTO dto,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
      body: jsonEncode(dto.toMap()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return UtilisateurModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    } else {
      throw Exception(
        'Erreur modification utilisateur: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Supprimer un utilisateur
  // ═══════════════════════════════════════════════════════════

  Future<void> deleteUtilisateur(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erreur suppression utilisateur: ${response.statusCode}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Récupérer les responsables maintenance
  // ═══════════════════════════════════════════════════════════

  Future<List<UtilisateurModel>> getResponsables() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final List<dynamic> dataList =
          jsonResponse['data'] ?? jsonResponse;

      return dataList
          .where(
            (json) =>
                json['type'] == 'RESPONSABLE_MAINTENANCE',
          )
          .map(
            (json) => UtilisateurModel.fromJson(json),
          )
          .toList();
    } else {
      throw Exception(
        'Erreur récupération responsables: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 Récupérer les techniciens
  // ═══════════════════════════════════════════════════════════

  Future<List<UtilisateurModel>> getTechniciens() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final List<dynamic> dataList =
          jsonResponse['data'] ?? jsonResponse;

      return dataList
          .where(
            (json) =>
                json['type'] == 'TECHNICIEN' ||
                json['technicien'] != null,
          )
          .map(
            (json) => UtilisateurModel.fromJson(json),
          )
          .toList();
    } else {
      throw Exception(
        'Erreur récupération techniciens: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }
}
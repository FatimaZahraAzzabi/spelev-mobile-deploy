import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/tache_model.dart';

class TacheService {
  final String baseUrl = '${ApiConfig.baseUrl}/api/taches';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<List<TacheModel>> getTaches() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList =
          jsonResponse['data'] ?? jsonResponse;

      return dataList
          .map((json) => TacheModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Erreur: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<TacheModel>> getMesTaches() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('$baseUrl/mes-taches'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList =
          jsonResponse['data'] ?? jsonResponse;

      return dataList
          .map((json) => TacheModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Erreur: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<TacheModel> createTache(
    Map<String, dynamic> dto,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      return TacheModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    } else {
      throw Exception(
        'Erreur: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<TacheModel> updateStatut(
    int id,
    String statut,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.put(
      Uri.parse('$baseUrl/$id/statut'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'statut': statut,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return TacheModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    } else {
      throw Exception(
        'Erreur: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteTache(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Erreur suppression: ${response.statusCode}',
      );
    }
  }

  Future<TacheModel> assignerTechniciens(
    int tacheId,
    List<int> technicienIds,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.put(
      Uri.parse('$baseUrl/$tacheId/assigner-techniciens'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'technicienIds': technicienIds,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return TacheModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    } else {
      throw Exception(
        'Erreur assignation: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
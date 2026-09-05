import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/client_model.dart';

class ClientService {
  final String baseUrl =
      "${ApiConfig.baseUrl}/api/utilisateurs";

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
  // 1. RÉCUPÉRER LA LISTE DES CLIENTS
  // ═══════════════════════════════════════════════════════════

  Future<List<ClientModel>> getClients() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final List<dynamic> data =
          jsonResponse['data'] ?? jsonResponse;

      // On garde uniquement les utilisateurs de type CLIENT
      return data
          .where((json) => json['type'] == 'CLIENT')
          .map((json) => ClientModel.fromJson(json))
          .toList();
    }

    throw Exception(
      'Erreur lors du chargement des clients: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 2. CRÉER UN CLIENT
  // ═══════════════════════════════════════════════════════════

  Future<ClientModel> createClient(
    ClientModel client,
    String motDePasse,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode(
        client.toMap(
          motDePasse: motDePasse,
        ),
      ),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      return ClientModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    }

    throw Exception(
      'Erreur création: ${response.body}',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 3. MODIFIER UN CLIENT
  // ═══════════════════════════════════════════════════════════

  Future<ClientModel> updateClient(
    int id,
    ClientModel client,
    String? motDePasse,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
      body: jsonEncode(
        client.toMap(
          motDePasse: motDePasse,
        ),
      ),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      return ClientModel.fromJson(
        jsonResponse['data'] ?? jsonResponse,
      );
    }

    throw Exception(
      'Erreur modification: ${response.body}',
    );
  }
}
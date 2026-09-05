import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/composant_model.dart';

class ComposantService {
  final String rootUrl = "${ApiConfig.baseUrl}/api";

  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 RÉCUPÉRER LES COMPOSANTS D'UN ASSEMBLAGE
  // ═══════════════════════════════════════════════════════════

  /// GET /api/composants/assemblage/{assemblageId}
  Future<List<ComposantModel>> getParAssemblage(
    int assemblageId,
  ) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(
        '$rootUrl/composants/assemblage/$assemblageId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final List<dynamic> data =
          json['data'] ?? json;

      return data
          .map((e) => ComposantModel.fromJson(e))
          .toList();
    }

    throw Exception(
      'Erreur chargement composants: '
      '${response.statusCode}',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  UPLOAD IMAGE
  // ═══════════════════════════════════════════════════════════

  /// POST /api/composants/{id}/image
  Future<ComposantModel> uploaderImage(
    int id,
    File imageFile,
  ) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$rootUrl/composants/$id/image'),
    );

    request.headers['Authorization'] =
        'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final response = await request.send();

    final responseBody =
        await response.stream.bytesToString();

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final json = jsonDecode(responseBody);

      return ComposantModel.fromJson(
        json['data'] ?? json,
      );
    }

    throw Exception(
      'Erreur upload image: ${response.statusCode}',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔹 CRÉER UN COMPOSANT
  // ═══════════════════════════════════════════════════════════

  /// POST /api/composants
  Future<ComposantModel> creer(
    Map<String, dynamic> dto,
  ) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$rootUrl/composants'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final json = jsonDecode(response.body);

      return ComposantModel.fromJson(
        json['data'] ?? json,
      );
    }

    throw Exception(
      'Erreur création: ${response.body}',
    );
  }
}
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/assemblage_model.dart';

class AssemblageService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<List<AssemblageModel>> getArbreParAscenseur(
      int ascenseurId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/assemblages/ascenseur/$ascenseurId/arbre',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final List<dynamic> data = json['data'] ?? json;

      return data
          .map((e) => AssemblageModel.fromJson(e))
          .toList();
    }

    throw Exception(
      'Erreur chargement arbre: ${response.statusCode}',
    );
  }

  Future<AssemblageModel> uploaderImage(
      int id, File imageFile) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/api/assemblages/$id/image',
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';

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

      return AssemblageModel.fromJson(
        json['data'] ?? json,
      );
    }

    throw Exception(
      'Erreur upload image: ${response.statusCode}',
    );
  }

  Future<AssemblageModel> creer(
      Map<String, dynamic> dto) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/assemblages',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final json = jsonDecode(response.body);

      return AssemblageModel.fromJson(
        json['data'] ?? json,
      );
    }

    throw Exception(
      'Erreur création: ${response.body}',
    );
  }

  Future<void> supprimer(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/assemblages/$id',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Erreur suppression: ${response.body}',
      );
    }
  }
}
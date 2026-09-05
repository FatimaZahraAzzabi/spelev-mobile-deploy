import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class PieceJointeService {
  final String _baseUrl = "${ApiConfig.baseUrl}/api/pieces-jointes";
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> uploaderFichier({
    required String filePath,
    required String entiteType,
    required int entiteId,
    String? description,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_baseUrl),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['entiteType'] = entiteType;
    request.fields['entiteId'] = entiteId.toString();
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }

    request.files.add(await http.MultipartFile.fromPath('fichier', filePath));

    debugPrint('📤 Upload vers: $_baseUrl');
    debugPrint('   entiteType: $entiteType, entiteId: $entiteId');
    debugPrint('   fichier: $filePath');

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    debugPrint('📥 Réponse upload: ${res.statusCode}');
    debugPrint('   Body: ${res.body}');

    if (res.statusCode >= 400) {
      throw Exception('Échec de l\'upload (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> supprimer(int pieceJointeId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final res = await http.delete(
      Uri.parse('$_baseUrl/$pieceJointeId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode >= 400) {
      throw Exception('Échec de la suppression (${res.statusCode})');
    }
  }
}
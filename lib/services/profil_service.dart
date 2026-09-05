import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/profil_model.dart';

class ProfilService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");
    final h = <String, String>{'Authorization': 'Bearer $token'};
    if (json) h['Content-Type'] = 'application/json';
    return h;
  }

  Future<ProfilModel> getProfil() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/utilisateurs/profil'),
      headers: await _headers(),
    );



    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      return ProfilModel.fromJson(data);
    } else {
      throw Exception('Erreur: ${response.statusCode} - ${response.body}');
    }
  }

   String getPhotoUrl() {
  return '${ApiConfig.baseUrl}/api/utilisateurs/photo';
  }

  Future<ProfilModel> modifierProfil(Map<String, dynamic> dto) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/utilisateurs/profil'),
      headers: await _headers(),
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      return ProfilModel.fromJson(data);
    } else {
      throw Exception('Erreur: ${response.statusCode} - ${response.body}');
    }
  }

  Future<ProfilModel> modifierPhoto(String filePath) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/api/utilisateurs/profil/photo'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    final ext = filePath.split('.').last.toLowerCase();
    String mime = 'image/jpeg';
    if (ext == 'png') mime = 'image/png';
    if (ext == 'webp') mime = 'image/webp';

    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      filePath,
      contentType: MediaType.parse(mime),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      return ProfilModel.fromJson(data);
    } else {
      throw Exception('Erreur upload: ${response.statusCode} - ${response.body}');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart'; 

class StatistiqueService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/statistiques';
  
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, int>> getStatistiquesResponsable() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('$baseUrl/responsable'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      
      return {
        'interventionsEnCours': data['interventionsEnCours'] ?? 0,
        'techniciensDisponibles': data['techniciensDisponibles'] ?? 0,
        'urgencesSignalees': data['urgencesSignalees'] ?? 0,
        'sitesActifs': data['sitesActifs'] ?? 0,
      };
    } else {
      throw Exception('Erreur serveur: ${response.statusCode} - ${response.body}');
    }
  }
}
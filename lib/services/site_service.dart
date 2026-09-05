import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/site_model.dart';
import '../models/utilisateur_model.dart';
import '../models/parc_model.dart';
import '../models/ville_model.dart';

class SiteService {
  final _storage = const FlutterSecureStorage();

  String get _baseUrlSites => '${ApiConfig.baseUrl}/api/sites';
  String get _rootUrl => ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<List<SiteModel>> getSites() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse(_baseUrlSites),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data'] ?? jsonResponse; 
      return dataList.map((json) => SiteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<SiteModel>> getSitesByClient(int clientId) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('$_baseUrlSites/client/$clientId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data'] ?? jsonResponse;
      return dataList.map((json) => SiteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<SiteModel> createSite(Map<String, dynamic> dto) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.post(
      Uri.parse(_baseUrlSites),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return SiteModel.fromJson(jsonResponse['data'] ?? jsonResponse);
    } else {
      throw Exception('Erreur création site: ${response.statusCode} - ${response.body}');
    }
  }

  Future<SiteModel> updateSite(int id, Map<String, dynamic> dto) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.put(
      Uri.parse('$_baseUrlSites/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SiteModel.fromJson(jsonResponse['data'] ?? jsonResponse);
    } else {
      throw Exception('Erreur mise à jour site: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<UtilisateurModel>> getClients() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('$_rootUrl/api/utilisateurs/clients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data'] ?? jsonResponse;
      return dataList.map((json) => UtilisateurModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement clients: ${response.statusCode}');
    }
  }

  Future<List<VilleModel>> getVilles() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('$_rootUrl/api/villes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data'] ?? jsonResponse;
      return dataList.map((json) => VilleModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement villes: ${response.statusCode}');
    }
  }

  Future<List<ParcModel>> getParcs() async {
    final token = await _getToken(); 
    if (token == null) throw Exception("Token manquant");

    final response = await http.get(
      Uri.parse('$_rootUrl/api/parcs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data'] ?? jsonResponse; 
      return dataList.map((json) => ParcModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement parcs: ${response.statusCode}');
    }
  }
}
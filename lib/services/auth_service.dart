import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/utilisateur_model.dart'; 

class AuthService {
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>?> login(String email, String motDePasse) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/login");
    try {
      print(" Tentative de connexion pour : $email");
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "motDePasse": motDePasse}),
      );

      print(" Réponse du serveur - Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print(" Réponse décodée: $jsonResponse");
        
        final data = jsonResponse['data']; 
        if (data != null && data['token'] != null) {
          await _storage.write(key: 'jwt_token', value: data['token']);
          await _storage.write(key: 'user_data', value: jsonEncode(data));
          return data;
        }
      } else {
        print(" Erreur HTTP ${response.statusCode}");
      }
    } catch (e) {
      print(" Exception login: $e");
    }
    return null;
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<UtilisateurModel?> getCurrentUser() async {
    final userStr = await _storage.read(key: 'user_data');
    if (userStr != null) {
      return UtilisateurModel.fromJson(jsonDecode(userStr));
    }
    return null;
  }


     // ✅ NOUVEAU : Demander un lien de réinitialisation
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/mot-de-passe-oublie");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return true; // Succès
      } else {
        print(" Erreur forgotPassword: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print(" Exception forgotPassword: $e");
      return false;
    }
  }

  Future<bool> resetPassword(String token, String nouveauMotDePasse) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/auth/reinitialiser-mot-de-passe");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "nouveauMotDePasse": nouveauMotDePasse,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(" Erreur resetPassword: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print(" Exception resetPassword: $e");
      return false;
    }
  } 
  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_data');
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/commentaire_model.dart';
import 'api_helper.dart';

class CommentaireService {
  /// Récupère tous les commentaires d'un bon de travail
  Future<List<CommentaireModel>> lister(int bonTravailId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bons-travail/$bonTravailId/commentaires'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    
    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => CommentaireModel.fromJson(e)).toList();
  }

  /// Ajoute un commentaire
  Future<CommentaireModel> ajouter(int bonTravailId, String contenu) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/bons-travail/$bonTravailId/commentaires'),
      headers: await ApiHelper.headers(),
      body: jsonEncode({'contenu': contenu}),
    );
    ApiHelper.checkStatus(res);
    
    final data = jsonDecode(res.body);
    return CommentaireModel.fromJson(data['data'] ?? data);
  }

  /// Supprime un commentaire
  Future<void> supprimer(int bonTravailId, int commentaireId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/bons-travail/$bonTravailId/commentaires/$commentaireId'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
  }
}
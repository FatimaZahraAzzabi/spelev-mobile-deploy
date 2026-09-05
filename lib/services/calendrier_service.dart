import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/calendrier_event_model.dart';
import 'api_helper.dart';

class CalendrierService {
  Future<List<CalendrierEventModel>> getEvenements({
    required DateTime debut,
    required DateTime fin,
    int? technicienId,
  }) async {
    final debutStr = debut.toIso8601String();
    final finStr = fin.toIso8601String();

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/calendrier').replace(
      queryParameters: {
        'debut': debutStr,
        'fin': finStr,
        if (technicienId != null) 'technicienId': technicienId.toString(),
      },
    );

    final res = await http.get(uri, headers: await ApiHelper.headers());
    ApiHelper.checkStatus(res);
    
    final data = ApiHelper.unwrap(res.body);
    return (data as List).map((e) => CalendrierEventModel.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getTechniciens() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/utilisateurs'), 
      headers: await ApiHelper.headers(),
    );
    
    if (res.statusCode == 200) {
      final data = ApiHelper.unwrap(res.body);
      return (data as List)
          .where((e) => e['type'] == 'TECHNICIEN')
          .map((e) => {'id': e['id'] as int, 'nom': '${e['prenom']} ${e['nom']}'})
          .toList();
    }
    return [];
  }

  Future<void> creerEvenement({
    required String titre,
    required String type,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? description,
    String? lieu,
    List<int>? technicienIds,
  }) async {
    final body = {
      'titre': titre,
      'type': type,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      if (description != null && description.isNotEmpty) 'description': description,
      if (lieu != null && lieu.isNotEmpty) 'lieu': lieu,
      if (technicienIds != null && technicienIds.isNotEmpty) 'technicienIds': technicienIds,
    };

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/evenements'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(body),
    );
    
    ApiHelper.checkStatus(res);
  }
}
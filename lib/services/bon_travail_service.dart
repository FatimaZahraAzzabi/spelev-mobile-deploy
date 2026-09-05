import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/bon_travail_model.dart';
import '../models/bon_travail_create_model.dart';
import 'api_helper.dart';

class BonTravailService {
  /// Liste tous les bons de travail
  Future<List<BonTravailModel>> lister() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bons-travail'),
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    final data = ApiHelper.unwrap(res.body);

    return (data as List)
        .map((e) => BonTravailModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  /// Liste les interventions du technicien connecté
  Future<List<BonTravailModel>> getMesInterventions() async {
    final res = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/bons-travail/mes-interventions',
      ),
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    final data = ApiHelper.unwrap(res.body);

    return (data as List)
        .map((e) => BonTravailModel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  /// Détail d'un bon de travail
  Future<BonTravailModel> getDetail(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bons-travail/$id'),
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    return BonTravailModel.fromJson(
      Map<String, dynamic>.from(
        ApiHelper.unwrap(res.body),
      ),
    );
  }

  /// Détail d'une intervention du technicien connecté
  Future<BonTravailModel> getDetailIntervention(int id) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/bons-travail/mes-interventions/$id',
      ),
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    return BonTravailModel.fromJson(
      Map<String, dynamic>.from(
        ApiHelper.unwrap(res.body),
      ),
    );
  }

  /// Créer un bon de travail
  Future<BonTravailModel> creer(
    BonTravailCreateModel dto,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/bons-travail'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(dto.toJson()),
    );

    ApiHelper.checkStatus(res);

    return BonTravailModel.fromJson(
      Map<String, dynamic>.from(
        ApiHelper.unwrap(res.body),
      ),
    );
  }

  /// Annuler un bon de travail
  Future<BonTravailModel> annuler(int id) async {
    final res = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/bons-travail/$id/annuler',
      ),
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    return BonTravailModel.fromJson(
      Map<String, dynamic>.from(
        ApiHelper.unwrap(res.body),
      ),
    );
  }

  /// Vérifier la disponibilité d'une liste de techniciens
  Future<List<Map<String, dynamic>>> verifierDisponibilite({
    required List<int> technicienIds,
    required DateTime debut,
    required int dureeMinutes,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/bons-travail/verifier-disponibilite',
    ).replace(
      queryParameters: {
        'technicienIds': technicienIds.join(','),
        'debut': debut.toIso8601String(),
        'dureeMinutes': dureeMinutes.toString(),
      },
    );

    final res = await http.get(
      uri,
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    final data = ApiHelper.unwrap(res.body);

    return List<Map<String, dynamic>>.from(data);
  }

  
  Future<List<Map<String, dynamic>>> getTechniciensDisponibles({
    required int ascenseurId,
    required DateTime debut,
    required int dureeMinutes,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/bons-travail/techniciens-disponibles',
    ).replace(
      queryParameters: {
        'ascenseurId': ascenseurId.toString(),
        'debut': debut.toIso8601String(),
        'dureeMinutes': dureeMinutes.toString(),
      },
    );

    final res = await http.get(
      uri,
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    final data = ApiHelper.unwrap(res.body);

    return List<Map<String, dynamic>>.from(data);
  }

  
  Future<List<Map<String, dynamic>>> getTechniciensDisponiblesParSite({
    required int siteId,
    required DateTime debut,
    required int dureeMinutes,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/bons-travail/techniciens-disponibles',
    ).replace(
      queryParameters: {
        'siteId': siteId.toString(),
        'debut': debut.toIso8601String(),
        'dureeMinutes': dureeMinutes.toString(),
      },
    );

    final res = await http.get(
      uri,
      headers: await ApiHelper.headers(),
    );

    ApiHelper.checkStatus(res);

    final data = ApiHelper.unwrap(res.body);

    return List<Map<String, dynamic>>.from(data);
  }
}
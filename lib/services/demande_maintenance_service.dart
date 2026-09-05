import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/demande_maintenance_model.dart';
import 'api_helper.dart';

class DemandeMaintenanceService {
  // ─── Côté CLIENT ────────────────────────────────────────

  Future<List<DemandeMaintenanceModel>> getMesDemandes() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/mes-demandes'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    final data = ApiHelper.unwrap(res.body);
    return (data as List).map((e) => DemandeMaintenanceModel.fromJson(e)).toList();
  }

  Future<DemandeMaintenanceModel> getDetail(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return DemandeMaintenanceModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<DemandeMaintenanceModel> creerDemande(Map<String, dynamic> dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(dto),
    );
    ApiHelper.checkStatus(res);
    return DemandeMaintenanceModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<void> annuler(int id) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id/annuler'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
  }

  // ─── Côté RESPONSABLE MAINTENANCE ───────────────────────

  Future<List<DemandeMaintenanceModel>> getDemandesEnAttente() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/en-attente'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    final data = ApiHelper.unwrap(res.body);
    return (data as List).map((e) => DemandeMaintenanceModel.fromJson(e)).toList();
  }

  Future<List<DemandeMaintenanceModel>> getToutesDemandes({String? statut}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/toutes')
        .replace(queryParameters: statut != null ? {'statut': statut} : null);
    final res = await http.get(uri, headers: await ApiHelper.headers());
    ApiHelper.checkStatus(res);
    final data = ApiHelper.unwrap(res.body);
    return (data as List).map((e) => DemandeMaintenanceModel.fromJson(e)).toList();
  }

  Future<DemandeMaintenanceModel> getDetailPourResponsable(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/gestion/$id'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return DemandeMaintenanceModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<DemandeMaintenanceModel> accepterDemande(int id) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id/accepter'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return DemandeMaintenanceModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<DemandeMaintenanceModel> rejeterDemande(int id, String motif) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id/rejeter'),
      headers: await ApiHelper.headers(),
      body: jsonEncode({'motif': motif}),
    );
    ApiHelper.checkStatus(res);
    return DemandeMaintenanceModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<String> genererDescriptionIa(int demandeId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$demandeId/generer-description-ia'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return ApiHelper.unwrap(res.body) as String;
  }

  Future<String> genererDescriptionIaOld(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id/generer-description-ia'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return ApiHelper.unwrap(res.body) as String;
  }

 

  Future<List<DemandeMaintenanceModel>> getDemandesInstallations() async {
    final all = await getToutesDemandes();
    return all.where((d) => d.typeDemande == 'EVALUATION').toList();
  }

  Future<List<DemandeMaintenanceModel>> getDemandesMaintenance() async {
    final all = await getToutesDemandes();
    return all.where((d) => d.typeDemande != 'EVALUATION').toList();
  }

  Future<Map<String, dynamic>> getDemandeAvecEvaluation(int demandeId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$demandeId/avec-evaluation'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return ApiHelper.unwrap(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> soumettreEvaluation(
    int evaluationId, 
    Map<String, dynamic> dto
  ) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/evaluations-ascenseur/$evaluationId/soumettre'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(dto),
    );
    ApiHelper.checkStatus(res);
    return ApiHelper.unwrap(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validerEvaluation(
    int evaluationId, 
    Map<String, dynamic> dto
  ) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/evaluations-ascenseur/$evaluationId/valider'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(dto),
    );
    ApiHelper.checkStatus(res);
    return ApiHelper.unwrap(res.body) as Map<String, dynamic>;
  }
}
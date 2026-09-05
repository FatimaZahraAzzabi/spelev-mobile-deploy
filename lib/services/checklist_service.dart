import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/checklist_model.dart';
import 'api_helper.dart';

class ChecklistService {
  Future<ChecklistModel> getByBonTravail(int bonTravailId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/par-bon-travail/$bonTravailId'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return ChecklistModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<ChecklistModel> getDetail(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/$id'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return ChecklistModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<ChecklistModel> demarrer(int checklistId) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/$checklistId/demarrer'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return ChecklistModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<ChecklistModel> cocherItem({
    required int itemId,
    required StatutItem statut,
    GraviteAnomalie? gravite,
    String? remarque,
  }) async {
    final body = <String, dynamic>{'statut': statut.name};
    if (statut == StatutItem.ANOMALIE_DETECTEE && gravite != null) {
      body['gravite'] = gravite.name;
    }
    if (remarque != null && remarque.isNotEmpty) {
      body['remarque'] = remarque;
    }

    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/items/$itemId'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(body),
    );
    ApiHelper.checkStatus(res);
    return ChecklistModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<ChecklistModel> cloturer({
    required int checklistId,
    required String bilanIntervention,
    required bool estMaintenance,
    required bool estDepannage,
    required bool estTravaux,
  }) async {
    final body = {
      'bilanIntervention': bilanIntervention,
      'estMaintenance': estMaintenance,
      'estDepannage': estDepannage,
      'estTravaux': estTravaux,
    };

    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/$checklistId/cloturer'),
      headers: await ApiHelper.headers(),
      body: jsonEncode(body),
    );
    ApiHelper.checkStatus(res);
    return ChecklistModel.fromJson(ApiHelper.unwrap(res.body));
  }

  Future<ItemCheckListModel> ajouterPhotoItem(int itemId, File photoFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/items/$itemId/photos'),
    );
    
    
    request.headers.addAll(await ApiHelper.headersMultipart());
    
    request.files.add(await http.MultipartFile.fromPath('file', photoFile.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    ApiHelper.checkStatus(response);
    final data = ApiHelper.unwrap(response.body);
    return ItemCheckListModel.fromJson(data);
  }
}
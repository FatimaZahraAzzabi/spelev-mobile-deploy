import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rapport_model.dart';
import 'api_helper.dart';

class RapportService {
  Future<List<RapportModel>> getRapportsAValider() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/rapports-a-valider'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    final data = ApiHelper.unwrap(res.body);
    return (data as List).map((e) => RapportModel.fromJson(e)).toList();
  }

  Future<RapportModel> getRapportDetail(int id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/checklists/$id'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    return RapportModel.fromJson(ApiHelper.unwrap(res.body));
  }
}
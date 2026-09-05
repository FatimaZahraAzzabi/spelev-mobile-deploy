import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_helper.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    final data = jsonDecode(res.body);
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/non-lues/count'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
    final data = jsonDecode(res.body);
    if (data is int) return data;
    if (data is Map && data['data'] != null) return data['data'] as int;
    return 0;
  }

  Future<void> markAsRead(int id) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/lire'),
      headers: await ApiHelper.headers(),
    );
    ApiHelper.checkStatus(res);
  }
}
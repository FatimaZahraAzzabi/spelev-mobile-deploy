import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notif) async {
    if (!notif.lu) {
      await _service.markAsRead(notif.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notif.id, type: notif.type, titre: notif.titre,
            message: notif.message, entiteType: notif.entiteType,
            entiteId: notif.entiteId, lu: true, dateCreation: notif.dateCreation,
          );
        }
      });
    }

   
  }

  IconData _getIconForType(TypeNotification type) {
    switch (type) {
      case TypeNotification.NOUVEAU_TRAVAIL_ASSIGNE: return Icons.assignment_add;
      case TypeNotification.TRAVAIL_TERMINE: return Icons.check_circle;
      case TypeNotification.TRAVAIL_ANNULE: return Icons.cancel;
      case TypeNotification.DEMANDE_REJETEE: return Icons.thumb_down;
      case TypeNotification.EVALUATION_A_VALIDER: return Icons.fact_check;
      case TypeNotification.STATUT_DEMANDE_CHANGE: return Icons.info_outline;
    }
  }

  Color _getColorForType(TypeNotification type) {
    switch (type) {
      case TypeNotification.NOUVEAU_TRAVAIL_ASSIGNE: return Colors.blue;
      case TypeNotification.TRAVAIL_TERMINE: return Colors.green;
      case TypeNotification.TRAVAIL_ANNULE: 
      case TypeNotification.DEMANDE_REJETEE: return Colors.red;
      case TypeNotification.EVALUATION_A_VALIDER: return Colors.orange;
      case TypeNotification.STATUT_DEMANDE_CHANGE: return Colors.grey;
    }
  }

  String _formatDateFr(DateTime date) {
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    final monthName = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} $monthName à $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Notifications', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune notification', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final color = _getColorForType(notif.type);
                    
                    return Card(
                      elevation: notif.lu ? 0 : 1,
                      color: notif.lu ? Colors.white : Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: notif.lu ? Colors.grey[200]! : color.withOpacity(0.3)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _handleNotificationTap(notif),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_getIconForType(notif.type), color: color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.titre,
                                            style: TextStyle(
                                              fontWeight: notif.lu ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (!notif.lu)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDateFr(notif.dateCreation),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
enum TypeNotification {
  NOUVEAU_TRAVAIL_ASSIGNE,
  TRAVAIL_TERMINE,
  TRAVAIL_ANNULE,
  DEMANDE_REJETEE,
  EVALUATION_A_VALIDER,
  STATUT_DEMANDE_CHANGE
}

class NotificationModel {
  final int id;
  final TypeNotification type;
  final String titre;
  final String message;
  final String? entiteType;
  final int? entiteId;
  final bool lu;
  final DateTime dateCreation;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    this.entiteType,
    this.entiteId,
    required this.lu,
    required this.dateCreation,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      type: TypeNotification.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TypeNotification.STATUT_DEMANDE_CHANGE,
      ),
      titre: json['titre'] as String,
      message: json['message'] as String,
      entiteType: json['entiteType'] as String?,
      entiteId: json['entiteId'] as int?,
      lu: json['lu'] as bool,
      dateCreation: DateTime.parse(json['dateCreation'] as String),
    );
  }
}
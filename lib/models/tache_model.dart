class TacheModel {
  final int id;
  final String titre;
  final String? description;
  final String type; // PREVENTIF ou CORRECTIF
  final String statut; // A_FAIRE, EN_COURS, TERMINE, ANNULE
  final String priorite; // BASSE, MOYENNE, HAUTE, URGENTE
  final DateTime? dateEcheance;
  final DateTime? dateCreation;
  final DateTime? dateCompletion;

  final int? ascenseurId;
  final String? ascenseurNom;
  final String? ascenseurSite;
  final String? ascenseurClient;

  final List<int>? technicienIds;
  final List<String>? technicienNoms;


  final int? createurId;
  final String? createurNom;
  final int? responsableId;
  final String? responsableNom;

  TacheModel({
    required this.id,
    required this.titre,
    this.description,
    this.technicienIds,
   this.technicienNoms,
    required this.type,
    required this.statut,
    required this.priorite,
    this.dateEcheance,
    this.dateCreation,
    this.dateCompletion,
    this.ascenseurId,
    this.ascenseurNom,
    this.ascenseurSite,
    this.ascenseurClient,
    this.createurId,
    this.createurNom,
    this.responsableId,
    this.responsableNom,
  });

  factory TacheModel.fromJson(Map<String, dynamic> json) {
    return TacheModel(
      id: json['id'] as int,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'PREVENTIF',
      statut: json['statut'] as String? ?? 'A_FAIRE',
      priorite: json['priorite'] as String? ?? 'MOYENNE',
      technicienIds: json['technicienIds'] != null ? List<int>.from(json['technicienIds']) : null,
  technicienNoms: json['technicienNoms'] != null ? List<String>.from(json['technicienNoms']) : null,
      dateEcheance: json['dateEcheance'] != null 
          ? DateTime.parse(json['dateEcheance']) 
          : null,
      dateCreation: json['dateCreation'] != null 
          ? DateTime.parse(json['dateCreation']) 
          : null,
      dateCompletion: json['dateCompletion'] != null 
          ? DateTime.parse(json['dateCompletion']) 
          : null,
      ascenseurId: json['ascenseurId'] as int?,
      ascenseurNom: json['ascenseurNom'] as String?,
      ascenseurSite: json['ascenseurSite'] as String?,
      ascenseurClient: json['ascenseurClient'] as String?,
      createurId: json['createurId'] as int?,
      createurNom: json['createurNom'] as String?,
      responsableId: json['responsableId'] as int?,
      responsableNom: json['responsableNom'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'type': type,
      'statut': statut,
      'priorite': priorite,
      'dateEcheance': dateEcheance?.toIso8601String(),
    };
  }
}
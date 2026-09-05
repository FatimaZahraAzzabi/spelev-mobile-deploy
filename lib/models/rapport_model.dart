import 'piece_jointe_model.dart';

enum StatutItemRapport { NON_VERIFIE, CONFORME, ANOMALIE_DETECTEE }
enum GraviteAnomalieRapport { MINEURE, MAJEURE, CRITIQUE }

class ItemRapportModel {
  final int id;
  final int ordre;
  final String libelle;
  final StatutItemRapport statut;
  final GraviteAnomalieRapport? gravite;
  final String? remarque;
  final List<PieceJointeModel> piecesJointes;

  const ItemRapportModel({
    required this.id,
    required this.ordre,
    required this.libelle,
    required this.statut,
    this.gravite,
    this.remarque,
    this.piecesJointes = const [],
  });

  factory ItemRapportModel.fromJson(Map<String, dynamic> json) {
    return ItemRapportModel(
      id: json['id'] as int,
      ordre: json['ordre'] as int,
      libelle: json['libelle'] as String,
      statut: StatutItemRapport.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => StatutItemRapport.NON_VERIFIE,
      ),
      gravite: json['gravite'] != null
          ? GraviteAnomalieRapport.values.firstWhere(
              (e) => e.name == json['gravite'],
              orElse: () => GraviteAnomalieRapport.MINEURE,
            )
          : null,
      remarque: json['remarque'] as String?,
      piecesJointes: (json['piecesJointes'] as List?)
              ?.map((p) => PieceJointeModel.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class RapportModel {
  final int id;
  final int mois;
  final int annee;
  final int ascenseurId;
  final String ascenseurNom;
  final int bonTravailId;
  final int? technicienId;
  final String? technicienNom;
  final String? heureArrivee;
  final String? heureDepart;
  final bool estMaintenance;
  final bool estDepannage;
  final bool estTravaux;
  final String? bilanIntervention;
  final List<ItemRapportModel> items;

  const RapportModel({
    required this.id,
    required this.mois,
    required this.annee,
    required this.ascenseurId,
    required this.ascenseurNom,
    required this.bonTravailId,
    this.technicienId,
    this.technicienNom,
    this.heureArrivee,
    this.heureDepart,
    this.estMaintenance = false,
    this.estDepannage = false,
    this.estTravaux = false,
    this.bilanIntervention,
    this.items = const [],
  });

  factory RapportModel.fromJson(Map<String, dynamic> json) {
    String? parseTime(dynamic timeData) {
      if (timeData == null) return null;
      if (timeData is String) return timeData;
      if (timeData is List) return '${timeData[0]}:${timeData[1]}';
      return timeData.toString();
    }

    return RapportModel(
      id: json['id'] as int,
      mois: json['mois'] as int,
      annee: json['annee'] as int,
      ascenseurId: json['ascenseurId'] as int,
      ascenseurNom: json['ascenseurNom'] as String? ?? '',
      bonTravailId: json['bonTravailId'] as int,
      technicienId: json['technicienId'] as int?,
      technicienNom: json['technicienNom'] as String?,
      heureArrivee: parseTime(json['heureArrivee']),
      heureDepart: parseTime(json['heureDepart']),
      estMaintenance: json['estMaintenance'] as bool? ?? false,
      estDepannage: json['estDepannage'] as bool? ?? false,
      estTravaux: json['estTravaux'] as bool? ?? false,
      bilanIntervention: json['bilanIntervention'] as String?,
      items: (json['items'] as List?)
              ?.map((e) => ItemRapportModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
enum StatutItem { NON_VERIFIE, CONFORME, ANOMALIE_DETECTEE }
enum GraviteAnomalie { MINEURE, MAJEURE, CRITIQUE }

class ItemCheckListModel {
  final int id;
  final int ordre;
  final String libelle;
  final StatutItem statut;
  final GraviteAnomalie? gravite;
  final String? remarque;
  final List<Map<String, dynamic>> piecesJointes;

  const ItemCheckListModel({
    required this.id,
    required this.ordre,
    required this.libelle,
    required this.statut,
    this.gravite,
    this.remarque,
    this.piecesJointes = const [],
  });

  factory ItemCheckListModel.fromJson(Map<String, dynamic> json) {
    return ItemCheckListModel(
      id: json['id'] as int,
      ordre: json['ordre'] as int,
      libelle: json['libelle'] as String,
      statut: StatutItem.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => StatutItem.NON_VERIFIE,
      ),
      gravite: json['gravite'] != null
          ? GraviteAnomalie.values.firstWhere(
              (e) => e.name == json['gravite'],
              orElse: () => GraviteAnomalie.MINEURE,
            )
          : null,
      remarque: json['remarque'] as String?,
      piecesJointes: (json['piecesJointes'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}

class ChecklistModel {
  final int id;
  final int mois;
  final int annee;
  final int ascenseurId;
  final String ascenseurNom;
  final int bonTravailId;
  final int? technicienId;
  final String? technicienNom;
  final DateTime? heureArrivee;
  final DateTime? heureDepart;
  final bool estMaintenance;
  final bool estDepannage;
  final bool estTravaux;
  final String? bilanIntervention;
  final List<ItemCheckListModel> items;

  const ChecklistModel({
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

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseHeure(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        final parts = value.split(':');
        return DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day,
          int.parse(parts[0]), int.parse(parts[1]),
        );
      } catch (e) {
        return null;
      }
    }

    return ChecklistModel(
      id: json['id'] as int,
      mois: json['mois'] as int,
      annee: json['annee'] as int,
      ascenseurId: json['ascenseurId'] as int,
      ascenseurNom: json['ascenseurNom'] as String? ?? '',
      bonTravailId: json['bonTravailId'] as int,
      technicienId: json['technicienId'] as int?,
      technicienNom: json['technicienNom'] as String?,
      heureArrivee: parseHeure(json['heureArrivee'] as String?),
      heureDepart: parseHeure(json['heureDepart'] as String?),
      estMaintenance: json['estMaintenance'] as bool? ?? false,
      estDepannage: json['estDepannage'] as bool? ?? false,
      estTravaux: json['estTravaux'] as bool? ?? false,
      bilanIntervention: json['bilanIntervention'] as String?,
      items: (json['items'] as List?)?.map((e) => ItemCheckListModel.fromJson(e)).toList() ?? [],
    );
  }
}
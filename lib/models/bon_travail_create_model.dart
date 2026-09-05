class BonTravailCreateModel {
  final int? demandeMaintenanceId;
  final int? ascenseurId;
  final int? parcId;
  final int? siteId;
  final int technicienResponsableId;
  final List<int>? technicienIdsRenfort;
  final DateTime dateInterventionPrevue;
  final int dureeEstimeeMinutes;
  final String? priorite;
  final String? description;
  final bool visitePreventive;
  final bool isEvaluation; 

  BonTravailCreateModel({
    this.demandeMaintenanceId,
    this.ascenseurId,
    this.parcId,
    this.siteId,
    required this.technicienResponsableId,
    this.technicienIdsRenfort,
    required this.dateInterventionPrevue,
    required this.dureeEstimeeMinutes,
    this.priorite,
    this.description,
    this.visitePreventive = false,
    this.isEvaluation = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (demandeMaintenanceId != null) 'demandeMaintenanceId': demandeMaintenanceId,
      if (ascenseurId != null) 'ascenseurId': ascenseurId,
      if (parcId != null) 'parcId': parcId,
      if (siteId != null) 'siteId': siteId,
      'technicienResponsableId': technicienResponsableId,
      if (technicienIdsRenfort != null) 'technicienIdsRenfort': technicienIdsRenfort,
      'dateInterventionPrevue': dateInterventionPrevue.toIso8601String(),
      'dureeEstimeeMinutes': dureeEstimeeMinutes,
      if (priorite != null) 'priorite': priorite,
      if (description != null) 'description': description,
      'visitePreventive': visitePreventive,
      'isEvaluation': isEvaluation, 
    };
  }
}
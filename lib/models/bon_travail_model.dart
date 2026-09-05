import 'package:flutter/material.dart';
import 'piece_jointe_model.dart';

enum StatutBonTravail { PLANIFIE, EN_COURS, TERMINE, ANNULE }
enum PrioriteDemande { CRITIQUE, URGENTE, NORMALE, FAIBLE }

class BonTravailModel {
  final int id;
  final StatutBonTravail statut;
  final PrioriteDemande priorite;
  final DateTime dateInterventionPrevue;
  final int dureeEstimeeMinutes;
  final String description;
  final DateTime? dateDebutReelle;
  final DateTime? dateFinReelle;
  final String? diagnostic;
  final String? causeIdentifiee;
  final String? actionRealisee;
  final String? piecesRemplacees;
  final bool? essaiConcluant;
  final String? recommandations;
  final int? demandeMaintenanceId;
  final int? ascenseurId;
  final String? ascenseurNom;
  final String? siteAdresse;
  final int? parcId;
  final String? parcNom;
  final int? technicienResponsableId;
  final String? technicienResponsableNom;
  final List<Map<String, dynamic>> techniciens;
  final List<PieceJointeModel> photosDemande;
  final List<PieceJointeModel> piecesJointesBonTravail;
  final String? createdAt;

  const BonTravailModel({
    required this.id,
    required this.statut,
    required this.priorite,
    required this.dateInterventionPrevue,
    required this.dureeEstimeeMinutes,
    required this.description,
    this.dateDebutReelle,
    this.dateFinReelle,
    this.diagnostic,
    this.causeIdentifiee,
    this.actionRealisee,
    this.piecesRemplacees,
    this.essaiConcluant,
    this.recommandations,
    this.demandeMaintenanceId,
    this.ascenseurId,
    this.ascenseurNom,
    this.siteAdresse,
    this.parcId,
    this.parcNom,
    this.technicienResponsableId,
    this.technicienResponsableNom,
    this.techniciens = const [],
    this.photosDemande = const [],
    this.piecesJointesBonTravail = const [],
    this.createdAt,
  });

  factory BonTravailModel.fromJson(Map<String, dynamic> json) {
    

    return BonTravailModel(
      id: json['id']?.toInt() ?? 0,
      
      statut: StatutBonTravail.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => StatutBonTravail.PLANIFIE,
      ),
      
      priorite: PrioriteDemande.values.firstWhere(
        (e) => e.name == json['priorite'],
        orElse: () => PrioriteDemande.NORMALE,
      ),
      
      dateInterventionPrevue: json['dateInterventionPrevue'] != null && json['dateInterventionPrevue'] != 'null'
          ? DateTime.parse(json['dateInterventionPrevue'].toString())
          : DateTime.now(),
      
      dureeEstimeeMinutes: (json['dureeEstimeeMinutes'] is int) 
          ? json['dureeEstimeeMinutes'] 
          : (json['dureeEstimeeMinutes']?.toString().isNotEmpty == true ? int.tryParse(json['dureeEstimeeMinutes'].toString()) ?? 0 : 0),
      
      description: json['description']?.toString().isNotEmpty == true ? json['description'].toString() : 'Aucune description',
      
      dateDebutReelle: json['dateDebutReelle'] != null && json['dateDebutReelle'] != 'null' ? DateTime.parse(json['dateDebutReelle'].toString()) : null,
      dateFinReelle: json['dateFinReelle'] != null && json['dateFinReelle'] != 'null' ? DateTime.parse(json['dateFinReelle'].toString()) : null,
      
      diagnostic: json['diagnostic']?.toString(),
      causeIdentifiee: json['causeIdentifiee']?.toString(),
      actionRealisee: json['actionRealisee']?.toString(),
      piecesRemplacees: json['piecesRemplacees']?.toString(),
      essaiConcluant: json['essaiConcluant'] as bool?,
      recommandations: json['recommandations']?.toString(),
      demandeMaintenanceId: json['demandeMaintenanceId']?.toInt(),
      ascenseurId: json['ascenseurId']?.toInt(),
      ascenseurNom: json['ascenseurNom']?.toString(),
      siteAdresse: json['siteAdresse']?.toString(),
      parcId: json['parcId']?.toInt(),
      parcNom: json['parcNom']?.toString(),
      technicienResponsableId: json['technicienResponsableId']?.toInt(),
      technicienResponsableNom: json['technicienResponsableNom']?.toString(),
      techniciens: (json['techniciens'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      photosDemande: (json['photosDemande'] as List?)?.map((p) => PieceJointeModel.fromJson(p)).toList() ?? [],
      piecesJointesBonTravail: (json['piecesJointesBonTravail'] as List?)?.map((p) => PieceJointeModel.fromJson(p)).toList() ?? [],
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get statutLabel {
    switch (statut) {
      case StatutBonTravail.PLANIFIE: return 'Planifié';
      case StatutBonTravail.EN_COURS: return 'En cours';
      case StatutBonTravail.TERMINE: return 'Terminé';
      case StatutBonTravail.ANNULE: return 'Annulé';
    }
  }

  Color get statutColor {
    switch (statut) {
      case StatutBonTravail.PLANIFIE: return Colors.blue;
      case StatutBonTravail.EN_COURS: return Colors.orange;
      case StatutBonTravail.TERMINE: return Colors.green;
      case StatutBonTravail.ANNULE: return Colors.grey;
    }
  }
}
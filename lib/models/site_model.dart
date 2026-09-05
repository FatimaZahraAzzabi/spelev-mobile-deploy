import 'ville_model.dart';
import 'utilisateur_model.dart';
import 'parc_model.dart';

class SiteModel {
  final int id;
  final String adresse;
  final String? codePostal;
  final VilleModel? ville;
  final UtilisateurModel? client;
  final ParcModel? parc;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SiteModel({
    required this.id,
    required this.adresse,
    this.codePostal,
    this.ville,
    this.client,
    this.parc,
    this.createdAt,
    this.updatedAt,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    // Gestion du Client (données à plat venant du backend)
    UtilisateurModel? clientObj;
    if (json['client'] != null && json['client'] is Map) {
      clientObj = UtilisateurModel.fromJson(json['client']);
    } else if (json['clientNom'] != null) {
      clientObj = UtilisateurModel(
        id: json['clientId'] ?? 0,
        nom: json['clientNom'] ?? 'Inconnu',
        prenom: json['clientPrenom'] ?? '', 
        email: json['clientEmail'] ?? '',
        telephone: json['clientTelephone'] ?? '',
        nomEntreprise: json['clientNomEntreprise'] ?? '',
        type: json['clientType'] ?? 'CLIENT',
      );
    }

    // Gestion du Parc
    ParcModel? parcObj;
    if (json['parc'] != null && json['parc'] is Map) {
      parcObj = ParcModel.fromJson(json['parc']);
    } else if (json['parcNom'] != null) {
      parcObj = ParcModel(
        id: json['parcId'] ?? 0,
        nom: json['parcNom'] ?? 'Non assigné',
      );
    }

    // Gestion de la Ville
    VilleModel? villeObj;
    if (json['ville'] != null && json['ville'] is Map) {
      villeObj = VilleModel.fromJson(json['ville']);
    } else if (json['villeNom'] != null) {
      villeObj = VilleModel(
        id: json['villeId'] ?? 0,
        nom: json['villeNom'] ?? 'Inconnue',
      );
    }

    return SiteModel(
      id: json['id'] ?? 0,
      adresse: json['adresse'] ?? '',
      codePostal: json['codePostal'] ?? json['villeCodePostal'],
      ville: villeObj,
      client: clientObj,
      parc: parcObj,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}
class ComposantModel {
  final int id;
  final String nom;
  final String reference;
  final String type;
  final String? fabricant;
  final String? imageUrl;
  final String? dateInstallation;
  final int? dureeVieEstimeeMois;
  final bool actif;
  final int assemblageId;
  final String? assemblageNom;

  ComposantModel({
    required this.id,
    required this.nom,
    required this.reference,
    required this.type,
    this.fabricant,
    this.imageUrl,
    this.dateInstallation,
    this.dureeVieEstimeeMois,
    required this.actif,
    required this.assemblageId,
    this.assemblageNom,
  });

  factory ComposantModel.fromJson(Map<String, dynamic> json) {
    return ComposantModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Inconnu',
      reference: json['reference'] ?? '',
      type: json['type'] ?? '',
      fabricant: json['fabricant'],
      imageUrl: json['imageUrl'],
      dateInstallation: json['dateInstallation'],
      dureeVieEstimeeMois: json['dureeVieEstimeeMois'],
      actif: json['actif'] ?? true,
      assemblageId: json['assemblageId'] ?? 0,
      assemblageNom: json['assemblageNom'],
    );
  }
}
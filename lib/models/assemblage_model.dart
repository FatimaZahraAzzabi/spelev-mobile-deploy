import 'composant_model.dart';

class AssemblageModel {
  final int id;
  final String nom;
  final String reference;
  final String type;
  final String? fabricant;
  final String? dateInstallation; 
  final int? dureeVieEstimeeMois;
  final String? description;
  final String? imageUrl;
  final int? niveau;
  final int? ascenseurId;
  final int? parentId;
  final String? parentNom;
  
  // Pour l'arbre
  final List<AssemblageModel>? sousAssemblages;
  final List<ComposantModel>? composants;

  AssemblageModel({
    required this.id,
    required this.nom,
    required this.reference,
    required this.type,
    this.fabricant,
    this.dateInstallation,
    this.dureeVieEstimeeMois,
    this.description,
    this.imageUrl,
    this.niveau,
    this.ascenseurId,
    this.parentId,
    this.parentNom,
    this.sousAssemblages,
    this.composants,
  });

  factory AssemblageModel.fromJson(Map<String, dynamic> json) {
    return AssemblageModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Inconnu',
      reference: json['reference'] ?? '',
      type: json['type'] ?? '',
      fabricant: json['fabricant'],
      dateInstallation: json['dateInstallation'],
      dureeVieEstimeeMois: json['dureeVieEstimeeMois'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      niveau: json['niveau'],
      ascenseurId: json['ascenseurId'],
      parentId: json['parentId'],
      parentNom: json['parentNom'],
      sousAssemblages: json['sousAssemblages'] != null
          ? (json['sousAssemblages'] as List).map((e) => AssemblageModel.fromJson(e)).toList()
          : null,
      composants: json['composants'] != null
          ? (json['composants'] as List).map((e) => ComposantModel.fromJson(e)).toList()
          : null,
    );
  }
}
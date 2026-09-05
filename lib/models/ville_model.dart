class VilleModel {
  final int id;
  final String nom;
  final String? codePostal;

  VilleModel({required this.id, required this.nom, this.codePostal});

  factory VilleModel.fromJson(Map<String, dynamic> json) {
    return VilleModel(
      id: json['id'],
      nom: json['nom'] ?? 'Inconnu',
      codePostal: json['codePostal'],
    );
  }
}
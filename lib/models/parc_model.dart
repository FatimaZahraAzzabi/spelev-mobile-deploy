class ParcModel {
  final int id;
  final String nom;

  ParcModel({required this.id, required this.nom});

  factory ParcModel.fromJson(Map<String, dynamic> json) {
    return ParcModel(
      id: json['id'],
      nom: json['nom'] ?? 'Nom inconnu',
    );
  }
}
class CommentaireModel {
  final int id;
  final int auteurId;
  final String auteurNom;
  final String auteurRole;
  final String contenu;
  final DateTime createdAt;

  const CommentaireModel({
    required this.id,
    required this.auteurId,
    required this.auteurNom,
    required this.auteurRole,
    required this.contenu,
    required this.createdAt,
  });

  factory CommentaireModel.fromJson(Map<String, dynamic> json) {
    return CommentaireModel(
      id: json['id'] as int,
      auteurId: json['auteurId'] as int,
      auteurNom: json['auteurNom'] as String? ?? '',
      auteurRole: json['auteurRole'] as String? ?? '',
      contenu: json['contenu'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
class ProfilModel {
  final int? id;
  final String? email;
  final String? nom;
  final String? prenom;
  final String? role;
  final String? telephone;
  final String? nomEntreprise;
  final String? adresse;
  final String? specialite; 
  final bool? actif;
  final String? photoUrl;
  final DateTime? createdAt;

  String get nomComplet => '${prenom ?? ''} ${nom ?? ''}'.trim();
  
  String? get entreprise => nomEntreprise;

  ProfilModel({
    this.id,
    this.email,
    this.nom,
    this.prenom,
    this.role,
    this.telephone,
    this.nomEntreprise,
    this.adresse,
    this.specialite, 
    this.actif,
    this.photoUrl,
    this.createdAt,
  });

  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      id: json['id'],
      email: json['email'],
      nom: json['nom'],
      prenom: json['prenom'],
      role: json['role'],
      telephone: json['telephone'],
      nomEntreprise: json['nomEntreprise'],
      adresse: json['adresse'],
      specialite: json['specialite'], 
      actif: json['actif'],
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
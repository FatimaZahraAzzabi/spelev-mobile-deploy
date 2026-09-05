class UtilisateurModel {
  final int id;
  final String email;
  final String telephone;
  final String motDePasse;
  final String nom;
  final String prenom;
  final String nomEntreprise;
  final bool actif;
  final String type;
  final String? specialite;
  final bool? disponible;
  final String? adresse;
  final List<int>? parcIds;
  final String? photoUrl; 

  UtilisateurModel({
    required this.id,
    required this.email,
    required this.telephone,
    this.motDePasse = '',
    required this.nom,
    required this.prenom,
    this.nomEntreprise = '',
    this.actif = true,
    required this.type,
    this.specialite,
    this.disponible,
    this.adresse,
    this.parcIds,
    this.photoUrl, 
  });

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) {
    return UtilisateurModel(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      nomEntreprise: json['nomEntreprise'] as String? ?? '',
      actif: json['actif'] as bool? ?? true,
      type: json['type'] as String? ?? 'CLIENT',
      specialite: json['specialite'] as String?,
      disponible: json['disponible'] as bool?,
      adresse: json['adresse'] as String?,
      parcIds: (json['parcIds'] as List?)?.map((e) => e as int).toList(),
      photoUrl: json['photoUrl'] as String?, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'telephone': telephone,
      'nom': nom,
      'prenom': prenom,
      'nomEntreprise': nomEntreprise,
      'actif': actif,
      'type': type,
      'specialite': specialite,
      'disponible': disponible,
      'adresse': adresse,
      'parcIds': parcIds,
      'photoUrl': photoUrl,
    };
  }
}

// DTO pour la création d'un utilisateur
class UtilisateurCreateDTO {
  final String email;
  final String telephone;
  final String motDePasse;
  final String nom;
  final String prenom;
  final String type;
  final String? nomEntreprise;
  final String? specialite;
  final String? adresse;
  final List<int>? parcIds;

  UtilisateurCreateDTO({
    required this.email,
    required this.telephone,
    required this.motDePasse,
    required this.nom,
    required this.prenom,
    required this.type,
    this.nomEntreprise,
    this.specialite,
    this.adresse,
    this.parcIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'telephone': telephone,
      'motDePasse': motDePasse,
      'nom': nom,
      'prenom': prenom,
      'type': type,
      'nomEntreprise': nomEntreprise,
      'specialite': specialite,
      'adresse': adresse,
      'parcIds': parcIds,
    };
  }
}

// DTO pour la modification
class UtilisateurUpdateDTO {
  final String email;
  final String telephone;
  final String nom;
  final String prenom;
  final String type;
  final bool actif;
  final String? nomEntreprise;
  final String? specialite;
  final String? adresse;
  final List<int>? parcIds;

  UtilisateurUpdateDTO({
    required this.email,
    required this.telephone,
    required this.nom,
    required this.prenom,
    required this.type,
    required this.actif,
    this.nomEntreprise,
    this.specialite,
    this.adresse,
    this.parcIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'telephone': telephone,
      'nom': nom,
      'prenom': prenom,
      'type': type,
      'actif': actif,
      'nomEntreprise': nomEntreprise,
      'specialite': specialite,
      'adresse': adresse,
      'parcIds': parcIds,
    };
  }
}
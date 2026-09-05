import 'piece_jointe_model.dart';

class DemandeMaintenanceModel {
  final int id;
  final String typeDemande;
  final String priorite;
  final String statut;
  final String description;
  final String? dateSouhaitee;
  final String? motifRejet;

  // Peut être null pour une demande d'évaluation
  final int? ascenseurId;
  final String? ascenseurNom;

  // Adresse saisie directement lors d'une demande d'évaluation
  final String? villeSaisie;
  final String? adresseSaisie;

  // Informations du client
  final int? clientId;
  final String? clientNom;
  final String? clientPrenom;
  final String? clientEmail;
  final String? clientNomEntreprise;

  final String? createdAt;
  final List<PieceJointeModel> photos;

  const DemandeMaintenanceModel({
    required this.id,
    required this.typeDemande,
    required this.priorite,
    required this.statut,
    required this.description,
    this.dateSouhaitee,
    this.motifRejet,
    this.ascenseurId,
    this.ascenseurNom,
    this.villeSaisie,
    this.adresseSaisie,
    this.clientId,
    this.clientNom,
    this.clientPrenom,
    this.clientEmail,
    this.clientNomEntreprise,
    this.createdAt,
    this.photos = const [],
  });

  /// Nom complet du client
  String get clientNomComplet {
    final nom =
        '${clientPrenom ?? ''} ${clientNom ?? ''}'.trim();

    if (nom.isEmpty) {
      return clientNomEntreprise ?? 'Client inconnu';
    }

    if (clientNomEntreprise != null &&
        clientNomEntreprise!.isNotEmpty) {
      return '$nom ($clientNomEntreprise)';
    }

    return nom;
  }

  factory DemandeMaintenanceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    // ============================
    // PHOTOS / PIÈCES JOINTES
    // ============================

    List<PieceJointeModel> photosList = [];

    final photosData =
        json['photos'] ??
        json['piecesJointes'] ??
        json['attachments'];

    if (photosData is List) {
      photosList = photosData
          .where((e) => e is Map)
          .map(
            (e) => PieceJointeModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    // ============================
    // ASCENSEUR
    // Facultatif pour les évaluations
    // ============================

    int? ascId;

    if (json['ascenseurId'] != null) {
      ascId =
          (json['ascenseurId'] as num?)?.toInt();
    }

    String? ascNom =
        json['ascenseurNom']?.toString();

    // Si le backend retourne :
    // "ascenseur": { "id": 1, "nom": "Ascenseur A" }

    if (json['ascenseur'] is Map) {
      final asc =
          Map<String, dynamic>.from(
        json['ascenseur'],
      );

      ascId ??=
          (asc['id'] as num?)?.toInt();

      ascNom ??=
          asc['nom']?.toString();
    }

    // ============================
    // CLIENT
    // ============================

    int? clientId =
        (json['clientId'] as num?)?.toInt();

    String? clientNom =
        json['clientNom']?.toString();

    String? clientPrenom =
        json['clientPrenom']?.toString();

    String? clientEmail =
        json['clientEmail']?.toString();

    String? clientNomEntreprise =
        json['clientNomEntreprise']?.toString();

    // Si le backend retourne :
    // "client": { ... }

    if (json['client'] is Map) {
      final client =
          Map<String, dynamic>.from(
        json['client'],
      );

      clientId ??=
          (client['id'] as num?)?.toInt();

      clientNom ??=
          client['nom']?.toString();

      clientPrenom ??=
          client['prenom']?.toString();

      clientEmail ??=
          client['email']?.toString();

      clientNomEntreprise ??=
          client['nomEntreprise']?.toString();
    }

    // ============================
    // CRÉATION DU MODÈLE
    // ============================

    return DemandeMaintenanceModel(
      id: (json['id'] as num?)?.toInt() ?? 0,

      typeDemande:
          json['typeDemande']?.toString() ??
              'AUTRE',

      priorite:
          json['priorite']?.toString() ??
              'NORMALE',

      statut:
          json['statut']?.toString() ??
              'EN_ATTENTE',

      description:
          json['description']?.toString() ?? '',

      dateSouhaitee:
          json['dateSouhaitee']?.toString(),

      motifRejet:
          json['motifRejet']?.toString(),

      // Peut être null pour une évaluation
      ascenseurId: ascId,

      ascenseurNom: ascNom,

      villeSaisie:
          json['villeSaisie']?.toString(),

      adresseSaisie:
          json['adresseSaisie']?.toString(),

      clientId: clientId,

      clientNom: clientNom,

      clientPrenom: clientPrenom,

      clientEmail: clientEmail,

      clientNomEntreprise:
          clientNomEntreprise,

      createdAt:
          json['createdAt']?.toString(),

      photos: photosList,
    );
  }

  /// Vérifie si la demande concerne une évaluation
  bool get isEvaluation {
    return typeDemande == 'EVALUATION' ||
        typeDemande == 'EVALUATION_NOUVELLE_INSTALLATION';
  }

  /// Vérifie si un ascenseur est associé
  bool get hasAscenseur {
    return ascenseurId != null;
  }

  /// Adresse complète saisie pour une nouvelle installation
  String get adresseComplete {
    final parts = <String>[];

    if (adresseSaisie != null &&
        adresseSaisie!.trim().isNotEmpty) {
      parts.add(adresseSaisie!.trim());
    }

    if (villeSaisie != null &&
        villeSaisie!.trim().isNotEmpty) {
      parts.add(villeSaisie!.trim());
    }

    return parts.isEmpty
        ? 'Adresse non définie'
        : parts.join(', ');
  }
}
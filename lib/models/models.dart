enum StatutAscenseur { actif, enMaintenance, horsService }

class Ascenseur {
  final int id;
  final String nom;
  final String fabricant;
  final String numeroSerie;
  final int nombreEtages;
  final String clientNom;
  final String site;
  final StatutAscenseur statut;

  Ascenseur({
    required this.id,
    required this.nom,
    required this.fabricant,
    required this.numeroSerie,
    required this.nombreEtages,
    required this.clientNom,
    required this.site,
    required this.statut,
  });
}

class Assemblage {
  final int id;
  final String nom;
  final int niveau;
  final List<Composant> composants;
  final List<Assemblage> sousAssemblages;

  Assemblage({
    required this.id,
    required this.nom,
    required this.niveau,
    this.composants = const [],
    this.sousAssemblages = const [],
  });
}

class Composant {
  final int id;
  final String nom;
  final String reference;
  final String type;
  final bool actif;

  Composant({
    required this.id,
    required this.nom,
    required this.reference,
    required this.type,
    this.actif = true,
  });
}
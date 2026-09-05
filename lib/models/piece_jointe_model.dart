import '../config/api_config.dart';

class PieceJointeModel {
  final int? id;
  final String nomFichier;
  final String url;
  final String? typeFichier;
  final String? description;

  const PieceJointeModel({
    this.id,
    required this.nomFichier,
    required this.url,
    this.typeFichier,
    this.description,
  });

  factory PieceJointeModel.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];

    String url = '';
    if (idVal != null) {
      url = '${ApiConfig.baseUrl}/api/fichiers/$idVal';
    } else {
      url = (json['url'] ?? '').toString();
    }

    return PieceJointeModel(
      id: idVal,
      nomFichier: json['nomFichier'] ?? 'fichier',
      url: url,
      typeFichier: json['typeFichier']?.toString(),
      description: json['description'],
    );
  }

  bool get estImage {
    final type = (typeFichier ?? '').toUpperCase();
    if (type == 'IMAGE') return true;
    final nom = nomFichier.toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'].any((e) => nom.endsWith(e));
  }

  bool get estAudio {
    final type = (typeFichier ?? '').toUpperCase();
    if (type == 'AUDIO') return true;
    final nom = nomFichier.toLowerCase();
    return ['.m4a', '.mp3', '.aac', '.wav', '.ogg', '.opus', '.webm'].any((e) => nom.endsWith(e));
  }
}
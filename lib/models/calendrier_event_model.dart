import 'package:flutter/material.dart';

class CalendrierEventModel {
  final String id;
  final String titre;
  final String source; 
  final String type;
  final DateTime debut;
  final DateTime fin;
  final String? lieu;
  final List<int> technicienIds;
  final List<String> technicienNoms;
  final String couleur; 

  const CalendrierEventModel({
    required this.id,
    required this.titre,
    required this.source,
    required this.type,
    required this.debut,
    required this.fin,
    this.lieu,
    required this.technicienIds,
    required this.technicienNoms,
    required this.couleur,
  });

  factory CalendrierEventModel.fromJson(Map<String, dynamic> json) {
    return CalendrierEventModel(
      id: json['id'] as String,
      titre: json['titre'] as String,
      source: json['source'] as String,
      type: json['type'] as String,
      debut: DateTime.parse(json['debut'] as String),
      fin: DateTime.parse(json['fin'] as String),
      lieu: json['lieu'] as String?,
      technicienIds: (json['technicienIds'] as List?)?.map((e) => e as int).toList() ?? [],
      technicienNoms: (json['technicienNoms'] as List?)?.map((e) => e as String).toList() ?? [],
      couleur: json['couleur'] as String,
    );
  }

  Color get color {
    String hex = couleur.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    }
    return Colors.grey; // Fallback
  }
}
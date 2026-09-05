import 'package:flutter/material.dart';

class StatutBadge extends StatelessWidget {
  final String statut;
  const StatutBadge({super.key, required this.statut});

  static Color _color(String s) {
    switch (s) {
      case 'EN_ATTENTE': return Colors.amber;
      case 'ASSIGNEE': return Colors.indigo;
      case 'EN_COURS': return Colors.orange;
      case 'RESOLUE': return Colors.green;
      case 'ANNULEE': return Colors.grey;
      case 'REJETEE': return Colors.red;
      default: return Colors.blue;
    }
  }

  static String _label(String s) {
    switch (s) {
      case 'EN_ATTENTE': return 'En attente';
      case 'ASSIGNEE': return 'Assignée';
      case 'EN_COURS': return 'En cours';
      case 'RESOLUE': return 'Résolue';
      case 'ANNULEE': return 'Annulée';
      case 'REJETEE': return 'Rejetée';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(_label(statut), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class PrioriteBadge extends StatelessWidget {
  final String priorite;
  const PrioriteBadge({super.key, required this.priorite});

  static Color _color(String p) {
    switch (p) {
      case 'URGENTE': return Colors.red;
      case 'NORMALE': return Colors.blue;
      case 'BASSE': return Colors.green;
      default: return Colors.grey;
    }
  }

  static String _label(String p) {
    switch (p) {
      case 'URGENTE': return 'Urgente';
      case 'NORMALE': return 'Normale';
      case 'BASSE': return 'Basse';
      default: return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(priorite);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(_label(priorite), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

String labelTypeDemande(String t) {
  switch (t) {
    case 'PANNE': return 'Panne';
    case 'ENTRETIEN_PREVENTIF': return 'Entretien préventif';
    case 'BRUIT_ANORMAL': return 'Bruit anormal';
    case 'AUTRE': return 'Autre';
    default: return t;
  }
}

String formatDateFr(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }
}
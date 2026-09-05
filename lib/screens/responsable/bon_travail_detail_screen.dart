import 'package:flutter/material.dart';
import '../../models/bon_travail_model.dart';
import '../../services/bon_travail_service.dart';
import '../../theme/app_theme.dart';
import 'responsable_drawer.dart';
import '../../widgets/messagerie_interne_widget.dart';

class BonTravailDetailScreen extends StatefulWidget {
  final int bonId;

  const BonTravailDetailScreen({super.key, required this.bonId});

  @override
  State<BonTravailDetailScreen> createState() => _BonTravailDetailScreenState();
}

class _BonTravailDetailScreenState extends State<BonTravailDetailScreen> {
  final _service = BonTravailService();
  BonTravailModel? _bon;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDetails();
  }

  Future<void> _chargerDetails() async {
    try {
      final detail = await _service.getDetail(widget.bonId);
      setState(() {
        _bon = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatutColor(StatutBonTravail statut) {
    switch (statut) {
      case StatutBonTravail.PLANIFIE: return Colors.blue;
      case StatutBonTravail.EN_COURS: return Colors.orange;
      case StatutBonTravail.TERMINE: return Colors.green;
      case StatutBonTravail.ANNULE: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _bon == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }

    final b = _bon!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-bons-travail'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Bon de travail N° ${b.id}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatutColor(b.statut).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              b.statutLabel,
              style: TextStyle(
                color: _getStatutColor(b.statut),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INFORMATIONS GÉNÉRALES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    _infoRow(Icons.assignment, 'Bon de travail', 'N° ${b.id}'),
                    _infoRow(Icons.elevator, 'Ascenseur', b.ascenseurNom ?? 'Non défini'),
                    _infoRow(Icons.location_on, 'Site', b.siteAdresse ?? 'Non défini'),
                    _infoRow(Icons.person, 'Technicien responsable', b.technicienResponsableNom ?? 'Non assigné'),
                    _infoRow(Icons.calendar_today, 'Date prévue', _formatDate(b.dateInterventionPrevue)),
                    _infoRow(Icons.timer, 'Durée estimée', '${b.dureeEstimeeMinutes} minutes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESCRIPTION',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    Text(b.description.isEmpty ? 'Aucune description' : b.description,
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                  ],
                ),
              ),
            ),
            if (b.diagnostic != null || b.actionRealisee != null) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RAPPORT D\'INTERVENTION',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      if (b.diagnostic != null) _infoRow(Icons.medical_services, 'Diagnostic', b.diagnostic!),
                      if (b.causeIdentifiee != null) _infoRow(Icons.search, 'Cause identifiée', b.causeIdentifiee!),
                      if (b.actionRealisee != null) _infoRow(Icons.build, 'Action réalisée', b.actionRealisee!),
                      if (b.piecesRemplacees != null) _infoRow(Icons.inventory, 'Pièces remplacées', b.piecesRemplacees!),
                      if (b.recommandations != null) _infoRow(Icons.lightbulb, 'Recommandations', b.recommandations!),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            MessagerieInterneWidget(bonTravailId: b.id),
            const SizedBox(height: 16),
            
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
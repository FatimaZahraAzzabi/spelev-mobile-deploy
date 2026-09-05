import 'package:flutter/material.dart';
import '../../services/rapport_service.dart';
import '../../models/rapport_model.dart';
import '../../config/api_config.dart'; // ✅ Assure-toi que cet import est présent
import '../../theme/app_theme.dart';
import 'responsable_drawer.dart';

class RapportDetailScreen extends StatefulWidget {
  final int rapportId;
  const RapportDetailScreen({super.key, required this.rapportId});

  @override
  State<RapportDetailScreen> createState() => _RapportDetailScreenState();
}

class _RapportDetailScreenState extends State<RapportDetailScreen> {
  final _service = RapportService();
  RapportModel? _rapport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _service.getRapportDetail(widget.rapportId);
      setState(() {
        _rapport = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _rapport == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    final r = _rapport!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-demandes-rapports'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Détail du rapport - ${r.ascenseurNom}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'INFORMATIONS GÉNÉRALES',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.elevator, 'Ascenseur', r.ascenseurNom),
                  _infoRow(Icons.calendar_today, 'Période', '${_getMonthName(r.mois)}/${r.annee}'),
                  _infoRow(Icons.person, 'Technicien', r.technicienNom ?? 'Non assigné'),
                  _infoRow(Icons.access_time, 'Horaires', '${r.heureArrivee ?? 'N/A'} - ${r.heureDepart ?? 'N/A'}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (r.bilanIntervention != null && r.bilanIntervention!.isNotEmpty) ...[
              _buildSectionCard(
                title: 'BILAN DE L\'INTERVENTION',
                child: Text(
                  r.bilanIntervention!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildSectionCard(
              title: 'CHECKLIST DÉTAILLÉE',
              child: Column(
                children: r.items.asMap().entries.map((entry) {
                  return _buildItemCard(entry.key + 1, entry.value);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rapport validé avec succès'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 20),
                label: const Text('VALIDER CE RAPPORT', style: TextStyle(letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
            ),
            const Divider(height: 24, color: Colors.grey),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, ItemRapportModel item) {
    final isConforme = item.statut == StatutItemRapport.CONFORME;
    final isAnomalie = item.statut == StatutItemRapport.ANOMALIE_DETECTEE;
    final hasPhotos = item.piecesJointes.isNotEmpty;
    final hasRemark = item.remarque != null && item.remarque!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.libelle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isConforme ? Colors.green.shade50 : (isAnomalie ? Colors.red.shade50 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isConforme ? Colors.green.shade200 : (isAnomalie ? Colors.red.shade200 : Colors.grey.shade300),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatutLabel(item.statut).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isConforme ? Colors.green.shade800 : (isAnomalie ? Colors.red.shade800 : Colors.grey.shade700),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          if (isAnomalie && item.gravite != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Gravité : ${_getGraviteLabel(item.gravite!).toUpperCase()}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                  ),
                ],
              ),
            ),
          ],

          if (hasRemark) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.remarque!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
                    if (hasPhotos) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.piecesJointes.map((photo) {
                  final imageUrl = ApiConfig.fixMinioUrl(photo.url);
                  
                  return Container(
                    width: 120, // Élargi pour voir le texte
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300, width: 1),
                      color: Colors.red.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ AFFICHE L'URL EN TEXTE POUR DÉBOGAGE
                        Text(
                          'URL Reçue: ${photo.url ?? "NULL"}',
                          style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'URL Corrigée: ${imageUrl.isEmpty ? "VIDE" : imageUrl}',
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        // On garde l'image si l'URL n'est pas vide
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              imageUrl,
                              height: 60,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 24));
                              },
                            ),
                          )
                        else
                          const Center(
                            child: Text('URL VIDE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatutLabel(StatutItemRapport statut) {
    switch (statut) {
      case StatutItemRapport.NON_VERIFIE: return 'Non vérifié';
      case StatutItemRapport.CONFORME: return 'Conforme';
      case StatutItemRapport.ANOMALIE_DETECTEE: return 'Anomalie';
    }
  }

  String _getGraviteLabel(GraviteAnomalieRapport gravite) {
    switch (gravite) {
      case GraviteAnomalieRapport.MINEURE: return 'Mineure';
      case GraviteAnomalieRapport.MAJEURE: return 'Majeure';
      case GraviteAnomalieRapport.CRITIQUE: return 'Critique';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }
}
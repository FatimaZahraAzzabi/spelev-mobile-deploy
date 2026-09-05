import 'package:flutter/material.dart';
import '../../services/rapport_service.dart';
import '../../models/rapport_model.dart';
import '../../theme/app_theme.dart';
import 'responsable_drawer.dart';
import 'rapport_detail_screen.dart';

class RapportsAValiderScreen extends StatefulWidget {
  const RapportsAValiderScreen({super.key});

  @override
  State<RapportsAValiderScreen> createState() => _RapportsAValiderScreenState();
}

class _RapportsAValiderScreenState extends State<RapportsAValiderScreen> {
  final _service = RapportService();
  List<RapportModel> _rapports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRapports();
  }

  Future<void> _loadRapports() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getRapportsAValider();
      setState(() {
        _rapports = data;
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-demandes-rapports'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Rapports à valider',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _loadRapports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _rapports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun rapport en attente de validation',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRapports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rapports.length,
                    itemBuilder: (context, index) {
                      return _buildRapportCard(_rapports[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildRapportCard(RapportModel rapport) {
    final hasPhotos = rapport.items.any((item) => item.piecesJointes.isNotEmpty);
    final hasRemarks = rapport.items.any((item) => item.remarque != null && item.remarque!.isNotEmpty);
    final hasAnomalies = rapport.items.any((item) => item.statut == StatutItemRapport.ANOMALIE_DETECTEE);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.orange,
                  radius: 24,
                  child: Text(
                    rapport.mois.toString().padLeft(2, '0'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rapport.ascenseurNom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${_getMonthName(rapport.mois)}/${rapport.annee}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasAnomalies ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasAnomalies ? 'Avec anomalies' : 'Conforme',
                    style: TextStyle(
                      color: hasAnomalies ? Colors.orange[800] : Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasPhotos)
                  _buildBadge(Icons.photo_library, 'Photos', Colors.blue),
                if (hasRemarks)
                  _buildBadge(Icons.note, 'Remarques', Colors.purple),
                _buildBadge(Icons.checklist, '${rapport.items.length} items', Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  rapport.technicienNom ?? 'Non assigné',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  rapport.heureDepart ?? 'N/A',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RapportDetailScreen(rapportId: rapport.id),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Voir le rapport'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color[700])),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }
}
import 'package:flutter/material.dart';
import 'responsable_drawer.dart';
import '../../services/statistique_service.dart'; 
import '../../widgets/notification_bell_widget.dart';

class ResponsableDashboardScreen extends StatefulWidget {
  const ResponsableDashboardScreen({super.key});

  @override
  State<ResponsableDashboardScreen> createState() => _ResponsableDashboardScreenState();
}

class _ResponsableDashboardScreenState extends State<ResponsableDashboardScreen> {
  final _statService = StatistiqueService();
  bool _isLoading = true;
  
  int _interventionsEnCours = 0;
  int _techniciensDisponibles = 0;
  int _urgencesSignalees = 0;
  int _sitesActifs = 0;

  @override
  void initState() {
    super.initState();
    _chargerStatistiques();
  }

  Future<void> _chargerStatistiques() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _statService.getStatistiquesResponsable();
      setState(() {
        _interventionsEnCours = stats['interventionsEnCours'] ?? 0;
        _techniciensDisponibles = stats['techniciensDisponibles'] ?? 0;
        _urgencesSignalees = stats['urgencesSignalees'] ?? 0;
        _sitesActifs = stats['sitesActifs'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement stats: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color navyColor = Colors.blue[900]!; 
    final Color orangeColor = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-dashboard'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de bord',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Vue d\'ensemble de la maintenance',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          const NotificationBellWidget(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _chargerStatistiques,
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, Responsable 👋',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navyColor),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Voici un résumé de l\'activité de vos équipes aujourd\'hui.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95, 
                    children: [
                      _buildStatCard('Interventions en cours', '$_interventionsEnCours', Colors.orange, Icons.build_circle),
                      _buildStatCard('Techniciens disponibles', '$_techniciensDisponibles', Colors.green, Icons.engineering),
                      _buildStatCard('Urgences signalées', '$_urgencesSignalees', Colors.redAccent, Icons.error_outline),
                      _buildStatCard('Sites actifs', '$_sitesActifs', navyColor, Icons.business),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // 3. Bouton d'action rapide
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/responsable-nouvelle-intervention');
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('Créer une nouvelle intervention', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // Widget réutilisable pour les cartes de statistiques
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
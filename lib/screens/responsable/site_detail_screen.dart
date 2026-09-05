import 'package:flutter/material.dart';
import '../../models/site_model.dart';
import '../../theme/app_theme.dart';

class SiteDetailScreen extends StatelessWidget {
  final SiteModel site;

  const SiteDetailScreen({super.key, required this.site});

  String get _clientName {
    if (site.client == null) return 'Non assigné';
    final prenom = (site.client!.prenom ?? '').trim();
    final nom = (site.client!.nom ?? '').trim();
    
    if (prenom.isNotEmpty && nom.isNotEmpty) return '$prenom $nom';
    if (nom.isNotEmpty) return nom;
    if (prenom.isNotEmpty) return prenom;
    return 'Non assigné';
  }

  String get _cityInfo {
    final ville = site.ville?.nom ?? 'Ville inconnue';
    final cp = site.codePostal?.trim() ?? '';
    return cp.isNotEmpty ? '$ville, $cp' : ville;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Détails du Site', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte principale (Adresse)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business, color: AppColors.navy, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.adresse,
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.black87
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _cityInfo, 
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations associées', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)
                    ),
                    const SizedBox(height: 16),
                    
                    _infoRow(Icons.person, 'Client', _clientName),
                    _infoRow(Icons.email, 'Email client', site.client?.email ?? 'Non renseigné'),
                    
                    const Divider(height: 24),
                    
                    _infoRow(Icons.category, 'Parc', site.parc?.nom ?? 'Non assigné'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Carte Dates
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Métadonnées', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)
                    ),
                    const SizedBox(height: 16),
                    _infoRow(Icons.calendar_today, 'Créé le', _formatDate(site.createdAt)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
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
                Text(
                  label, 
                  style: const TextStyle(fontSize: 12, color: Colors.black54)
                ),
                const SizedBox(height: 2),
                Text(
                  value, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non renseigné';
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import 'technicien_drawer.dart';
import '../../theme/app_theme.dart';
import '../../services/bon_travail_service.dart';
import '../../models/bon_travail_model.dart';
import '../../widgets/notification_bell_widget.dart';

class TechnicienDashboardScreen extends StatefulWidget {
  const TechnicienDashboardScreen({super.key});

  @override
  State<TechnicienDashboardScreen> createState() => _TechnicienDashboardScreenState();
}

class _TechnicienDashboardScreenState extends State<TechnicienDashboardScreen> {
  final _service = BonTravailService();
  List<BonTravailModel> _interventions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    setState(() => _isLoading = true);
    try {
      final interventions = await _service.getMesInterventions();
      
      debugPrint(' Nombre d\'interventions reçues : ${interventions.length}');
      for (var i in interventions) {
        debugPrint('   ➔ BT #${i.id} | Statut: ${i.statut.name} | Ascenseur: ${i.ascenseurNom}');
      }

      if (mounted) {
        setState(() {
          _interventions = interventions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int get _total => _interventions.length;
  int get _planifiees => _interventions.where((i) => i.statut == StatutBonTravail.PLANIFIE).length;
  int get _enCours => _interventions.where((i) => i.statut == StatutBonTravail.EN_COURS).length;
  int get _terminees => _interventions.where((i) => i.statut == StatutBonTravail.TERMINE).length;

  @override
  Widget build(BuildContext context) {
    final actives = _interventions.where((i) => 
      i.statut == StatutBonTravail.PLANIFIE || i.statut == StatutBonTravail.EN_COURS
    ).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const TechnicienDrawer(currentRoute: '/technicien-dashboard'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          const NotificationBellWidget(), 
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _loadInterventions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bonjour, Technicien 👋',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Voici le résumé de vos interventions.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Statistiques
                  Row(
                    children: [
                      _buildStatCard('Total', '$_total', Colors.blue, Icons.task),
                      const SizedBox(width: 12),
                      _buildStatCard('Planifiées', '$_planifiees', Colors.indigo, Icons.calendar_today),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard('En cours', '$_enCours', Colors.orange, Icons.pending_actions),
                      const SizedBox(width: 12),
                      _buildStatCard('Terminées', '$_terminees', Colors.green, Icons.check_circle),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Interventions actives',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  if (actives.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune intervention active',
                              style: TextStyle(color: Colors.grey[600], fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...actives.take(5).map((bt) => _buildInterventionCard(bt)).toList(),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/technicien-interventions');
                      },
                      icon: const Icon(Icons.build),
                      label: const Text('Voir toutes mes interventions', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterventionCard(BonTravailModel bt) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/technicien-detail-intervention', arguments: bt.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: bt.statutColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bt.statutLabel.toUpperCase(),
                      style: TextStyle(
                        color: bt.statutColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (bt.priorite != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPrioriteColor(bt.priorite!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bt.priorite.name,
                        style: TextStyle(
                          color: _getPrioriteColor(bt.priorite), 
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'BT #${bt.id}${bt.ascenseurNom != null ? ' - ${bt.ascenseurNom}' : ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (bt.siteAdresse != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bt.siteAdresse!,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    '${bt.dateInterventionPrevue.day}/${bt.dateInterventionPrevue.month}/${bt.dateInterventionPrevue.year} à ${bt.dateInterventionPrevue.hour.toString().padLeft(2, '0')}:${bt.dateInterventionPrevue.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

   Color _getPrioriteColor(PrioriteDemande priorite) {
    switch (priorite) {
      case PrioriteDemande.CRITIQUE:
      case PrioriteDemande.URGENTE:
        return Colors.red;
      case PrioriteDemande.NORMALE:
        return Colors.blue;
      case PrioriteDemande.FAIBLE:
        return Colors.green;
    }
  }
  
}
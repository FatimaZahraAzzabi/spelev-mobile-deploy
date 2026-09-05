import 'package:flutter/material.dart';
import '../../models/demande_maintenance_model.dart';
import '../../services/demande_maintenance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badges.dart';
import '../../widgets/notification_bell_widget.dart';
import 'client_drawer.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final _demandeService = DemandeMaintenanceService();
  List<DemandeMaintenanceModel> _demandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    try {
      final demandes = await _demandeService.getMesDemandes();
      if (mounted) {
        setState(() { 
          _demandes = demandes; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  int get _total => _demandes.length;
  int get _enAttente => _demandes.where((d) => d.statut == 'EN_ATTENTE' || d.statut == 'BROUILLON').length;
  
  int get _enCours => _demandes.where((d) => 
    d.statut == 'ACCEPTEE' || d.statut == 'ASSIGNEE' || d.statut == 'EN_COURS'
  ).length;
  
  int get _resolues => _demandes.where((d) => d.statut == 'RESOLUE' || d.statut == 'TERMINEE').length;
  int get _rejetees => _demandes.where((d) => d.statut == 'REJETEE' || d.statut == 'ANNULEE').length;

  @override
  Widget build(BuildContext context) {
    final demandesActives = _demandes.where((d) => 
      d.statut == 'EN_ATTENTE' || d.statut == 'ACCEPTEE' || d.statut == 'ASSIGNEE' || d.statut == 'EN_COURS'
    ).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: ClientDrawer(currentRoute: '/client-dashboard'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Tableau de bord', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          const NotificationBellWidget(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _loadDemandes,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : RefreshIndicator(
              onRefresh: _loadDemandes, 
              color: AppColors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bonjour 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    const Text('Voici le résumé de vos demandes de maintenance.', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    const SizedBox(height: 24),
                    
                    // Statistiques
                    Row(children: [
                      _buildStatCard('Total', '$_total', Colors.blue, Icons.receipt_long),
                      const SizedBox(width: 12),
                      _buildStatCard('En attente', '$_enAttente', Colors.amber, Icons.hourglass_empty),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _buildStatCard('En cours', '$_enCours', Colors.orange, Icons.pending_actions),
                      const SizedBox(width: 12),
                      _buildStatCard('Résolues', '$_resolues', Colors.green, Icons.check_circle),
                    ]),
                    
                    const SizedBox(height: 32),
                    const Text('Demandes récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    
                    if (demandesActives.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Aucune demande active', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...demandesActives.take(3).map(_buildDemandeCard),
                      
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/client-demandes'),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Voir toutes mes demandes', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/client-nouvelle-demande'),
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvelle demande', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
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
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandeCard(DemandeMaintenanceModel d) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/client-demande-detail', arguments: d.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                StatutBadge(statut: d.statut),
                const Spacer(),
                PrioriteBadge(priorite: d.priorite),
              ]),
              const SizedBox(height: 12),
              Text(labelTypeDemande(d.typeDemande), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.elevator, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(child: Text(d.ascenseurNom ?? 'Ascenseur #${d.ascenseurId}', style: const TextStyle(fontSize: 13, color: Colors.black87))),
              ]),
              const SizedBox(height: 8),
              Text(d.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(formatDateFr(d.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
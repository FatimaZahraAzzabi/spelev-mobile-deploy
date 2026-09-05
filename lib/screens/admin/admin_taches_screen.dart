import 'package:flutter/material.dart';
import 'admin_drawer.dart';
import 'nouvelle_tache_screen.dart';
import '../../services/tache_service.dart';
import '../../models/tache_model.dart';

class AdminTachesScreen extends StatefulWidget {
  const AdminTachesScreen({super.key});

  @override
  State<AdminTachesScreen> createState() => _AdminTachesScreenState();
}

class _AdminTachesScreenState extends State<AdminTachesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tacheService = TacheService();
  List<TacheModel> _taches = [];
  bool _isLoading = true;
  String _filter = 'TOUTES';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTaches();
    
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _loadTaches();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTaches() async {
    setState(() => _isLoading = true);
    try {
      final taches = await _tacheService.getTaches();
      setState(() {
        _taches = taches;
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

  Future<void> _deleteTache(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tacheService.deleteTache(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tâche supprimée avec succès'), backgroundColor: Colors.green),
          );
          _loadTaches();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  List<TacheModel> get _filteredTaches {
    if (_filter == 'TOUTES') return _taches;
    return _taches.where((t) => t.statut == _filter).toList();
  }

  Color _getColorStatut(String statut) {
    switch (statut) {
      case 'A_FAIRE': return Colors.orange;
      case 'EN_COURS': return Colors.blue;
      case 'TERMINE': return Colors.green;
      case 'ANNULE': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AdminDrawer(currentRoute: '/admin-taches'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Gestion des Tâches', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Liste des tâches'),
            Tab(icon: Icon(Icons.add_task), text: 'Nouvelle tâche'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListeTab(),
          
          // ONGLET 2 : CRÉATION DE TÂCHE
          // On utilise une clé unique pour réinitialiser le formulaire à chaque fois qu'on clique sur l'onglet
          KeyedSubtree(
            key: ValueKey('form_tache_${DateTime.now().millisecondsSinceEpoch}'),
            child: const NouvelleTacheScreen(isEmbedded: true), 
          ),
        ],
      ),
    );
  }

  Widget _buildListeTab() {
    return Column(
      children: [
        // Filtres
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['TOUTES', 'A_FAIRE', 'EN_COURS', 'TERMINE', 'ANNULE'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f == 'TOUTES' ? 'Toutes' : f),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = f);
                    },
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),

        // Liste
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTaches.isEmpty
                  ? const Center(child: Text('Aucune tâche trouvée', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTaches.length,
                      itemBuilder: (context, index) {
                        final tache = _filteredTaches[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: tache.type == 'PREVENTIF' ? Colors.blue[100] : Colors.red[100],
                              child: Icon(
                                tache.type == 'PREVENTIF' ? Icons.schedule : Icons.warning,
                                color: tache.type == 'PREVENTIF' ? Colors.blue[800] : Colors.red[800],
                              ),
                            ),
                            title: Text(tache.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(' ${tache.ascenseurNom ?? "Ascenseur inconnu"}'),
                                Text(' ${tache.responsableNom ?? "Non assigné"}'),
                                if (tache.dateEcheance != null)
                                  Text(' Échéance: ${tache.dateEcheance!.day}/${tache.dateEcheance!.month}/${tache.dateEcheance!.year}'),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getColorStatut(tache.statut).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tache.statut,
                                    style: TextStyle(color: _getColorStatut(tache.statut), fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 22, color: Colors.red),
                                  onPressed: () => _deleteTache(tache.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
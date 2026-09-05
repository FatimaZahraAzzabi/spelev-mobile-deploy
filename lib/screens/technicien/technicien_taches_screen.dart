import 'package:flutter/material.dart';
import 'technicien_drawer.dart';
import '../../theme/app_theme.dart';
import '../../services/tache_service.dart';
import '../../models/tache_model.dart';

class TechnicienTachesScreen extends StatefulWidget {
  const TechnicienTachesScreen({super.key});

  @override
  State<TechnicienTachesScreen> createState() => _TechnicienTachesScreenState();
}

class _TechnicienTachesScreenState extends State<TechnicienTachesScreen> {
  final _tacheService = TacheService();
  List<TacheModel> _taches = [];
  bool _isLoading = true;
  String _filter = 'TOUTES';

  @override
  void initState() {
    super.initState();
    _loadTaches();
  }

  Future<void> _loadTaches() async {
    setState(() => _isLoading = true);
    try {
      // On utilise le même endpoint qui filtre selon l'utilisateur connecté
      final taches = await _tacheService.getMesTaches(); 
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

  Future<void> _changerStatut(TacheModel tache, String nouveauStatut) async {
    // Confirmation avant de terminer
    if (nouveauStatut == 'TERMINE') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la fin de la tâche'), // ✅ Modifié
          content: const Text('Êtes-vous sûr d\'avoir terminé cette tâche ?'), // ✅ Modifié
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await _tacheService.updateStatut(tache.id, nouveauStatut);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getLabelStatut(nouveauStatut)}'),
            backgroundColor: Colors.green,
          ),
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

  List<TacheModel> get _filteredTaches {
    if (_filter == 'TOUTES') return _taches;
    return _taches.where((t) => t.statut == _filter).toList();
  }

  String _getLabelStatut(String statut) {
    switch (statut) {
      case 'A_FAIRE': return 'À faire';
      case 'EN_COURS': return 'En cours';
      case 'TERMINE': return 'Terminé';
      case 'ANNULE': return 'Annulé';
      default: return statut;
    }
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'URGENTE': return Colors.red;
      case 'HAUTE': return Colors.orange;
      case 'MOYENNE': return Colors.blue;
      case 'BASSE': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const TechnicienDrawer(currentRoute: '/technicien-taches'), // ✅ Route mise à jour
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Mes tâches', // ✅ Modifié
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['TOUTES', 'A_FAIRE', 'EN_COURS', 'TERMINE'].map((f) {
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f == 'TOUTES' ? 'Toutes' : _getLabelStatut(f)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = f);
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _filteredTaches.isEmpty
                    ? const Center(
                        child: Text('Aucune tâche', style: TextStyle(color: Colors.grey)), // ✅ Modifié
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTaches.length,
                        itemBuilder: (context, index) {
                          final tache = _filteredTaches[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: tache.type == 'PREVENTIF' ? Colors.blue[100] : Colors.red[100],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tache.type == 'PREVENTIF' ? 'Préventif' : 'Correctif',
                                          style: TextStyle(
                                            color: tache.type == 'PREVENTIF' ? Colors.blue[800] : Colors.red[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPrioriteColor(tache.priorite).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tache.priorite,
                                          style: TextStyle(
                                            color: _getPrioriteColor(tache.priorite),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: tache.statut == 'TERMINE'
                                              ? Colors.green[100]
                                              : tache.statut == 'EN_COURS'
                                                  ? Colors.blue[100]
                                                  : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _getLabelStatut(tache.statut),
                                          style: TextStyle(
                                            color: tache.statut == 'TERMINE'
                                                ? Colors.green[800]
                                                : tache.statut == 'EN_COURS'
                                                    ? Colors.blue[800]
                                                    : Colors.orange[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Titre
                                  Text(
                                    tache.titre,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  if (tache.description != null && tache.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tache.description!,
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Infos
                                  Row(
                                    children: [
                                      const Icon(Icons.elevator, size: 16, color: Colors.black54),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          tache.ascenseurNom ?? 'Ascenseur inconnu',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (tache.ascenseurSite != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            tache.ascenseurSite!,
                                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (tache.dateEcheance != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Échéance: ${tache.dateEcheance!.day}/${tache.dateEcheance!.month}/${tache.dateEcheance!.year}',
                                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // ✅ BOUTONS D'ACTION POUR LE TECHNICIEN
                                  if (tache.statut != 'TERMINE' && tache.statut != 'ANNULE')
                                    Row(
                                      children: [
                                        if (tache.statut == 'A_FAIRE')
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _changerStatut(tache, 'EN_COURS'),
                                              icon: const Icon(Icons.play_arrow, size: 18),
                                              label: const Text('Démarrer'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                        if (tache.statut == 'A_FAIRE') const SizedBox(width: 8),
                                        if (tache.statut == 'EN_COURS')
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _changerStatut(tache, 'TERMINE'),
                                              icon: const Icon(Icons.check, size: 18),
                                              label: const Text('Terminer'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    const Text(
                                      'Tâche terminée', // ✅ Modifié
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
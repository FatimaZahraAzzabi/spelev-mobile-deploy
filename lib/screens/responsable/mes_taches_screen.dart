import 'package:flutter/material.dart';
import 'responsable_drawer.dart';
import '../../services/tache_service.dart';
import '../../services/utilisateur_service.dart';
import '../../models/tache_model.dart';
import '../../models/utilisateur_model.dart';

class MesTachesScreen extends StatefulWidget {
  const MesTachesScreen({super.key});

  @override
  State<MesTachesScreen> createState() => _MesTachesScreenState();
}

class _MesTachesScreenState extends State<MesTachesScreen> {
  final _tacheService = TacheService();
  final _utilisateurService = UtilisateurService();
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

  // ✅ NOUVEAU : Sélection MULTIPLE de techniciens
  Future<void> _showAssignTechniciensDialog(TacheModel tache) async {
    List<UtilisateurModel> tousLesTechniciens = [];
    Map<UtilisateurModel, bool> selections = {};
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loading && tousLesTechniciens.isEmpty) {
              _utilisateurService.getTechniciens().then((list) {
                setModalState(() {
                  tousLesTechniciens = list;
                  // Initialiser les sélections (cocher ceux déjà assignés si on veut, ou tout décocher)
                  for (var tech in tousLesTechniciens) {
                    selections[tech] = false;
                  }
                  loading = false;
                });
              }).catchError((e) {
                setModalState(() => loading = false);
              });
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionner les techniciens',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else if (tousLesTechniciens.isEmpty)
                    const Center(child: Text('Aucun technicien disponible.'))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: tousLesTechniciens.length,
                        itemBuilder: (context, index) {
                          final tech = tousLesTechniciens[index];
                          return CheckboxListTile(
                            title: Text('${tech.prenom} ${tech.nom}'),
                            subtitle: Text(tech.specialite ?? 'Spécialité non définie'),
                            value: selections[tech] ?? false,
                            onChanged: (bool? value) {
                              setModalState(() {
                                selections[tech] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Récupérer les IDs sélectionnés
                        List<int> idsSelectionnes = selections.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key.id)
                            .toList();

                        if (idsSelectionnes.isEmpty) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez sélectionner au moins un technicien'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                        try {
                          await _tacheService.assignerTechniciens(tache.id, idsSelectionnes);
                          if (mounted) {
                            Navigator.pop(context); // Fermer loader
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Techniciens assignés avec succès'), backgroundColor: Colors.green),
                            );
                            _loadTaches();
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirmer l\'assignation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<TacheModel> get _filteredTaches {
    if (_filter == 'TOUTES') return _taches;
    return _taches.where((t) => t.statut == _filter).toList();
  }

  Color _getColorPriorite(String priorite) {
    switch (priorite) {
      case 'URGENTE': return Colors.red;
      case 'HAUTE': return Colors.orange;
      case 'MOYENNE': return Colors.blue;
      case 'BASSE': return Colors.green;
      default: return Colors.grey;
    }
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

  String _getLabelStatut(String statut) {
    switch (statut) {
      case 'A_FAIRE': return 'À faire';
      case 'EN_COURS': return 'En cours';
      case 'TERMINE': return 'Terminé';
      case 'ANNULE': return 'Annulé';
      default: return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-mes-taches'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Mes tâches', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
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
                    ? const Center(child: Text('Aucune tâche', style: TextStyle(color: Colors.grey)))
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
                                        decoration: BoxDecoration(color: tache.type == 'PREVENTIF' ? Colors.blue[100] : Colors.red[100], borderRadius: BorderRadius.circular(6)),
                                        child: Text(tache.type == 'PREVENTIF' ? 'Préventif' : 'Correctif', style: TextStyle(color: tache.type == 'PREVENTIF' ? Colors.blue[800] : Colors.red[800], fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _getColorPriorite(tache.priorite).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                        child: Text(tache.priorite, style: TextStyle(color: _getColorPriorite(tache.priorite), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _getColorStatut(tache.statut).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                        child: Text(_getLabelStatut(tache.statut), style: TextStyle(color: _getColorStatut(tache.statut), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(tache.titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  if (tache.description != null && tache.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(tache.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                  ],
                                  const SizedBox(height: 12),
                                  
                                  // Infos Ascenseur
                                  Row(children: [const Icon(Icons.elevator, size: 16, color: Colors.black54), const SizedBox(width: 4), Expanded(child: Text(tache.ascenseurNom ?? 'Ascenseur inconnu', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))]),
                                  if (tache.ascenseurSite != null) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.black54), const SizedBox(width: 4), Expanded(child: Text(tache.ascenseurSite!, style: const TextStyle(fontSize: 13, color: Colors.black54)))]),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // ✅ GESTION DES TECHNICIENS (MULTIPLE)
                                  if (tache.technicienNoms != null && tache.technicienNoms!.isNotEmpty) ...[
                                    const Text('Techniciens assignés :', style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: tache.technicienNoms!.map((nom) => Chip(
                                        avatar: const Icon(Icons.engineering, size: 18, color: Colors.green),
                                        label: Text(nom, style: const TextStyle(fontSize: 13)),
                                        backgroundColor: Colors.green[50],
                                        side: const BorderSide(color: Colors.green),
                                      )).toList(),
                                    ),
                                  ] else ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showAssignTechniciensDialog(tache),
                                        icon: const Icon(Icons.person_add, size: 18),
                                        label: const Text('Assigner des techniciens'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue), padding: const EdgeInsets.symmetric(vertical: 10)),
                                      ),
                                    ),
                                  ],
                                  
                                  // ✅ LES BOUTONS DE STATUT ONT ÉTÉ SUPPRIMÉS ICI (Le responsable ne peut plus les changer)
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
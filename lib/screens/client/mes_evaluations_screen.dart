import 'package:flutter/material.dart';
import '../../services/evaluation_service.dart';
import '../../theme/app_theme.dart';
import 'client_drawer.dart';
import 'evaluation_detail_screen.dart';
import 'nouvelle_evaluation_screen.dart';

class MesEvaluationsScreen extends StatefulWidget {
  const MesEvaluationsScreen({super.key});

  @override
  State<MesEvaluationsScreen> createState() => _MesEvaluationsScreenState();
}

class _MesEvaluationsScreenState extends State<MesEvaluationsScreen> {
  final _evaluationService = EvaluationService();
  List<Map<String, dynamic>> _evaluations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _evaluationService.getMesEvaluations();
      if (mounted) setState(() => _evaluations = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDetail(Map<String, dynamic> d) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EvaluationDetailScreen(evaluation: d)),
    );
    if (result == true) _load();
  }

  Future<void> _annuler(Map<String, dynamic> d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler cette demande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _evaluationService.annuler(d['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande annulée'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  (String, Color) _statutInfo(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return ('En attente', Colors.orange);
      case 'ASSIGNEE': return ('Visite planifiée', Colors.blue);
      case 'EN_COURS': return ('Visite en cours', Colors.teal);
      case 'RESOLUE': return ('Ascenseur enregistré', Colors.green);
      case 'REJETEE': return ('Refusée', Colors.red);
      case 'ANNULEE': return ('Annulée', Colors.grey);
      default: return (statut, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: ClientDrawer(currentRoute: '/client-mes-evaluations'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Mes évaluations',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.orange), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NouvelleEvaluationScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle évaluation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _evaluations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Aucune demande d\'évaluation', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Appuyez sur "Nouvelle évaluation" pour commencer',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _evaluations.length,
                    itemBuilder: (_, i) {
                      final d = _evaluations[i];
                      final statut = d['statut'] ?? 'EN_ATTENTE';
                      final (label, color) = _statutInfo(statut);
                      final ville = d['villeSaisie'] ?? '';
                      final adresse = d['adresseSaisie'] ?? '';
                      final description = d['description'] ?? '';
                      final id = d['id'] ?? 0;
                      final photos = d['photos'] ?? [];
                      final createdAt = d['createdAt'];
                      final peutAnnuler = statut == 'EN_ATTENTE';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(label,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                                  ),
                                  const Spacer(),
                                  Text('#$id', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_city, size: 16, color: AppColors.navy),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$ville${adresse.isNotEmpty ? ' - $adresse' : ''}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 13, color: Colors.black45),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Créée le : ${createdAt != null ? createdAt.toString().substring(0, 10) : ''}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const Spacer(),
                                  if (photos is List && photos.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.attach_file, size: 13, color: Colors.black45),
                                        const SizedBox(width: 4),
                                        Text('${photos.length}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openDetail(d),
                                      icon: const Icon(Icons.visibility, size: 16),
                                      label: const Text('Voir'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.navy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  if (peutAnnuler) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _annuler(d),
                                        icon: const Icon(Icons.cancel_outlined, size: 16),
                                        label: const Text('Annuler'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
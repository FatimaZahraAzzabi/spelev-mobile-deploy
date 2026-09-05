import 'package:flutter/material.dart';
import '../../services/demande_maintenance_service.dart';
import '../../models/demande_maintenance_model.dart';

class DemandesEnAttenteScreen extends StatefulWidget {
  const DemandesEnAttenteScreen({super.key});

  @override
  State<DemandesEnAttenteScreen> createState() => _DemandesEnAttenteScreenState();
}

class _DemandesEnAttenteScreenState extends State<DemandesEnAttenteScreen> {
  final _service = DemandeMaintenanceService();
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
      final data = await _service.getDemandesEnAttente();
      setState(() {
        _demandes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _rejeterDemande(DemandeMaintenanceModel demande) async {
    final motifController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez fournir un motif de rejet :'),
            const SizedBox(height: 12),
            TextField(
              controller: motifController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Ex: Pièce non disponible, hors contrat...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && motifController.text.trim().length >= 10) {
      try {
        await _service.rejeterDemande(demande.id, motifController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande rejetée'), backgroundColor: Colors.orange));
          _loadDemandes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        }
      }
    } else if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le motif doit faire au moins 10 caractères'), backgroundColor: Colors.red));
    }
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'CRITIQUE': return Colors.red;
      case 'HAUTE': return Colors.orange;
      case 'MOYENNE': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Demandes en attente', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _demandes.isEmpty
              ? const Center(child: Text('Aucune demande en attente', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _demandes.length,
                  itemBuilder: (context, index) {
                    final d = _demandes[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(d.ascenseurNom ?? 'Ascenseur #${d.ascenseurId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _getPrioriteColor(d.priorite).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(d.priorite, style: TextStyle(color: _getPrioriteColor(d.priorite), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                           Text('Client: ${d.clientNomComplet}', style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 8),
                            Text(d.description, style: const TextStyle(color: Colors.black87)),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _rejeterDemande(d),
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Naviguer vers l'écran de création de Bon de Travail en passant l'ID de la demande
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Création BT pour la demande #${d.id} (À implémenter)')));
                                  },
                                  icon: const Icon(Icons.build, size: 20),
                                  label: const Text('Créer Bon de Travail'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
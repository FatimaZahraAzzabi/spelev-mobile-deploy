import 'package:flutter/material.dart';
import '../../models/demande_maintenance_model.dart';
import '../../services/demande_maintenance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badges.dart';
import 'client_drawer.dart';

class ClientDemandesScreen extends StatefulWidget {
  const ClientDemandesScreen({super.key});

  @override
  State<ClientDemandesScreen> createState() => _ClientDemandesScreenState();
}

class _ClientDemandesScreenState extends State<ClientDemandesScreen> {
  final _service = DemandeMaintenanceService();
  final _searchController = TextEditingController();
  List<DemandeMaintenanceModel> _demandes = [];
  bool _isLoading = true;
  String _filtreType = 'TOUS';
  String _filtreStatut = 'TOUS';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getMesDemandes();
      setState(() {
        _demandes = list;
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

  List<DemandeMaintenanceModel> get _filtrees {
    return _demandes.where((d) {
      final okType = _filtreType == 'TOUS' || d.typeDemande == _filtreType;
      final okStatut = _filtreStatut == 'TOUS' || d.statut == _filtreStatut;
      final q = _searchController.text.trim().toLowerCase();
      final okSearch = q.isEmpty ||
          d.description.toLowerCase().contains(q) ||
          (d.ascenseurNom ?? '').toLowerCase().contains(q) ||
          labelTypeDemande(d.typeDemande).toLowerCase().contains(q);
      return okType && okStatut && okSearch;
    }).toList();
  }

  Future<void> _annuler(DemandeMaintenanceModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text('Voulez-vous vraiment annuler cette demande ?'),
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
      await _service.annuler(d.id);
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

  @override
  Widget build(BuildContext context) {
    final list = _filtrees;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: ClientDrawer(currentRoute: '/client-demandes'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Mes demandes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ─── En-tête identique au web ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes demandes de maintenance',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                          const SizedBox(height: 6),
                          Container(width: 40, height: 3, color: AppColors.orange),
                          const SizedBox(height: 6),
                          Text(
                            '${_demandes.length} demande(s)',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/client-nouvelle-demande');
                        _load();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nouvelle demande', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ─── Recherche ───
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par ascenseur, type...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                // ─── Filtres ───
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtreType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TOUS', child: Text('Tous les types', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'PANNE', child: Text('Panne', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'ENTRETIEN_PREVENTIF', child: Text('Entretien préventif', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'BRUIT_ANORMAL', child: Text('Bruit anormal', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'AUTRE', child: Text('Autre', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) => setState(() => _filtreType = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtreStatut,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TOUS', child: Text('Tous les statuts', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'EN_ATTENTE', child: Text('En attente', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'ASSIGNEE', child: Text('Assignée', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'EN_COURS', child: Text('En cours', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'RESOLUE', child: Text('Résolue', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'ANNULEE', child: Text('Annulée', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'REJETEE', child: Text('Rejetée', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) => setState(() => _filtreStatut = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ─── Liste ───
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : list.isEmpty
                    ? const Center(child: Text('Aucune demande trouvée', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _buildCard(list[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(DemandeMaintenanceModel d) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : N° + statut + date (comme les colonnes du web)
            Row(
              children: [
                Text('#${d.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(width: 8),
                StatutBadge(statut: d.statut),
                const Spacer(),
                Text(formatDateFr(d.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            // Ligne 2 : type + ascenseur
            Text(
              labelTypeDemande(d.typeDemande),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.elevator, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.ascenseurNom ?? '—',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Ligne 3 : actions Voir / Annuler (comme le web)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/client-demande-detail', arguments: d.id);
                    _load();
                  },
                  child: const Text('Voir', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                if (d.statut == 'EN_ATTENTE')
                  TextButton(
                    onPressed: () => _annuler(d),
                    child: const Text('Annuler', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
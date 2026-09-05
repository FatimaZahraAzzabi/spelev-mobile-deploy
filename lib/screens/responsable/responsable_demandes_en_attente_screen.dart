import 'package:flutter/material.dart';
import '../../services/demande_maintenance_service.dart';
import '../../models/demande_maintenance_model.dart';
import '../../theme/app_theme.dart';
import 'responsable_drawer.dart';
import 'responsable_demande_detail_screen.dart';

class ResponsableDemandesEnAttenteScreen extends StatefulWidget {
  const ResponsableDemandesEnAttenteScreen({super.key});

  @override
  State<ResponsableDemandesEnAttenteScreen> createState() =>
      _ResponsableDemandesEnAttenteScreenState();
}

class _ResponsableDemandesEnAttenteScreenState
    extends State<ResponsableDemandesEnAttenteScreen> {
  final _service = DemandeMaintenanceService();
  List<DemandeMaintenanceModel> _demandes = [];
  List<DemandeMaintenanceModel> _filteredDemandes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterPriorite = 'Tous';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getDemandesEnAttente();
      setState(() {
        _demandes = data;
        _filteredDemandes = data;
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

  void _applyFilters() {
    setState(() {
      _filteredDemandes = _demandes.where((d) {
        final matchSearch = _searchQuery.isEmpty ||
            d.clientNomComplet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (d.ascenseurNom?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            d.description.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchPriorite = _filterPriorite == 'Tous' || d.priorite == _filterPriorite;

        return matchSearch && matchPriorite;
      }).toList();
    });
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'CRITIQUE': return Colors.red;
      case 'URGENTE': return Colors.orange;
      case 'NORMALE': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getPrioriteIcon(String priorite) {
    switch (priorite) {
      case 'CRITIQUE': return Icons.error_outline;
      case 'URGENTE': return Icons.warning_amber_outlined;
      case 'NORMALE': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-demandes-attente'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Demandes en attente',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _loadDemandes,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par client, ascenseur...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priorité:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterPriorite,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: ['Tous', 'CRITIQUE', 'URGENTE', 'NORMALE']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _filterPriorite = value!);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _filteredDemandes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune demande en attente',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDemandes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDemandes.length,
                          itemBuilder: (context, index) {
                            final d = _filteredDemandes[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResponsableDemandeDetailScreen(demande: d),
                                    ),
                                  ).then((_) => _loadDemandes());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Demande N° ${d.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppColors.navy,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  d.clientNomComplet,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPrioriteColor(d.priorite).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getPrioriteIcon(d.priorite),
                                                  size: 14,
                                                  color: _getPrioriteColor(d.priorite),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  d.priorite,
                                                  style: TextStyle(
                                                    color: _getPrioriteColor(d.priorite),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.elevator, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              d.ascenseurNom ?? 'Ascenseur #${d.ascenseurId}',
                                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        d.description,
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            d.createdAt != null
                                                ? _formatDate(DateTime.parse(d.createdAt!))
                                                : '',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                          ),
                                          const Text(
                                            'Voir détails →',
                                            style: TextStyle(
                                              color: AppColors.orange,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
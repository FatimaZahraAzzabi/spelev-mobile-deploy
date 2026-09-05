import 'package:flutter/material.dart';
import '../../services/bon_travail_service.dart';
import '../../models/bon_travail_model.dart';
import '../../theme/app_theme.dart';
import 'technicien_drawer.dart';
import 'technicien_detail_intervention_screen.dart';

class TechnicienInterventionsScreen extends StatefulWidget {
  const TechnicienInterventionsScreen({super.key});

  @override
  State<TechnicienInterventionsScreen> createState() => _TechnicienInterventionsScreenState();
}

class _TechnicienInterventionsScreenState extends State<TechnicienInterventionsScreen> {
  final _service = BonTravailService();
  List<BonTravailModel> _interventions = [];
  bool _isLoading = true;
  String _filterStatut = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMesInterventions();
      setState(() {
        _interventions = data;
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

  Color _getStatutColor(StatutBonTravail statut) {
    switch (statut) {
      case StatutBonTravail.PLANIFIE: return Colors.blue;
      case StatutBonTravail.EN_COURS: return Colors.orange;
      case StatutBonTravail.TERMINE: return Colors.green;
      case StatutBonTravail.ANNULE: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const TechnicienDrawer(currentRoute: '/technicien-interventions'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Mes interventions', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.orange), onPressed: _loadInterventions),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Filtrer:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatut,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                    items: ['Tous', 'PLANIFIE', 'EN_COURS', 'TERMINE', 'ANNULE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (value) => setState(() => _filterStatut = value!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _interventions.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Aucune intervention', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadInterventions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _interventions.length,
                          itemBuilder: (context, index) {
                            final b = _interventions[index];
                            if (_filterStatut != 'Tous' && b.statut.name != _filterStatut) return const SizedBox.shrink();
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TechnicienDetailInterventionScreen(bonId: b.id)),
                                  ).then((_) => _loadInterventions());
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
                                                Text('BT N° ${b.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
                                                const SizedBox(height: 4),
                                                Text(b.ascenseurNom ?? 'Ascenseur #${b.ascenseurId}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: _getStatutColor(b.statut).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                            child: Text(b.statutLabel, style: TextStyle(color: _getStatutColor(b.statut), fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text(b.siteAdresse ?? 'Adresse non définie', style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Text(_formatDate(b.dateInterventionPrevue), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                        ],
                                      ),
                                      if (b.statut == StatutBonTravail.EN_COURS) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                                          child: Row(
                                            children: [
                                              Icon(Icons.timer, color: Colors.orange[700], size: 16),
                                              const SizedBox(width: 8),
                                              Text('Intervention en cours', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
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
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import '../../services/demande_maintenance_service.dart';
import '../../models/demande_maintenance_model.dart';
import '../../theme/app_theme.dart';
import 'demande_evaluation_detail_screen.dart';

class DemandesInstallationsScreen extends StatefulWidget {
  const DemandesInstallationsScreen({super.key});

  @override
  State<DemandesInstallationsScreen> createState() =>
      _DemandesInstallationsScreenState();
}

class _DemandesInstallationsScreenState
    extends State<DemandesInstallationsScreen> {
  final _service = DemandeMaintenanceService();
  List<DemandeMaintenanceModel> _demandes = [];
  bool _isLoading = true;
  String _filtreStatut = 'TOUS';

  final List<String> _statutsFiltres = [
    'TOUS',
    'EN_ATTENTE',
    'ACCEPTEE',
    'REJETEE',
    'RESOLUE'
  ];

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getDemandesInstallations();
      setState(() {
        _demandes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DemandeMaintenanceModel> get _demandesFiltrees {
    if (_filtreStatut == 'TOUS') return _demandes;
    return _demandes.where((d) => d.statut == _filtreStatut).toList();
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'ACCEPTEE':
        return Colors.green;
      case 'REJETEE':
        return Colors.red;
      case 'RESOLUE':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLibelle(String statut) {
    switch (statut) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'ACCEPTEE':
        return 'Acceptée';
      case 'REJETEE':
        return 'Rejetée';
      case 'RESOLUE':
        return 'Résolue';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nouvelles installations',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statutsFiltres.map((statut) {
                  final isSelected = _filtreStatut == statut;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        statut == 'TOUS' ? 'Tous' : _getStatutLibelle(statut),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _filtreStatut = statut;
                        });
                      },
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: AppColors.navy,
                      checkmarkColor: Colors.white,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected ? AppColors.navy : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  )
                : _demandesFiltrees.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.elevator, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucune demande d\'installation',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Les nouvelles demandes apparaîtront ici',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDemandes,
                        color: AppColors.orange,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _demandesFiltrees.length,
                          itemBuilder: (context, index) {
                            final d = _demandesFiltrees[index];
                            return _buildDemandeCard(d);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(DemandeMaintenanceModel demande) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DemandeEvaluationDetailScreen(
              demande: demande,
            ),
          ),
        ).then((_) => _loadDemandes());
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getStatutColor(demande.statut).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.navy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.elevator,
                            color: AppColors.navy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Demande N°${demande.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                demande.clientNomComplet,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatutColor(demande.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatutLibelle(demande.statut),
                      style: TextStyle(
                        color: _getStatutColor(demande.statut),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (demande.adresseSaisie != null && demande.adresseSaisie!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          demande.adresseSaisie!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (demande.villeSaisie != null && demande.villeSaisie!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_city_outlined,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          demande.villeSaisie!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                demande.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Nouvelle installation',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (demande.createdAt != null)
                    Text(
                      _formatDate(DateTime.parse(demande.createdAt!)),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              if (demande.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${demande.photos.length} pièce${demande.photos.length > 1 ? 's' : ''} jointe${demande.photos.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
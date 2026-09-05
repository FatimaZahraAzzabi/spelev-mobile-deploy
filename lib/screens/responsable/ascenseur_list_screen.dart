import 'package:flutter/material.dart';
import 'responsable_drawer.dart';
import '../../services/ascenseur_service.dart';
import '../../models/ascenseur_model.dart';
import 'assemblage_tree_screen.dart';
import '../../theme/app_theme.dart';
import 'nouvel_ascenseur_screen.dart';

class AscenseurListScreen extends StatefulWidget {
  const AscenseurListScreen({super.key});

  @override
  State<AscenseurListScreen> createState() => _AscenseurListScreenState();
}

class _AscenseurListScreenState extends State<AscenseurListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _service = AscenseurService();
  String _searchQuery = '';
  List<AscenseurModel> _ascenseurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAscenseurs();
  }

  Future<void> _loadAscenseurs() async {
    setState(() => _isLoading = true);
    try {
      final ascenseurs = await _service.getAscenseurs();
      setState(() {
        _ascenseurs = ascenseurs;
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

  Future<void> _deleteAscenseur(int id, String nom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'ascenseur "$nom" ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteAscenseur(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ascenseur supprimé avec succès'), backgroundColor: Colors.green),
          );
          _loadAscenseurs();
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

  void _showDetails(AscenseurModel asc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.85,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fiche de l\'ascenseur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      asc.nom,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: asc.actif ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      asc.actif ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: asc.actif ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildSectionTitle('Informations générales'),
              const SizedBox(height: 12),
              _buildInfoRow('Marque', asc.marque ?? 'Non renseigné'),
              _buildInfoRow('Fabricant', asc.fabricant ?? 'Non renseigné'),
              if (asc.modele != null) _buildInfoRow('Modèle', asc.modele!),
              if (asc.numeroSerie != null) _buildInfoRow('N° de série', asc.numeroSerie!),
              const SizedBox(height: 24),
              _buildSectionTitle('Caractéristiques techniques'),
              const SizedBox(height: 12),
              if (asc.nombreEtages != null) _buildInfoRow('Nombre d\'étages', '${asc.nombreEtages}'),
              if (asc.capacitePersonnes != null) _buildInfoRow('Capacité', '${asc.capacitePersonnes} personnes'),
              if (asc.chargeMaxKg != null) _buildInfoRow('Charge max', '${asc.chargeMaxKg} kg'),
              if (asc.vitesse != null) _buildInfoRow('Vitesse', '${asc.vitesse} m/s'),
              const SizedBox(height: 24),
              _buildSectionTitle('Rattachement'),
              const SizedBox(height: 12),
              _buildInfoRow('Client', '${asc.clientPrenom ?? ''} ${asc.clientNom ?? 'Non défini'}'),
              _buildInfoRow('Site', asc.siteAdresse ?? 'Adresse non définie'),
              if (asc.parcNom != null) _buildInfoRow('Parc', asc.parcNom!),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssemblageTreeScreen(
                          ascenseurId: asc.id,
                          ascenseurNom: asc.nom,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_tree, color: Colors.white, size: 20),
                  label: const Text(
                    'Voir l\'arborescence des pièces',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  List<AscenseurModel> get _filteredAscenseurs {
    if (_searchQuery.isEmpty) return _ascenseurs;
    return _ascenseurs.where((asc) {
      final nom = asc.nom.toLowerCase();
      final site = (asc.siteAdresse ?? '').toLowerCase();
      final marque = (asc.marque ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) || site.contains(query) || marque.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const ResponsableDrawer(currentRoute: '/responsable-ascenseur-list'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Gestion des Ascenseurs',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche professionnelle
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom, site...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/responsable-nouvel-ascenseur'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste ou État vide
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _filteredAscenseurs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.elevator, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun ascenseur trouvé',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez de modifier votre recherche',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAscenseurs,
                        color: AppColors.orange,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAscenseurs.length,
                          itemBuilder: (context, index) {
                            final asc = _filteredAscenseurs[index];
                            return _buildElevatorCard(asc);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ✅ Carte professionnelle pour chaque ascenseur - VERSION CORRIGÉE
  Widget _buildElevatorCard(AscenseurModel asc) {
    return GestureDetector(
      onTap: () => _showDetails(asc),
      child: Card(
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône avec fond subtil
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.elevator,
                      color: AppColors.navy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                asc.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: asc.actif ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                asc.actif ? 'Actif' : 'Inactif',
                                style: TextStyle(
                                  color: asc.actif ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                asc.siteAdresse ?? 'Site non défini',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.business_outlined, size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${asc.marque ?? 'Marque ?'} • ${asc.fabricant ?? 'Fabricant ?'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: Colors.grey.shade200),
              
              // ✅ Section des boutons - VERSION CORRIGÉE (Icônes au lieu de texte)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton Modifier (icône seule)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NouvelAscenseurScreen(ascenseur: asc),
                      ),
                    ).then((result) {
                      if (result == true) _loadAscenseurs();
                    }),
                    color: AppColors.orange,
                    tooltip: 'Modifier',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  // Bouton Détails (icône seule)
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: () => _showDetails(asc),
                    color: AppColors.navy,
                    tooltip: 'Détails',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  // Bouton Supprimer (icône seule)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteAscenseur(asc.id, asc.nom),
                    color: Colors.red.shade700,
                    tooltip: 'Supprimer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ],
          ),
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
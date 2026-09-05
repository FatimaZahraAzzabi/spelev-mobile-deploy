import 'package:flutter/material.dart';
import 'responsable_drawer.dart';
import '../../theme/app_theme.dart';
import '../../services/site_service.dart';
import '../../models/site_model.dart';
import 'site_detail_screen.dart'; 

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _service = SiteService();
  String _searchQuery = '';
  List<SiteModel> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    try {
      final sites = await _service.getSites();
      setState(() {
        _sites = sites;
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

  List<SiteModel> get _filteredSites {
    if (_searchQuery.isEmpty) return _sites;
    return _sites.where((site) {
      final adresse = site.adresse.toLowerCase();
      final ville = site.ville?.nom.toLowerCase() ?? '';
      final client = site.client != null 
          ? '${site.client!.prenom} ${site.client!.nom}'.toLowerCase() 
          : '';
      final query = _searchQuery.toLowerCase();
      return adresse.contains(query) || ville.contains(query) || client.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-site-list'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Gestion des Sites',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par adresse, ville ou client...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/responsable-nouveau-site');
                    _loadSites(); 
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _filteredSites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Aucun site trouvé', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSites, 
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSites.length,
                          itemBuilder: (context, index) {
                            final site = _filteredSites[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.navy.withOpacity(0.1),
                                  child: const Icon(Icons.business, color: AppColors.navy),
                                ),
                                title: Text(
                                  site.adresse,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (site.ville != null)
                                      Text(' ${site.ville!.nom} ${site.codePostal ?? ''}', style: const TextStyle(color: Colors.black87)),
                                    if (site.client != null)
                                      Text(' ${site.client!.prenom} ${site.client!.nom}', 
                                          style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SiteDetailScreen(site: site),
                                    ),
                                  );
                                },
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
}
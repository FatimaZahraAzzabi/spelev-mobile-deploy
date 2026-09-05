import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../services/assemblage_service.dart';
import '../../models/assemblage_model.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import 'add_assemblage_screen.dart';
import 'add_composant_screen.dart';

class AssemblageTreeScreen extends StatefulWidget {
  final int ascenseurId;
  final String ascenseurNom;

  const AssemblageTreeScreen({
    super.key,
    required this.ascenseurId,
    required this.ascenseurNom,
  });

  @override
  State<AssemblageTreeScreen> createState() => _AssemblageTreeScreenState();
}

class _AssemblageTreeScreenState extends State<AssemblageTreeScreen> {
  final _service = AssemblageService();
  List<AssemblageModel> _arbre = [];
  bool _isLoading = true;
  String _selectedTab = 'arborescence';

  @override
  void initState() {
    super.initState();
    _chargerArbre();
  }

  Future<void> _chargerArbre() async {
    setState(() => _isLoading = true);
    try {
      final arbre = await _service.getArbreParAscenseur(widget.ascenseurId);
      setState(() {
        _arbre = arbre;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ascenseurNom,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              'Arborescence technique',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Arborescence',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedTab = 'informations');
            },
            child: Text(
              'Informations',
              style: TextStyle(
                color: _selectedTab == 'informations' ? AppColors.orange : Colors.grey[600],
                fontWeight: _selectedTab == 'informations' ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: _selectedTab == 'arborescence' ? _buildArborescenceTab() : _buildInformationsTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAssemblageScreen(
                ascenseurId: widget.ascenseurId,
                ascenseurNom: widget.ascenseurNom,
              ),
            ),
          ).then((_) => _chargerArbre());
        },
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter assemblage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildArborescenceTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
        : _arbre.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_tree, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun assemblage configuré',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _chargerArbre,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _arbre.length,
                  itemBuilder: (context, index) {
                    return _buildAssemblageCard(_arbre[index]);
                  },
                ),
              );
  }

  Widget _buildImagePlaceholder(IconData icon, String label) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.navy.withOpacity(0.2)),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssemblageCard(AssemblageModel node) {
    final hasChildren = node.sousAssemblages != null && node.sousAssemblages!.isNotEmpty;
    final hasComposants = node.composants != null && node.composants!.isNotEmpty;
    
    final String rawUrl = node.imageUrl ?? '';
    final String correctedUrl = ApiConfig.fixMinioUrl(rawUrl);
    final hasImage = correctedUrl.isNotEmpty;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AuthenticatedImage(url: correctedUrl, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Niveau ${node.niveau ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildImagePlaceholder(Icons.image_outlined, 'Aucune image disponible'),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.nom,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Réf: ${node.reference ?? "Non définie"}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      onSelected: (value) {
                        if (value == 'add_sous_assemblage') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAssemblageScreen(
                                ascenseurId: widget.ascenseurId,
                                ascenseurNom: widget.ascenseurNom,
                                parentId: node.id,
                              ),
                            ),
                          ).then((_) => _chargerArbre());
                        } else if (value == 'add_composant') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddComposantScreen(
                                assemblageId: node.id,
                                assemblageNom: node.nom,
                              ),
                            ),
                          ).then((_) => _chargerArbre());
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'add_sous_assemblage',
                          child: Row(
                            children: [
                              Icon(Icons.add_box, color: AppColors.orange),
                              SizedBox(width: 8),
                              Text('Ajouter sous-assemblage'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_composant',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Ajouter composant'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (hasComposants) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.settings, size: 16, color: AppColors.navy),
                      const SizedBox(width: 8),
                      const Text(
                        'Composants',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${node.composants!.length}',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...node.composants!.map((comp) => _buildComposantItem(comp)),
                ],

                if (hasChildren) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.folder_open, size: 16, color: AppColors.navy),
                      const SizedBox(width: 8),
                      const Text(
                        'Sous-assemblages',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: node.sousAssemblages!.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _buildChildAssemblyCard(node.sousAssemblages![index]);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposantItem(dynamic comp) {
    final String rawCompUrl = comp.imageUrl ?? '';
    final String correctedCompUrl = ApiConfig.fixMinioUrl(rawCompUrl);
    final hasCompImage = correctedCompUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          if (hasCompImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 48,
                child: AuthenticatedImage(url: correctedCompUrl, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.build, size: 24, color: Colors.grey[400]),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comp.nom,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  'Réf: ${comp.reference ?? "N/A"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildAssemblyCard(AssemblageModel child) {
    final String rawChildUrl = child.imageUrl ?? '';
    final String correctedChildUrl = ApiConfig.fixMinioUrl(rawChildUrl);
    final hasImage = correctedChildUrl.isNotEmpty;
    final hasComps = child.composants != null && child.composants!.isNotEmpty;

    return InkWell(
      onTap: () {
        if (hasComps) {
          _showSubAssemblyDetails(child);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun composant dans ce sous-assemblage'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 70,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: hasImage
                        ? AuthenticatedImage(url: correctedChildUrl, fit: BoxFit.cover)
                        : _buildImagePlaceholder(Icons.folder_outlined, ''),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          child.nom,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasComps)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.build, size: 8, color: AppColors.orange),
                                const SizedBox(width: 2),
                                Text(
                                  '${child.composants!.length}',
                                  style: const TextStyle(
                                    fontSize: 9, 
                                    color: AppColors.orange, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.black87),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_composant',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Ajouter composant ici', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'add_composant') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddComposantScreen(
                            assemblageId: child.id,
                            assemblageNom: child.nom,
                          ),
                        ),
                      ).then((_) => _chargerArbre());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubAssemblyDetails(AssemblageModel child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  child.nom,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  'Réf: ${child.reference ?? "Non définie"}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.build, size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Composants',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${child.composants!.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: child.composants?.length ?? 0,
                    itemBuilder: (context, index) {
                      final comp = child.composants![index];
                      return _buildComposantItem(comp);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInformationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations générales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Ascenseur', widget.ascenseurNom),
                  _buildInfoRow('Total assemblages', '${_arbre.length}'),
                  _buildInfoRow('Dernière mise à jour', DateTime.now().toString().split(' ')[0]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Assemblages', _arbre.length, Icons.folder),
                  _buildStatRow('Composants', _countComposants(), Icons.settings),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.orange, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  int _countComposants() {
    int count = 0;
    void countRecursive(List<AssemblageModel> nodes) {
      for (var node in nodes) {
        if (node.composants != null) count += node.composants!.length;
        if (node.sousAssemblages != null && node.sousAssemblages!.isNotEmpty) {
          countRecursive(node.sousAssemblages!);
        }
      }
    }
    countRecursive(_arbre);
    return count;
  }
}

class AuthenticatedImage extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const AuthenticatedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int? _statusCode;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {
          'Host': 'localhost:9000',
        },
      );

      _statusCode = response.statusCode;

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Données vides';
              _isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Erreur HTTP $_statusCode';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Exception: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)),
      );
    }
    
    if (_hasError || _imageBytes == null) {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text('Erreur', style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text('Erreur affichage', style: TextStyle(color: Colors.red, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}
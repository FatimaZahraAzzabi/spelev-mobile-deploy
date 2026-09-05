// lib/screens/shared/profil_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../config/api_config.dart';
import '../../models/profil_model.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import 'edit_profil_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _service = ProfilService();
  final _storage = const FlutterSecureStorage();
  ProfilModel? _profil;
  bool _isLoading = true;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil({bool clearCache = false}) async {
    setState(() => _isLoading = true);
    if (clearCache) {
      painting.PaintingBinding.instance.imageCache.clear();
      painting.PaintingBinding.instance.imageCache.clearLiveImages();
      setState(() => _refreshKey++);
    }
    
    try {
      final profil = await _service.getProfil();
      
      // Mettre à jour le stockage local pour que le Drawer se mette à jour instantanément
      final oldUserStr = await _storage.read(key: 'user_data');
      if (oldUserStr != null) {
        final Map<String, dynamic> userData = jsonDecode(oldUserStr);
        userData['nom'] = profil.nom;
        userData['prenom'] = profil.prenom;
        userData['photoUrl'] = profil.photoUrl;
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
      }
      
      if (mounted) setState(() => _profil = profil);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEdit() async {
    if (_profil == null) return;
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilScreen(profil: _profil!)));
    if (result == true) _loadProfil(clearCache: true);
  }

  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // drawer: TonDrawerDynamique, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Mon Profil', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.orange), onPressed: () => _loadProfil(clearCache: true)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _profil == null
              ? const Center(child: Text('Impossible de charger le profil'))
              : _buildBody(_profil!),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: _openEdit,
        icon: const Icon(Icons.edit),
        label: const Text('Modifier'),
      ),
    );
  }

  Widget _buildBody(ProfilModel profil) {
    final aPhoto = profil.photoUrl != null && profil.photoUrl!.isNotEmpty;
    final isTechnicien = profil.role == 'TECHNICIEN';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ProfileAvatar(
                    initiale: (profil.prenom ?? 'U')[0].toUpperCase(),
                    hasPhoto: aPhoto,
                    refreshKey: _refreshKey,
                  ),
                  const SizedBox(height: 16),
                  Text(profil.nomComplet, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text(profil.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(profil.role?.replaceAll('_', ' ') ?? 'Utilisateur', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.orange)),
                  ),
                  if (isTechnicien && profil.specialite != null && profil.specialite!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(profil.specialite!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 16),
                  _infoRow(Icons.person, 'Prénom', profil.prenom ?? 'Non renseigné'),
                  _infoRow(Icons.person_outline, 'Nom', profil.nom ?? 'Non renseigné'),
                  _infoRow(Icons.email, 'Email', profil.email ?? 'Non renseigné'),
                  _infoRow(Icons.phone, 'Téléphone', profil.telephone ?? 'Non renseigné'),
                  if (profil.nomEntreprise != null && profil.nomEntreprise!.isNotEmpty)
                    _infoRow(Icons.business, 'Entreprise', profil.nomEntreprise!),
                  if (profil.adresse != null && profil.adresse!.isNotEmpty)
                    _infoRow(Icons.location_on, 'Adresse', profil.adresse!),
                  if (isTechnicien && profil.specialite != null && profil.specialite!.isNotEmpty)
                    _infoRow(Icons.build, 'Spécialité', profil.specialite!),
                  _infoRow(Icons.check_circle, 'Statut', profil.actif == true ? 'Actif ✓' : 'Inactif', valueColor: profil.actif == true ? Colors.green : Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
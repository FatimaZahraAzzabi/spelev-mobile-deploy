// lib/screens/shared/edit_profil_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../config/api_config.dart';
import '../../models/profil_model.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
class EditProfilScreen extends StatefulWidget {
  final ProfilModel profil;
  const EditProfilScreen({super.key, required this.profil});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfilService();
  final _picker = ImagePicker();
  final _storage = const FlutterSecureStorage();

  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _entrepriseController;
  late final TextEditingController _adresseController;
  late final TextEditingController _specialiteController;

  File? _newPhotoFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.profil.nom ?? '');
    _prenomController = TextEditingController(text: widget.profil.prenom ?? '');
    _telephoneController = TextEditingController(text: widget.profil.telephone ?? '');
    _entrepriseController = TextEditingController(text: widget.profil.nomEntreprise ?? '');
    _adresseController = TextEditingController(text: widget.profil.adresse ?? '');
    _specialiteController = TextEditingController(text: widget.profil.specialite ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose(); _prenomController.dispose(); _telephoneController.dispose();
    _entrepriseController.dispose(); _adresseController.dispose(); _specialiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 800, maxHeight: 800);
    if (picked != null) setState(() => _newPhotoFile = File(picked.path));
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Changer la photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.photo_library, color: AppColors.orange), title: const Text('Galerie'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ListTile(leading: const Icon(Icons.camera_alt, color: AppColors.orange), title: const Text('Caméra'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      ProfilModel? updatedProfil;
      if (_newPhotoFile != null) {
        updatedProfil = await _service.modifierPhoto(_newPhotoFile!.path);
      }

      final textData = await _service.modifierProfil({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        'nomEntreprise': _entrepriseController.text.trim().isEmpty ? null : _entrepriseController.text.trim(),
        'adresse': _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        'specialite': _specialiteController.text.trim().isEmpty ? null : _specialiteController.text.trim(),
      });

      final finalProfil = updatedProfil ?? textData;

      // Mise à jour du stockage local
      final oldUserStr = await _storage.read(key: 'user_data');
      if (oldUserStr != null) {
        final Map<String, dynamic> userData = jsonDecode(oldUserStr);
        userData['nom'] = finalProfil.nom;
        userData['prenom'] = finalProfil.prenom;
        userData['telephone'] = finalProfil.telephone;
        userData['nomEntreprise'] = finalProfil.nomEntreprise;
        userData['adresse'] = finalProfil.adresse;
        userData['specialite'] = finalProfil.specialite;
        userData['photoUrl'] = finalProfil.photoUrl;
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aPhoto = widget.profil.photoUrl != null && widget.profil.photoUrl!.isNotEmpty;
    final isTechnicien = widget.profil.role == 'TECHNICIEN';
    final isClientOrResp = widget.profil.role == 'CLIENT' || widget.profil.role == 'RESPONSABLE_MAINTENANCE';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Modifier mon profil', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ProfileAvatar(initiale: (widget.profil.prenom ?? 'U')[0].toUpperCase(), hasPhoto: aPhoto || _newPhotoFile != null, refreshKey: _newPhotoFile != null ? 1 : 0), // Astuce pour forcer le rebuild si nouvelle photo
                            // Note: Pour une vraie prévisualisation de File, tu peux garder ton ancienne logique _buildAvatar ici si tu préfères.
                            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(onPressed: _showPhotoOptions, icon: const Icon(Icons.edit, size: 16), label: const Text('Changer la photo'), style: TextButton.styleFrom(foregroundColor: AppColors.orange)),
                      if (_newPhotoFile != null) const Text('Nouvelle photo sélectionnée ✓', style: TextStyle(fontSize: 12, color: Colors.green)),
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
                      const Text('Informations personnelles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 16),
                      TextFormField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                      const SizedBox(height: 12),
                      TextFormField(controller: _telephoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                      
                      if (isClientOrResp || widget.profil.role == 'ADMINISTRATEUR') ...[
                        const SizedBox(height: 12),
                        TextFormField(controller: _entrepriseController, decoration: const InputDecoration(labelText: 'Entreprise', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
                      ],

                      if (isTechnicien) ...[
                        const SizedBox(height: 12),
                        TextFormField(controller: _specialiteController, decoration: const InputDecoration(labelText: 'Spécialité', border: OutlineInputBorder(), prefixIcon: Icon(Icons.build))),
                      ],

                      const SizedBox(height: 12),
                      TextFormField(controller: _adresseController, maxLines: 2, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.email, size: 18, color: Colors.black45),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Email (non modifiable)', style: TextStyle(fontSize: 11, color: Colors.black45)),
                                  Text(widget.profil.email ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _isLoading ? null : () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: _isLoading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
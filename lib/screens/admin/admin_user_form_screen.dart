import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_drawer.dart';
import '../../theme/app_theme.dart';
import '../../services/utilisateur_service.dart';
import '../../models/utilisateur_model.dart';
import '../../config/api_config.dart';
import '../../services/api_helper.dart';

class AdminUserFormScreen extends StatefulWidget {
  final UtilisateurModel? utilisateur;

  const AdminUserFormScreen({super.key, this.utilisateur});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UtilisateurService();
  bool _isLoading = false;

  bool get _isEditMode => widget.utilisateur != null;

  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _entrepriseController;
  late final TextEditingController _specialiteController;
  late final TextEditingController _adresseController;

  String? _selectedType;
  bool _isActive = true;

  List<Map<String, dynamic>> _allParcs = [];
  List<int> _selectedParcIds = [];
  bool _isLoadingParcs = false;
  bool _parcsManuallyModified = false; 
  @override
  void initState() {
    super.initState();
    final u = widget.utilisateur;
    _nomController = TextEditingController(text: u?.nom ?? '');
    _prenomController = TextEditingController(text: u?.prenom ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _telephoneController = TextEditingController(text: u?.telephone ?? '');
    _passwordController = TextEditingController(text: '');
    _entrepriseController = TextEditingController(text: u?.nomEntreprise ?? '');
    _specialiteController = TextEditingController(text: u?.specialite ?? '');
    _adresseController = TextEditingController(text: u?.adresse ?? '');
    _selectedType = u?.type;
    _isActive = u?.actif ?? true;
    _selectedParcIds = u?.parcIds ?? []; 

    _loadParcs();
  }

  Future<void> _loadParcs() async {
    setState(() => _isLoadingParcs = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/parcs'),
        headers: await ApiHelper.headers(),
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        setState(() {
          _allParcs = data.map((e) => {'id': e['id'], 'nom': e['nom']}).toList();
          _isLoadingParcs = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingParcs = false);
      debugPrint('Erreur chargement parcs: $e');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _entrepriseController.dispose();
    _specialiteController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
 
    if (_selectedType == 'TECHNICIEN' && _selectedParcIds.isEmpty && (!_isEditMode || _parcsManuallyModified)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez assigner au moins un parc au technicien.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        final dto = UtilisateurUpdateDTO(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim(),
          type: _selectedType!,
          actif: _isActive,
          nomEntreprise: _entrepriseController.text.trim().isEmpty ? null : _entrepriseController.text.trim(),
          specialite: _specialiteController.text.trim().isEmpty ? null : _specialiteController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          parcIds: (_selectedType == 'TECHNICIEN' && _parcsManuallyModified) ? _selectedParcIds : null,
        );
        await _service.updateUtilisateur(widget.utilisateur!.id, dto);
      } else {
        final dto = UtilisateurCreateDTO(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim(),
          motDePasse: _passwordController.text.trim(),
          type: _selectedType!,
          nomEntreprise: _entrepriseController.text.trim().isEmpty ? null : _entrepriseController.text.trim(),
          specialite: _specialiteController.text.trim().isEmpty ? null : _specialiteController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          parcIds: _selectedType == 'TECHNICIEN' ? _selectedParcIds : null,
        );
        await _service.createUtilisateur(dto);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Utilisateur modifié avec succès !' : 'Utilisateur créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AdminDrawer(currentRoute: '/admin-users'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _isEditMode ? 'Modifier l\'utilisateur' : 'Créer un utilisateur',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isEditMode ? 'Modifier les informations' : 'Créer un utilisateur',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Nom et Prénom
                      if (constraints.maxWidth < 600) ...[
                        TextFormField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      
                      TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      }),
                      const SizedBox(height: 12),
                      
                      if (constraints.maxWidth < 600) ...[
                        TextFormField(controller: _telephoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'ADMINISTRATEUR', child: Text('Admin')),
                            DropdownMenuItem(value: 'TECHNICIEN', child: Text('Technicien')),
                            DropdownMenuItem(value: 'RESPONSABLE_MAINTENANCE', child: Text('Resp. Maint.')),
                            DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                          ],
                          onChanged: !_isEditMode ? (value) => setState(() => _selectedType = value) : null,
                          validator: (value) => value == null ? 'Requis' : null,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _telephoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
                                items: const [
                                  DropdownMenuItem(value: 'ADMINISTRATEUR', child: Text('Admin')),
                                  DropdownMenuItem(value: 'TECHNICIEN', child: Text('Technicien')),
                                  DropdownMenuItem(value: 'RESPONSABLE_MAINTENANCE', child: Text('Resp. Maint.')),
                                  DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                                ],
                                onChanged: !_isEditMode ? (value) => setState(() => _selectedType = value) : null,
                                validator: (value) => value == null ? 'Requis' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      if (_isEditMode) ...[
                        Card(
                          color: _isActive ? Colors.green[50] : Colors.red[50],
                          child: SwitchListTile(
                            title: const Text('Compte actif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(_isActive ? 'L\'utilisateur peut se connecter' : 'L\'utilisateur ne peut pas se connecter', style: TextStyle(fontSize: 12)),
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value),
                            activeColor: Colors.green,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (!_isEditMode) ...[
                        TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (v.length < 6) return 'Minimum 6 caractères';
                          return null;
                        }),
                        const SizedBox(height: 12),
                      ],

                      if (_selectedType == 'TECHNICIEN') ...[
                        const Divider(),
                        Row(
                          children: [
                            const Text('Parcs assignés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (_isEditMode) const Text(' (optionnel)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingParcs)
                          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                        else if (_allParcs.isEmpty)
                          const Text('Aucun parc disponible. Créez d\'abord des parcs.', style: TextStyle(color: Colors.red, fontSize: 12))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allParcs.map((parc) {
                              final isSelected = _selectedParcIds.contains(parc['id']);
                              return FilterChip(
                                label: Text(parc['nom']),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _parcsManuallyModified = true; 
                                    if (selected) {
                                      _selectedParcIds.add(parc['id']);
                                    } else {
                                      _selectedParcIds.remove(parc['id']);
                                    }
                                  });
                                },
                                selectedColor: AppColors.orange.withOpacity(0.2),
                                checkmarkColor: AppColors.orange,
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 12),
                      ],

                      if (constraints.maxWidth < 600) ...[
                        TextFormField(controller: _entrepriseController, decoration: const InputDecoration(labelText: 'Entreprise', border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _specialiteController, decoration: const InputDecoration(labelText: 'Spécialité', border: OutlineInputBorder())),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _entrepriseController, decoration: const InputDecoration(labelText: 'Entreprise', border: OutlineInputBorder()))),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _specialiteController, decoration: const InputDecoration(labelText: 'Spécialité', border: OutlineInputBorder()))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      
                      TextFormField(controller: _adresseController, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text('Annuler', style: TextStyle(color: Colors.black87, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(_isEditMode ? 'Enregistrer' : 'Créer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../services/composant_service.dart';
import '../../theme/app_theme.dart';

class AddComposantScreen extends StatefulWidget {
  final int assemblageId;
  final String assemblageNom;

  const AddComposantScreen({
    super.key,
    required this.assemblageId,
    required this.assemblageNom,
  });

  @override
  State<AddComposantScreen> createState() => _AddComposantScreenState();
}

class _AddComposantScreenState extends State<AddComposantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ComposantService();

  final _nomController = TextEditingController();
  final _referenceController = TextEditingController();
  final _fabricantController = TextEditingController();

  String? _selectedType;
  bool _isLoading = false;

  final List<String> _types = [
    'MOTEUR',
    'FREIN',
    'REDUCTEUR',
    'POULIE',
    'CABLE_SUSPENSION',
    'PORTE_CABINE',
    'AFFICHEUR',
    'BOITE_BOUTONS',
    'ECLAIRAGE',
    'AUTRE',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _referenceController.dispose();
    _fabricantController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dto = {
        'nom': _nomController.text.trim(),
        'reference': _referenceController.text.trim(),
        'type': _selectedType,
        'fabricant': _fabricantController.text.trim().isEmpty 
            ? null 
            : _fabricantController.text.trim(),
        'assemblageId': widget.assemblageId,
      };

      await _service.creer(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Composant créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Nouveau composant',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assemblage: ${widget.assemblageNom}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Nom
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          hintText: 'Ex: Moteur principal',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => 
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Référence
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Référence *',
                          hintText: 'Ex: MOT-2026-001',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => 
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                        validator: (v) => 
                            (v == null) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fabricant
                      TextFormField(
                        controller: _fabricantController,
                        decoration: const InputDecoration(
                          labelText: 'Fabricant',
                          hintText: 'Ex: Otis',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Créer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
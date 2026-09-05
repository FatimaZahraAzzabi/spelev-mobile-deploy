import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/assemblage_service.dart';
import '../../models/assemblage_model.dart';
import '../../theme/app_theme.dart';

class AddAssemblageScreen extends StatefulWidget {
  final int ascenseurId;
  final String ascenseurNom;
  final int? parentId;

  const AddAssemblageScreen({
    super.key,
    required this.ascenseurId,
    required this.ascenseurNom,
    this.parentId,
  });

  @override
  State<AddAssemblageScreen> createState() => _AddAssemblageScreenState();
}

class _AddAssemblageScreenState extends State<AddAssemblageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AssemblageService();
  final _picker = ImagePicker();

  final _nomController = TextEditingController();
  final _referenceController = TextEditingController();
  final _fabricantController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedType;
  DateTime? _dateInstallation;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _types = [
    'CABINE',
    'GAINE',
    'MACHINERIE',
    'PORTE',
    'ELECTRIQUE',
    'AUTRE',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _referenceController.dispose();
    _fabricantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateInstallation = picked;
      });
    }
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
        'dateInstallation': _dateInstallation?.toIso8601String().split('T').first,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'ascenseurId': widget.ascenseurId,
        if (widget.parentId != null) 'parentId': widget.parentId,
      };

      await _service.creer(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assemblage créé avec succès'),
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
        title: Text(
          widget.parentId != null 
              ? 'Ajouter un sous-assemblage' 
              : 'Nouvel assemblage',
          style: const TextStyle(
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
                      const Text(
                        'Informations générales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Nom
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          hintText: 'Ex: Cabine',
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
                          hintText: 'Ex: REF-2026-001',
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
                      const SizedBox(height: 16),

                      // Date d'installation
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Date d'installation",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _dateInstallation != null
                                ? '${_dateInstallation!.day.toString().padLeft(2, '0')}/${_dateInstallation!.month.toString().padLeft(2, '0')}/${_dateInstallation!.year}'
                                : 'jj/mm/aaaa',
                            style: TextStyle(
                              color: _dateInstallation != null 
                                  ? Colors.black 
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
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
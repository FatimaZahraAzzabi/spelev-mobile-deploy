import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/tache_service.dart';
import '../../services/ascenseur_service.dart';
import '../../services/utilisateur_service.dart';
import '../../models/ascenseur_model.dart';
import '../../models/utilisateur_model.dart';

class NouvelleTacheScreen extends StatefulWidget {
   final bool isEmbedded; 

  const NouvelleTacheScreen({super.key, this.isEmbedded = false});
  @override
  State<NouvelleTacheScreen> createState() => _NouvelleTacheScreenState();
}

class _NouvelleTacheScreenState extends State<NouvelleTacheScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tacheService = TacheService();
  final _ascenseurService = AscenseurService();
  final _utilisateurService = UtilisateurService();
  
  bool _isLoading = false;
  bool _loadingData = false;

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedType;
  String? _selectedPriorite;
  DateTime? _dateEcheance;
  AscenseurModel? _selectedAscenseur;
  UtilisateurModel? _selectedResponsable;

  List<AscenseurModel> _ascenseurs = [];
  List<UtilisateurModel> _responsables = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final ascenseurs = await _ascenseurService.getAscenseurs();
      final utilisateurs = await _utilisateurService.getResponsables();
      setState(() {
        _ascenseurs = ascenseurs;
        _responsables = utilisateurs;
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateEcheance = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAscenseur == null || _selectedResponsable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un ascenseur et un responsable'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = {
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'priorite': _selectedPriorite,
        'dateEcheance': _dateEcheance?.toIso8601String().split('T').first,
        'ascenseurId': _selectedAscenseur!.id,
        'responsableId': _selectedResponsable!.id,
      };

      await _tacheService.createTache(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche créée avec succès'), backgroundColor: Colors.green),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Nouvelle tâche',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    TextFormField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de la tâche *',
                        hintText: 'Ex: Maintenance mensuelle ascenseur Bloc A',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décrivez la tâche à effectuer...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type de tâche
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de tâche *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PREVENTIF', child: Text('Préventif (Maintenance planifiée)')),
                        DropdownMenuItem(value: 'CORRECTIF', child: Text('Correctif (Suite à une panne)')),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Priorité
                    DropdownButtonFormField<String>(
                      value: _selectedPriorite,
                      decoration: const InputDecoration(
                        labelText: 'Priorité *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BASSE', child: Text('Basse')),
                        DropdownMenuItem(value: 'MOYENNE', child: Text('Moyenne')),
                        DropdownMenuItem(value: 'HAUTE', child: Text('Haute')),
                        DropdownMenuItem(value: 'URGENTE', child: Text('Urgente')),
                      ],
                      onChanged: (value) => setState(() => _selectedPriorite = value),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date d'échéance
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'échéance',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dateEcheance != null
                              ? '${_dateEcheance!.day}/${_dateEcheance!.month}/${_dateEcheance!.year}'
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _dateEcheance != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sélection Ascenseur
                    DropdownButtonFormField<AscenseurModel>(
                      value: _selectedAscenseur,
                      decoration: const InputDecoration(
                        labelText: 'Ascenseur concerné *',
                        border: OutlineInputBorder(),
                      ),
                      items: _ascenseurs.map((asc) {
                        return DropdownMenuItem(
                          value: asc,
                          child: Text(
                            '${asc.nom} - ${asc.siteAdresse ?? "Site inconnu"}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedAscenseur = value),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Sélection Responsable
                    DropdownButtonFormField<UtilisateurModel>(
                      value: _selectedResponsable,
                      decoration: const InputDecoration(
                        labelText: 'Responsable assigné *',
                        border: OutlineInputBorder(),
                      ),
                      items: _responsables.map((resp) {
                        return DropdownMenuItem(
                          value: resp,
                          child: Text('${resp.prenom} ${resp.nom}'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedResponsable = value),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Créer la tâche', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
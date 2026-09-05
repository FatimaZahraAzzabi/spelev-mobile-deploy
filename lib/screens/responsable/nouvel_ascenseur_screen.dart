import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'responsable_drawer.dart';
import '../../theme/app_theme.dart';
import '../../services/ascenseur_service.dart';
import '../../models/ascenseur_model.dart';
import '../../models/utilisateur_model.dart';
import '../../models/site_model.dart';

class NouvelAscenseurScreen extends StatefulWidget {
  final AscenseurModel? ascenseur;

  const NouvelAscenseurScreen({super.key, this.ascenseur});

  @override
  State<NouvelAscenseurScreen> createState() => _NouvelAscenseurScreenState();
}

class _NouvelAscenseurScreenState extends State<NouvelAscenseurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AscenseurService();
  bool _isLoading = false;

  // Contrôleurs
  final _nomController = TextEditingController();
  final _marqueController = TextEditingController();
  final _fabricantController = TextEditingController();
  final _modeleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _codeBarreController = TextEditingController();
  final _puissanceController = TextEditingController();
  final _coutAcquisitionController = TextEditingController();
  final _nombreEtagesController = TextEditingController();
  final _capaciteController = TextEditingController();
  final _chargeMaxController = TextEditingController();
  final _vitesseController = TextEditingController();
  final _informationsSuppController = TextEditingController();

  String? _selectedType;
  DateTime? _dateMiseEnService;
  DateTime? _dateExpirationGarantie;
  UtilisateurModel? _selectedClient;
  SiteModel? _selectedSite;
  List<UtilisateurModel> _clients = [];
  List<SiteModel> _sites = [];
  bool _loadingClients = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadClients().then((_) {
      if (widget.ascenseur != null) {
        _prefillData();
      }
    });
  }

  void _prefillData() {
    final asc = widget.ascenseur!;

    _nomController.text = asc.nom;
    _marqueController.text = asc.marque ?? '';
    _fabricantController.text = asc.fabricant ?? '';
    _modeleController.text = asc.modele ?? '';
    _descriptionController.text = asc.description ?? '';
    _numeroSerieController.text = asc.numeroSerie ?? '';
    _codeBarreController.text = asc.codeBarre ?? '';
    _puissanceController.text = asc.puissance ?? '';
    _coutAcquisitionController.text = asc.coutAcquisition?.toString() ?? '';
    _nombreEtagesController.text = asc.nombreEtages?.toString() ?? '';
    _capaciteController.text = asc.capacitePersonnes?.toString() ?? '';
    _chargeMaxController.text = asc.chargeMaxKg?.toString() ?? '';
    _vitesseController.text = asc.vitesse?.toString() ?? '';

    _dateMiseEnService = asc.dateMiseEnService;
    _dateExpirationGarantie = asc.dateExpirationGarantie;
    _selectedType = asc.type;

    // Sélection du client
    if (asc.clientId != null) {
      final clientsCorrespondants =
          _clients.where((c) => c.id == asc.clientId).toList();

      if (clientsCorrespondants.isNotEmpty) {
        _selectedClient = clientsCorrespondants.first;

        _loadSites(_selectedClient!.id).then((_) {
          if (!mounted) return;

          if (asc.siteId != null) {
            final sitesCorrespondants =
                _sites.where((s) => s.id == asc.siteId).toList();

            if (sitesCorrespondants.isNotEmpty) {
              setState(() {
                _selectedSite = sitesCorrespondants.first;
                _isInitialized = true;
              });
            }
          } else {
            setState(() {
              _isInitialized = true;
            });
          }
        });
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadClients() async {
    setState(() => _loadingClients = true);
    try {
      final clients = await _service.getClients();
      setState(() {
        _clients = clients;
        _loadingClients = false;
      });
    } catch (e) {
      setState(() => _loadingClients = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement clients: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadSites(int clientId) async {
    setState(() => _loadingClients = true);
    try {
      final sites = await _service.getSitesByClient(clientId);
      setState(() {
        _sites = sites;
        if (widget.ascenseur == null) _selectedSite = null; 
        _loadingClients = false;
      });
    } catch (e) {
      setState(() => _loadingClients = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement sites: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showClientPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un client'),
        content: SizedBox(
          width: double.maxFinite,
          child: _loadingClients
              ? const Center(child: CircularProgressIndicator())
              : _clients.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucun client disponible'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _clients.length,
                      itemBuilder: (context, index) {
                        final client = _clients[index];
                        return ListTile(
                          title: Text('${client.prenom} ${client.nom}'),
                          subtitle: client.nomEntreprise != null && client.nomEntreprise!.isNotEmpty 
                              ? Text(client.nomEntreprise!) 
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedClient = client;
                              _selectedSite = null;
                            });
                            _loadSites(client.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showSitePicker() {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un client'), 
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un site'),
        content: SizedBox(
          width: double.maxFinite,
          child: _loadingClients
              ? const Center(child: CircularProgressIndicator())
              : _sites.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20), 
                      child: Text('Aucun site disponible pour ce client'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sites.length,
                      itemBuilder: (context, index) {
                        final site = _sites[index];
                        return ListTile(
                          title: Text(site.adresse),
                          subtitle: site.ville != null ? Text('Ville: ${site.ville!.nom}') : null,
                          onTap: () {
                            setState(() => _selectedSite = site);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isMiseEnService) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMiseEnService 
          ? (_dateMiseEnService ?? DateTime.now())
          : (_dateExpirationGarantie ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isMiseEnService) {
          _dateMiseEnService = picked;
        } else {
          _dateExpirationGarantie = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.ascenseur != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-ascenseur-list'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          isEditMode ? 'Modifier l\'ascenseur' : 'Nouvel ascenseur',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RATTACHEMENT
              _buildSectionTitle('RATTACHEMENT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _showClientPicker,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Client *', 
                          border: OutlineInputBorder(), 
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _selectedClient != null 
                              ? '${_selectedClient!.prenom} ${_selectedClient!.nom}'
                              : '-- Sélectionner un client --',
                          style: TextStyle(
                            color: _selectedClient != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _showSitePicker,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Site *', 
                          border: OutlineInputBorder(), 
                          suffixIcon: Icon(Icons.add_circle, color: AppColors.orange),
                        ),
                        child: Text(
                          _selectedSite != null 
                              ? _selectedSite!.adresse 
                              : '-- Sélectionner un site --',
                          style: TextStyle(
                            color: _selectedSite != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // INFORMATIONS GÉNÉRALES
              _buildSectionTitle('INFORMATIONS GÉNÉRALES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *', 
                        hintText: 'Ex: Ascenseur Bloc A', 
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _marqueController,
                      decoration: const InputDecoration(
                        labelText: 'Marque *', 
                        hintText: 'Ex: Otis', 
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fabricantController,
                      decoration: const InputDecoration(
                        labelText: 'Fabricant *', 
                        hintText: 'Ex: Otis France', 
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _modeleController,
                      decoration: const InputDecoration(
                        labelText: 'Modèle', 
                        hintText: 'Ex: Gen2', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coutAcquisitionController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coût d\'acquisition (DH)', 
                        hintText: 'Ex: 150000', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type', 
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'HYDRAULIQUE', child: Text('Hydraulique')),
                        DropdownMenuItem(value: 'TRACTION', child: Text('Traction')),
                        DropdownMenuItem(value: 'MRL', child: Text('MRL (Sans salle des machines)')),
                        DropdownMenuItem(value: 'PNEUMATIQUE', child: Text('Pneumatique')),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // IDENTIFICATION
              _buildSectionTitle('IDENTIFICATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numeroSerieController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de série', 
                        hintText: 'Ex: SN-2026-001', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codeBarreController,
                      decoration: const InputDecoration(
                        labelText: 'Code-barre', 
                        hintText: 'Ex: CB-001', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // CARACTÉRISTIQUES TECHNIQUES
              _buildSectionTitle('CARACTÉRISTIQUES TECHNIQUES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreEtagesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Nombre d'étages", 
                        hintText: 'Ex: 10', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capaciteController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacité (personnes)', 
                        hintText: 'Ex: 8', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _chargeMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Charge max (kg)', 
                        hintText: 'Ex: 630', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vitesseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vitesse (m/s)', 
                        hintText: 'Ex: 1.6', 
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _puissanceController,
                decoration: const InputDecoration(
                  labelText: 'Puissance', 
                  hintText: 'Ex: 15kW', 
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // DATES
              _buildSectionTitle('DATES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de mise en service', 
                          border: OutlineInputBorder(), 
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dateMiseEnService != null 
                              ? DateFormat('dd/MM/yyyy').format(_dateMiseEnService!) 
                              : 'jj/mm/aaaa',
                          style: TextStyle(
                            color: _dateMiseEnService != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Date d'expiration garantie", 
                          border: OutlineInputBorder(), 
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dateExpirationGarantie != null 
                              ? DateFormat('dd/MM/yyyy').format(_dateExpirationGarantie!) 
                              : 'jj/mm/aaaa',
                          style: TextStyle(
                            color: _dateExpirationGarantie != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description et infos supplémentaires
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description', 
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _informationsSuppController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Informations supplémentaires', 
                  border: OutlineInputBorder(),
                ),
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
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditMode ? 'Enregistrer les modifications' : 'Créer l\'ascenseur',
                              style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w700, 
        color: AppColors.navy, 
        letterSpacing: 0.5,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client'), 
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un site'), 
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = {
        'nom': _nomController.text.trim(),
        'marque': _marqueController.text.trim(),
        'fabricant': _fabricantController.text.trim(),
        'modele': _modeleController.text.trim().isEmpty ? null : _modeleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'coutAcquisition': _coutAcquisitionController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_coutAcquisitionController.text.trim()),
        'nombreEtages': _nombreEtagesController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_nombreEtagesController.text.trim()),
        'capacitePersonnes': _capaciteController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_capaciteController.text.trim()),
        'chargeMaxKg': _chargeMaxController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_chargeMaxController.text.trim()),
        'vitesse': _vitesseController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_vitesseController.text.trim()),
        'numeroSerie': _numeroSerieController.text.trim().isEmpty ? null : _numeroSerieController.text.trim(),
        'codeBarre': _codeBarreController.text.trim().isEmpty ? null : _codeBarreController.text.trim(),
        'puissance': _puissanceController.text.trim().isEmpty ? null : _puissanceController.text.trim(),
        'dateMiseEnService': _dateMiseEnService?.toIso8601String().split('T').first,
        'dateExpirationGarantie': _dateExpirationGarantie?.toIso8601String().split('T').first,
        'type': _selectedType,
        'informationsSupplementaires': _informationsSuppController.text.trim().isEmpty 
            ? null 
            : _informationsSuppController.text.trim(),
        'clientId': _selectedClient!.id,
        'siteId': _selectedSite!.id,
      };

      if (widget.ascenseur != null) {
        await _service.updateAscenseur(widget.ascenseur!.id, dto);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ascenseur modifié avec succès'), 
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); 
        }
      } else {
        await _service.createAscenseur(dto);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ascenseur créé avec succès'), 
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _marqueController.dispose();
    _fabricantController.dispose();
    _modeleController.dispose();
    _descriptionController.dispose();
    _numeroSerieController.dispose();
    _codeBarreController.dispose();
    _puissanceController.dispose();
    _coutAcquisitionController.dispose();
    _nombreEtagesController.dispose();
    _capaciteController.dispose();
    _chargeMaxController.dispose();
    _vitesseController.dispose();
    _informationsSuppController.dispose();
    super.dispose();
  }
}
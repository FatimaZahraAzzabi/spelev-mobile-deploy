import 'package:flutter/material.dart';
import 'responsable_drawer.dart'; 
import '../../theme/app_theme.dart'; 
import '../../services/site_service.dart';
import '../../models/site_model.dart';
import '../../models/utilisateur_model.dart';
import '../../models/ville_model.dart';
import '../../models/parc_model.dart'; 

class NouveauSiteScreen extends StatefulWidget {
  const NouveauSiteScreen({super.key});

  @override
  State<NouveauSiteScreen> createState() => _NouveauSiteScreenState();
}

class _NouveauSiteScreenState extends State<NouveauSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SiteService();
  bool _isLoading = false;

  final _adresseController = TextEditingController();
  final _codePostalController = TextEditingController();

  UtilisateurModel? _selectedClient;
  VilleModel? _selectedVille;
  ParcModel? _selectedParc; 

  List<UtilisateurModel> _clients = [];
  List<VilleModel> _villes = [];
  List<ParcModel> _parcs = []; 
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final clients = await _service.getClients();
      final villes = await _service.getVilles();
      final parcs = await _service.getParcs(); 
      
      setState(() {
        _clients = clients;
        _villes = villes;
        _parcs = parcs; // ✅ AJOUTÉ
        _loadingData = false;
      });
    } catch (e) {
      setState(() => _loadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement données: $e'), backgroundColor: Colors.red),
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
          child: _loadingData
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    return ListTile(
                      title: Text('${client.prenom} ${client.nom}'),
                      subtitle: Text(client.nomEntreprise ?? ''),
                      onTap: () {
                        setState(() => _selectedClient = client);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );
  }

  void _showVillePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une ville'),
        content: SizedBox(
          width: double.maxFinite,
          child: _loadingData
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _villes.length,
                  itemBuilder: (context, index) {
                    final ville = _villes[index];
                    return ListTile(
                      title: Text(ville.nom),
                      onTap: () {
                        setState(() => _selectedVille = ville);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );
  }

  void _showParcPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un parc'),
        content: SizedBox(
          width: double.maxFinite,
          child: _loadingData
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _parcs.length,
                  itemBuilder: (context, index) {
                    final parc = _parcs[index];
                    return ListTile(
                      title: Text(parc.nom),
                      onTap: () {
                        setState(() => _selectedParc = parc);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-site-list'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Nouveau site', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('RATTACHEMENT'),
              const SizedBox(height: 12),
              
              // Sélection Client
              InkWell(
                onTap: _showClientPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Client *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down)),
                  child: Text(
                    _selectedClient != null ? '${_selectedClient!.prenom} ${_selectedClient!.nom} - ${_selectedClient!.nomEntreprise ?? ""}' : '-- Sélectionner un client --',
                    style: TextStyle(color: _selectedClient != null ? Colors.black : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Sélection Ville
              InkWell(
                onTap: _showVillePicker,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ville *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down)),
                  child: Text(
                    _selectedVille != null ? _selectedVille!.nom : '-- Sélectionner une ville --',
                    style: TextStyle(color: _selectedVille != null ? Colors.black : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ AJOUTÉ : Sélection Parc
              InkWell(
                onTap: _showParcPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Parc *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down)),
                  child: Text(
                    _selectedParc != null ? _selectedParc!.nom : '-- Sélectionner un parc --',
                    style: TextStyle(color: _selectedParc != null ? Colors.black : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('INFORMATIONS DU SITE'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: 'Adresse *', hintText: 'Ex: 123 Rue Mohammed V', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codePostalController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Code postal', hintText: 'Ex: 20000', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Annuler', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Créer le site', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy, letterSpacing: 0.5));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un client'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedVille == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une ville'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedParc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un parc'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = {
        'adresse': _adresseController.text.trim(),
        'codePostal': _codePostalController.text.trim().isEmpty ? null : _codePostalController.text.trim(),
        'clientId': _selectedClient!.id,
        'villeId': _selectedVille!.id,
        'parcId': _selectedParc!.id, 
      };

      await _service.createSite(dto);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site créé avec succès'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _adresseController.dispose();
    _codePostalController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';

import '../../services/demande_maintenance_service.dart';
import '../../services/utilisateur_service.dart'; 
import '../../models/demande_maintenance_model.dart';
import '../../models/utilisateur_model.dart';    
import '../../models/site_model.dart';
import '../../theme/app_theme.dart';
import '../../services/bon_travail_service.dart';
import '../../services/site_service.dart';
import '../../models/bon_travail_create_model.dart';
import 'responsable_drawer.dart';

class NouveauBonTravailScreen extends StatefulWidget {
  final DemandeMaintenanceModel? demande;
  final bool isEvaluation;

  const NouveauBonTravailScreen({
    super.key,
    this.demande,
    this.isEvaluation = false,
  });

  @override
  State<NouveauBonTravailScreen> createState() =>
      _NouveauBonTravailScreenState();
}

class _NouveauBonTravailScreenState extends State<NouveauBonTravailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bonTravailService = BonTravailService();
  final _demandeService = DemandeMaintenanceService();
  final _siteService = SiteService();
  final _utilisateurService = UtilisateurService(); 

  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  DateTime? _dateIntervention;
  TimeOfDay? _heureIntervention;

  int _dureeMinutes = 120;

  int? _technicienResponsableId;

  List<Map<String, dynamic>> _techniciensDisponibles = [];

  bool _isLoadingTechniciens = false;
  bool _hasSearchedTechniciens = false;

  // ============================================================
  // SITES
  // ============================================================

  List<SiteModel> _sites = [];
  int? _selectedSiteId;
  bool _isLoadingSites = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEvaluation || (widget.demande?.isEvaluation ?? false)) {
      _initialiserEvaluation();
    } else {
      _initialiserDemandeMaintenance();
    }
  }

  // ============================================================
  // INITIALISATION DEMANDE CLASSIQUE
  // ============================================================

  void _initialiserDemandeMaintenance() {
    if (widget.demande != null) {
      _descriptionController.text = widget.demande!.description ?? '';
    }
    _loadSites(); 
  }

  // ============================================================
  // INITIALISATION ÉVALUATION
  // ============================================================

  void _initialiserEvaluation() {
    _loadSites(); 
    
    if (widget.demande != null) {
      final demande = widget.demande!;
      _descriptionController.text =
          'ÉVALUATION NOUVELLE INSTALLATION\n'
          'Client : ${demande.clientNomComplet}\n'
          'Adresse : ${demande.adresseSaisie ?? 'À définir'}\n'
          'Ville : ${demande.villeSaisie ?? 'À définir'}\n'
          '--------------------------------\n'
          '${demande.description ?? ''}';
    }
  }

  // ============================================================
  // CHARGER LES SITES
  // ============================================================

  Future<void> _loadSites() async {
    final bool estEvaluation = widget.isEvaluation || (widget.demande?.isEvaluation ?? false);
    
    setState(() {
      _isLoadingSites = true;
    });

    try {
      List<SiteModel> sites;

      if (estEvaluation) {
        sites = await _siteService.getSites();
        debugPrint(' Évaluation : ${sites.length} sites chargés (tous)');
      } else {
        if (widget.demande?.clientId == null) {
          sites = [];
        } else {
          sites = await _siteService.getSitesByClient(widget.demande!.clientId!);
          debugPrint('📍 Maintenance : ${sites.length} sites chargés (client uniquement)');
        }
      }

      if (!mounted) return;

      setState(() {
        _sites = sites;
        _isLoadingSites = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingSites = false; });
      debugPrint('❌ Erreur chargement sites : $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement des sites : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================
  // CRÉER UN NOUVEAU SITE
  // ============================================================

  Future<void> _creerNouveauSite() async {
    final result = await Navigator.pushNamed(context, '/responsable-nouveau-site');
    
    if (result == true) {
      await _loadSites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site créé avec succès'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() {
      _dateIntervention = picked;
      _technicienResponsableId = null;
      _hasSearchedTechniciens = false;
      _techniciensDisponibles.clear();
    });
  }

  // ============================================================
  // HEURE
  // ============================================================

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    setState(() {
      _heureIntervention = picked;
      _technicienResponsableId = null;
      _hasSearchedTechniciens = false;
      _techniciensDisponibles.clear();
    });
  }

  // ============================================================
  // CHARGER TECHNICIENS PAR PARC (ÉVALUATION)
  // ============================================================

  Future<void> _chargerTechniciensParParc() async {
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un site.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingTechniciens = true;
      _hasSearchedTechniciens = true;
      _technicienResponsableId = null;
    });

    try {
      final allTechniciens = await _utilisateurService.getTechniciens();

      final selectedSite = _sites.firstWhere(
        (s) => s.id == _selectedSiteId,
        orElse: () => SiteModel(id: 0, adresse: 'Inconnu'),
      );
      
      final int? siteParcId = selectedSite.parc?.id;

      final liste = allTechniciens.where((t) {
        if (siteParcId == null) return true; 
        return t.parcIds != null && t.parcIds!.contains(siteParcId);
      }).map((t) => {
            'id': t.id,
            'nom': t.nom,
            'prenom': t.prenom,
            'specialite': t.specialite ?? '',
          }).toList();

      setState(() {
        _techniciensDisponibles = liste;
        _isLoadingTechniciens = false;
      });

      debugPrint('👷 Techniciens du parc trouvés : ${_techniciensDisponibles.length}');

      if (_techniciensDisponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(siteParcId == null 
                ? 'Aucun technicien enregistré dans le système.' 
                : 'Aucun technicien ne couvre ce parc spécifique.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingTechniciens = false; });
      debugPrint('❌ Erreur chargement techniciens : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // CHARGER TECHNICIENS DISPONIBLES (MAINTENANCE)
  // ============================================================

  Future<void> _chargerTechniciensDisponibles() async {
    final bool estEvaluation = widget.isEvaluation || (widget.demande?.isEvaluation ?? false);

    if (estEvaluation) {
      await _chargerTechniciensParParc(); 
      return;
    }

    if (_dateIntervention == null || _heureIntervention == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord sélectionner la date et l\'heure.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final ascenseurId = widget.demande?.ascenseurId;
    if (ascenseurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : Cette demande (N°${widget.demande?.id}) ne contient pas d\'ascenseur.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoadingTechniciens = true;
      _hasSearchedTechniciens = true;
      _technicienResponsableId = null;
    });

    try {
      final debut = DateTime(
        _dateIntervention!.year, _dateIntervention!.month, _dateIntervention!.day,
        _heureIntervention!.hour, _heureIntervention!.minute,
      );

      final data = await _bonTravailService.getTechniciensDisponibles(
        ascenseurId: ascenseurId,
        debut: debut,
        dureeMinutes: _dureeMinutes,
      );

      if (!mounted) return;
      setState(() {
        _techniciensDisponibles = data;
        _isLoadingTechniciens = false;
      });

      debugPrint('👷 Techniciens disponibles (date) : ${_techniciensDisponibles.length}');

      if (_techniciensDisponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun technicien disponible pour ce créneau.'), backgroundColor: Colors.orange, duration: Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingTechniciens = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }

  // ============================================================
  // GÉNÉRATION DESCRIPTION IA
  // ============================================================

  Future<void> _genererDescriptionIa() async {
    if (widget.demande == null) return;
    setState(() { _isLoading = true; });
    try {
      final descriptionGeneree = await _demandeService.genererDescriptionIa(widget.demande!.id);
      if (!mounted) return;
      setState(() { _descriptionController.text = descriptionGeneree; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [Icon(Icons.auto_awesome, color: Colors.white), SizedBox(width: 8), Text('Description générée avec succès par IA ✨')]),
          backgroundColor: Colors.green, duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur IA : $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // ============================================================
  // CRÉATION DU BON DE TRAVAIL
  // ============================================================

  Future<void> _creerBonTravail() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateIntervention == null || _heureIntervention == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner la date et l\'heure.'), backgroundColor: Colors.orange));
      return;
    }

    if (_technicienResponsableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner un technicien responsable.'), backgroundColor: Colors.orange));
      return;
    }

    final bool estEvaluation = widget.isEvaluation || (widget.demande?.isEvaluation ?? false);

    if (estEvaluation && _selectedSiteId == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucun site sélectionné'),
          content: const Text('Le technicien pourra-t-il créer le site sur place lors de la visite ?\n\nSinon, retournez en arrière pour en créer un.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange), child: const Text('Continuer sans site')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!estEvaluation && widget.demande?.ascenseurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible : aucun ascenseur associé.'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final debut = DateTime(_dateIntervention!.year, _dateIntervention!.month, _dateIntervention!.day, _heureIntervention!.hour, _heureIntervention!.minute);

      final dto = BonTravailCreateModel(
        demandeMaintenanceId: widget.demande?.id,
        ascenseurId: estEvaluation ? null : widget.demande?.ascenseurId,
        siteId: estEvaluation ? _selectedSiteId : null,
        technicienResponsableId: _technicienResponsableId!,
        dateInterventionPrevue: debut,
        dureeEstimeeMinutes: _dureeMinutes,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : estEvaluation ? 'Évaluation nouvelle installation pour ${widget.demande?.clientNomComplet ?? "client"}' : 'Intervention sur ${widget.demande?.clientNomComplet ?? "client"}',
        priorite: widget.demande?.priorite ?? 'NORMALE',
        visitePreventive: widget.demande?.typeDemande == 'ENTRETIEN_PREVENTIF',
        isEvaluation: estEvaluation,
      );

      debugPrint('===== CRÉATION BON DE TRAVAIL =====');
      debugPrint('siteId: ${dto.siteId}, techId: ${dto.technicienResponsableId}, isEval: ${dto.isEvaluation}');

      await _bonTravailService.creer(dto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estEvaluation ? 'Bon de travail d\'évaluation créé avec succès.' : 'Bon de travail créé avec succès.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool estEvaluation = widget.isEvaluation || (widget.demande?.isEvaluation ?? false);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const ResponsableDrawer(currentRoute: '/responsable-bons-travail'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(estEvaluation ? 'Créer BT Évaluation' : 'Nouveau bon de travail', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.demande != null)
                Card(
                  color: AppColors.navy.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DEMANDE ASSOCIÉE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange)),
                        const SizedBox(height: 8),
                        Text('Demande N° ${widget.demande!.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(widget.demande!.clientNomComplet, style: TextStyle(color: Colors.grey[700])),
                        if (!estEvaluation) Text('Ascenseur : ${widget.demande!.ascenseurNom ?? "Non défini"}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: estEvaluation ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(estEvaluation ? 'Évaluation' : 'Maintenance', style: TextStyle(color: estEvaluation ? Colors.purple : Colors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // ==================================================
              // SITE POUR ÉVALUATION
              // ==================================================
              if (estEvaluation) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('SITE DE L\'ÉVALUATION', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text(' *', style: TextStyle(color: Colors.red)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _creerNouveauSite,
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Créer un site', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.navy, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Sélectionnez un site existant ou créez-en un nouveau.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        
                        if (_isLoadingSites)
                          const Center(child: CircularProgressIndicator())
                        else if (_sites.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange[700], size: 32),
                                const SizedBox(height: 8),
                                Text('Aucun site disponible.', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(onPressed: _creerNouveauSite, icon: const Icon(Icons.add), label: const Text('Créer un site maintenant'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white)),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<int>(
                            value: _selectedSiteId,
                            decoration: const InputDecoration(labelText: 'Site', border: OutlineInputBorder(), hintText: 'Sélectionner un site'),
                            items: _sites.map((site) {
                              final villeNom = site.ville?.nom ?? '';
                              final clientNom = site.client != null ? '${site.client!.prenom} ${site.client!.nom}' : '';
                              return DropdownMenuItem<int>(
                                value: site.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(site.adresse, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('$villeNom ${clientNom.isNotEmpty ? "- $clientNom" : ""}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSiteId = value;
                                _technicienResponsableId = null;
                                _hasSearchedTechniciens = false;
                                _techniciensDisponibles.clear();
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ==================================================
              // SITE POUR MAINTENANCE
              // ==================================================
              if (!estEvaluation && widget.demande != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SITE DE L\'ASCENSEUR', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_isLoadingSites)
                          const Center(child: CircularProgressIndicator())
                        else if (_sites.isEmpty)
                          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Text('Aucun site trouvé pour cet ascenseur.', style: TextStyle(color: Colors.red[700])))
                        else
                          Text('Site associé : ${_sites.isNotEmpty ? _sites.first.adresse : "Non défini"}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ==================================================
              // DATE / HEURE / DURÉE
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE ET HEURE PRÉVUES *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                                child: Row(children: [const Icon(Icons.calendar_today, color: AppColors.orange), const SizedBox(width: 8), Expanded(child: Text(_dateIntervention != null ? _formatDate(_dateIntervention!) : 'Sélectionner une date', style: TextStyle(color: _dateIntervention != null ? Colors.black87 : Colors.grey)))]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                                child: Row(children: [const Icon(Icons.access_time, color: AppColors.orange), const SizedBox(width: 8), Expanded(child: Text(_heureIntervention != null ? _heureIntervention!.format(context) : 'Heure', style: TextStyle(color: _heureIntervention != null ? Colors.black87 : Colors.grey)))]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Durée (min) : ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _dureeMinutes,
                              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              items: [60, 90, 120, 180, 240, 300].map((minutes) => DropdownMenuItem<int>(value: minutes, child: Text('$minutes min'))).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _dureeMinutes = value;
                                  _technicienResponsableId = null;
                                  _hasSearchedTechniciens = false;
                                  _techniciensDisponibles.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==================================================
              // TECHNICIEN (CORRIGÉ - PLUS DE DÉBORDEMENT)
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('TECHNICIEN RESPONSABLE *', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: estEvaluation ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              estEvaluation ? 'Parc du site' : 'Disponibles',
                              style: TextStyle(color: estEvaluation ? Colors.purple : Colors.blue, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingTechniciens)
                        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator()))
                      else if (!_hasSearchedTechniciens)
                        ElevatedButton.icon(
                          onPressed: _chargerTechniciensDisponibles,
                          icon: const Icon(Icons.search),
                          label: Text(estEvaluation ? 'Charger les techniciens de ce parc' : 'Voir les techniciens disponibles'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, minimumSize: const Size(double.infinity, 48)),
                        )
                      else if (_techniciensDisponibles.isEmpty)
                        Column(
                          children: [
                            ElevatedButton.icon(onPressed: _chargerTechniciensDisponibles, icon: const Icon(Icons.refresh), label: const Text('Réessayer'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87, minimumSize: const Size(double.infinity, 48))),
                            const SizedBox(height: 8),
                            Text(estEvaluation ? 'Aucun technicien ne couvre ce parc.' : 'Aucun technicien disponible pour ce créneau.', style: TextStyle(color: Colors.red[700], fontSize: 12), textAlign: TextAlign.center),
                          ],
                        )
                      else
                        DropdownButtonFormField<int>(
                          isDense: true,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          value: _technicienResponsableId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            hintText: 'Sélectionner un technicien',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: const TextStyle(fontSize: 13, height: 1.2),
                          items: _techniciensDisponibles.map((technicien) {
                            final dynamic rawId = technicien['id'];
                            final int? id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                            final String nomAffiche = '${technicien['prenom'] ?? ''} ${technicien['nom'] ?? ''}'.trim();
                            final String finalNom = nomAffiche.isNotEmpty ? nomAffiche : 'Technicien inconnu';
                            final String specialite = technicien['specialite']?.toString() ?? '';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    finalNom, 
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (specialite.isNotEmpty)
                                    Text(
                                      specialite, 
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() { _technicienResponsableId = value; }),
                          validator: (value) => value == null ? 'Veuillez sélectionner un technicien' : null,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (widget.demande != null)
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _genererDescriptionIa,
                              icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 16),
                              label: Text(_isLoading ? 'Génération...' : 'IA'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[100], foregroundColor: Colors.purple[900], padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          hintText: estEvaluation ? 'Décrivez l\'évaluation prévue...' : 'Décrivez l\'intervention prévue...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'La description est requise' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==================================================
              // BOUTON CRÉATION
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _creerBonTravail,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(estEvaluation ? 'Créer BT Évaluation' : 'Créer le bon de travail', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
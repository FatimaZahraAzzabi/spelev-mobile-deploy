import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/bon_travail_service.dart';
import '../../services/checklist_service.dart';
import '../../models/bon_travail_model.dart';
import '../../models/checklist_model.dart';
import '../../theme/app_theme.dart';
import 'cloture_intervention_screen.dart';
import '../../widgets/messagerie_interne_widget.dart';

class TechnicienDetailInterventionScreen extends StatefulWidget {
  final int bonId;
  const TechnicienDetailInterventionScreen({super.key, required this.bonId});

  @override
  State<TechnicienDetailInterventionScreen> createState() => _TechnicienDetailInterventionScreenState();
}

class _TechnicienDetailInterventionScreenState extends State<TechnicienDetailInterventionScreen> {
  final _bonService = BonTravailService();
  final _checklistService = ChecklistService();
  final _picker = ImagePicker();

  BonTravailModel? _bon;
  ChecklistModel? _checklist;
  bool _isLoading = true;
  bool _isStarting = false;

  Duration _chronoDuration = Duration.zero;
  Timer? _chronoTimer;
  final Map<int, ItemCheckListModel> _modifiedItems = {};
  final Set<int> _expandedRemarks = {};
  final Map<int, File?> _itemPhotos = {};
  
  final Map<int, TextEditingController> _remarkControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  TextEditingController _getRemarkController(int itemId, String initialText) {
    if (!_remarkControllers.containsKey(itemId)) {
      _remarkControllers[itemId] = TextEditingController(text: initialText);
    }
    return _remarkControllers[itemId]!;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bon = await _bonService.getDetailIntervention(widget.bonId); 
      ChecklistModel? checklist;
      try {
        checklist = await _checklistService.getByBonTravail(widget.bonId);
      } catch (e) {
        // Pas de checklist
      }

      setState(() {
        _bon = bon;
        _checklist = checklist;
        _isLoading = false;
      });

      if (bon.statut == StatutBonTravail.EN_COURS && checklist != null && checklist.heureArrivee != null) {
        _startChrono(checklist.heureArrivee!);
      } else {
        _chronoTimer?.cancel();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _chronoTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _startChrono(DateTime heureArrivee) {
    final now = DateTime.now();
    setState(() => _chronoDuration = now.difference(heureArrivee));
    _chronoTimer?.cancel();
    _chronoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _chronoDuration = _chronoDuration + const Duration(seconds: 1));
    });
  }

  Future<void> _demarrerIntervention() async {
    if (_checklist == null) return;
    setState(() => _isStarting = true);
    try {
      final updatedChecklist = await _checklistService.demarrer(_checklist!.id);
      setState(() {
        _checklist = updatedChecklist;
        _bon = BonTravailModel(
          id: _bon!.id, statut: StatutBonTravail.EN_COURS, priorite: _bon!.priorite,
          dateInterventionPrevue: _bon!.dateInterventionPrevue, dureeEstimeeMinutes: _bon!.dureeEstimeeMinutes,
          description: _bon!.description, ascenseurNom: _bon!.ascenseurNom, siteAdresse: _bon!.siteAdresse,
          technicienResponsableNom: _bon!.technicienResponsableNom,
        );
      });
      _startChrono(DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention démarrée avec succès'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

   Future<void> _enregistrerItem(ItemCheckListModel item) async {
    try {
      // 1. D'abord, on envoie la photo au backend si elle existe
      final photoFile = _itemPhotos[item.id];
      if (photoFile != null) {
        await _checklistService.ajouterPhotoItem(item.id, photoFile);
      }

      // 2. Ensuite, on enregistre le statut et la remarque
      final updatedChecklist = await _checklistService.cocherItem(
        itemId: item.id, 
        statut: item.statut, 
        gravite: item.gravite, 
        remarque: item.remarque,
      );
      
      setState(() {
        _checklist = updatedChecklist;
        _modifiedItems.remove(item.id);
        _itemPhotos.remove(item.id); 
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item enregistré avec succès'), backgroundColor: Colors.green, duration: Duration(seconds: 1))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _prendrePhoto(int itemId) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prendre une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.orange),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.orange),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    try {
      final XFile? pickedFile = choice == 'camera'
          ? await _picker.pickImage(source: ImageSource.camera, imageQuality: 80)
          : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        if (mounted) {
          setState(() {
            _itemPhotos[itemId] = imageFile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo ajoutée avec succès'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateItemLocal(int itemId, ItemCheckListModel updated) {
    setState(() => _modifiedItems[itemId] = updated);
  }

  ItemCheckListModel _getEffectiveItem(ItemCheckListModel item) => _modifiedItems[item.id] ?? item;

  @override
  void dispose() {
    _chronoTimer?.cancel();
    for (var controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _bon == null) {
      return Scaffold(backgroundColor: Colors.grey[100], appBar: AppBar(title: const Text('Chargement...')), body: const Center(child: CircularProgressIndicator(color: AppColors.orange)));
    }
    final b = _bon!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 2, iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Bon de travail N° ${b.id}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: b.statutColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(b.statutLabel, style: TextStyle(color: b.statutColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INFORMATIONS GÉNÉRALES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    _infoRow(Icons.assignment, 'Bon de travail', 'N° ${b.id}'),
                    _infoRow(Icons.elevator, 'Ascenseur', b.ascenseurNom ?? 'Non défini'),
                    _infoRow(Icons.location_on, 'Site', b.siteAdresse ?? 'Non défini'),
                    _infoRow(Icons.calendar_today, 'Date prévue', _formatDate(b.dateInterventionPrevue)),
                    _infoRow(Icons.timer, 'Durée estimée', '${b.dureeEstimeeMinutes} minutes'),
                    if (_chronoDuration.inSeconds > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[200]!)),
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: Colors.orange[700]), const SizedBox(width: 8),
                            Text('Chronomètre: ${_formatDuration(_chronoDuration)}', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESCRIPTION DE LA DEMANDE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    Text(b.description.isNotEmpty ? b.description : 'Aucune description', style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_checklist != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checklist, color: AppColors.orange), const SizedBox(width: 8),
                          Text('Checklist de maintenance — ${_checklist!.mois}/${_checklist!.annee}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._checklist!.items.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final effectiveItem = _getEffectiveItem(entry.value);
                        return _buildChecklistItem(index, effectiveItem);
                      }),
                    ],
                  ),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('Aucune checklist disponible pour cette intervention', style: TextStyle(color: Colors.blue)))]),
              ),
            
            const SizedBox(height: 16),
            MessagerieInterneWidget(bonTravailId: widget.bonId),
            const SizedBox(height: 80),
          ],
        ),
      ),

      bottomNavigationBar: _checklist != null ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: b.statut == StatutBonTravail.PLANIFIE
              ? SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isStarting ? null : _demarrerIntervention,
                    icon: _isStarting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow),
                    label: Text(_isStarting ? 'Démarrage...' : 'Démarrer l\'intervention'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                )
              : b.statut == StatutBonTravail.EN_COURS
                  ? SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context, MaterialPageRoute(builder: (_) => ClotureInterventionScreen(checklistId: _checklist!.id, bonId: widget.bonId)),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.check_circle), label: const Text('Clôturer l\'intervention'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ) : null,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.orange), const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(int index, ItemCheckListModel item) {
    final isModified = _modifiedItems.containsKey(item.id);
    final currentStatut = item.statut;
    final isRemarkExpanded = _expandedRemarks.contains(item.id) || (item.remarque != null && item.remarque!.isNotEmpty);
    final hasPhoto = _itemPhotos[item.id] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12), color: isModified ? Colors.blue[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: AppColors.orange, child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(item.libelle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StatutItem>(
              value: currentStatut,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: StatutItem.values.map((statut) => DropdownMenuItem(value: statut, child: Text(_getStatutItemLabel(statut)))).toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateItemLocal(item.id, ItemCheckListModel(
                  id: item.id, ordre: item.ordre, libelle: item.libelle, statut: value,
                  gravite: value == StatutItem.ANOMALIE_DETECTEE ? (item.gravite ?? GraviteAnomalie.MINEURE) : null,
                  remarque: item.remarque, piecesJointes: item.piecesJointes,
                ));
              },
            ),
            if (currentStatut == StatutItem.ANOMALIE_DETECTEE) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<GraviteAnomalie>(
                value: item.gravite ?? GraviteAnomalie.MINEURE,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), labelText: 'Gravité'),
                items: GraviteAnomalie.values.map((gravite) => DropdownMenuItem(value: gravite, child: Text(_getGraviteLabel(gravite)))).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _updateItemLocal(item.id, ItemCheckListModel(id: item.id, ordre: item.ordre, libelle: item.libelle, statut: item.statut, gravite: value, remarque: item.remarque, piecesJointes: item.piecesJointes));
                },
              ),
            ],
            
            const SizedBox(height: 8),
            if (!isRemarkExpanded)
              TextButton.icon(
                onPressed: () {
                  setState(() => _expandedRemarks.add(item.id));
                },
                icon: const Icon(Icons.note_add, size: 16, color: AppColors.orange),
                label: const Text('Ajouter une remarque', style: TextStyle(color: AppColors.orange, fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              )
            else
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _getRemarkController(item.id, item.remarque ?? ''),
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
                    hintText: 'Votre remarque...', 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _expandedRemarks.remove(item.id);
                        });
                      },
                    ),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _updateItemLocal(item.id, ItemCheckListModel(
                      id: item.id, 
                      ordre: item.ordre, 
                      libelle: item.libelle, 
                      statut: item.statut, 
                      gravite: item.gravite, 
                      remarque: value, 
                      piecesJointes: item.piecesJointes
                    ));
                  },
                ),
              ),
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (hasPhoto)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.orange, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_itemPhotos[item.id]!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _prendrePhoto(item.id),
                          icon: Icon(hasPhoto ? Icons.check : Icons.camera_alt, size: 16, color: hasPhoto ? Colors.green : AppColors.orange),
                          label: Text(hasPhoto ? 'Photo ajoutée' : 'Photo', style: TextStyle(color: hasPhoto ? Colors.green : AppColors.orange, fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _enregistrerItem(item),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatutItemLabel(StatutItem statut) {
    switch (statut) {
      case StatutItem.NON_VERIFIE: return 'Non vérifié';
      case StatutItem.CONFORME: return 'Conforme';
      case StatutItem.ANOMALIE_DETECTEE: return 'Anomalie';
    }
  }

  String _getGraviteLabel(GraviteAnomalie gravite) {
    switch (gravite) {
      case GraviteAnomalie.MINEURE: return 'Mineure';
      case GraviteAnomalie.MAJEURE: return 'Majeure';
      case GraviteAnomalie.CRITIQUE: return 'Critique';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}
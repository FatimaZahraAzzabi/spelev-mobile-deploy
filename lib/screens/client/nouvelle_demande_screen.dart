import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:developer' as developer;

import '../../models/ascenseur_model.dart';
import '../../services/ascenseur_service.dart';
import '../../services/demande_maintenance_service.dart';
import '../../services/piece_jointe_service.dart';
import '../../theme/app_theme.dart';
import 'client_drawer.dart';

class NouvelleDemandeScreen extends StatefulWidget {
  const NouvelleDemandeScreen({super.key});

  @override
  State<NouvelleDemandeScreen> createState() => _NouvelleDemandeScreenState();
}

class _NouvelleDemandeScreenState extends State<NouvelleDemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ascenseurService = AscenseurService();
  final _demandeService = DemandeMaintenanceService();
  final _pieceJointeService = PieceJointeService();
  final _recorder = AudioRecorder();
  final _descriptionController = TextEditingController();

  List<AscenseurModel> _ascenseurs = [];
  int? _selectedAscenseurId;
  String? _typeDemande;
  DateTime? _dateSouhaitee;
  List<XFile> _photos = [];
  String? _audioPath;
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isLoadingAscenseurs = true;
  String? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _loadAscenseurs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) _selectedAscenseurId = args;
  }

  Future<void> _loadAscenseurs() async {
    setState(() => _isLoadingAscenseurs = true);
    try {
      developer.log('📡 Chargement des ascenseurs...', name: 'NouvelleDemande');
      final list = await _ascenseurService.getMesAscenseurs();
      developer.log(' ${list.length} ascenseur(s) chargé(s)', name: 'NouvelleDemande');
      
      if (!mounted) return;
      setState(() {
        _ascenseurs = list;
        _isLoadingAscenseurs = false;
        // Vérifier que l'ascenseur pré-sélectionné existe
        if (_selectedAscenseurId != null) {
          final existe = list.any((a) => a.id == _selectedAscenseurId);
          if (!existe) _selectedAscenseurId = null;
        }
      });
      
      if (list.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun ascenseur disponible. Contactez un responsable.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      developer.log(' Erreur chargement ascenseurs: $e', name: 'NouvelleDemande');
      if (!mounted) return;
      setState(() => _isLoadingAscenseurs = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement ascenseurs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _choisirPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    
    setState(() {
      _photos = [..._photos, ...picked].take(5).toList();
    });
    
    if (_photos.length >= 5 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _toggleRecord() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
        developer.log('🎤 Enregistrement arrêté: $path', name: 'NouvelleDemande');
      } else {
        if (!await _recorder.hasPermission()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission micro refusée'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/message_vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        if (!mounted) return;
        setState(() => _isRecording = true);
        developer.log(' Enregistrement démarré...', name: 'NouvelleDemande');
      }
    } catch (e) {
      developer.log(' Erreur enregistrement: $e', name: 'NouvelleDemande');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arrêtez l\'enregistrement avant d\'envoyer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_ascenseurs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun ascenseur disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 'Création de la demande...';
    });

    try {
      // 1. Créer la demande
      developer.log(' Création de la demande...', name: 'NouvelleDemande');
      final dto = <String, dynamic>{
        'ascenseurId': _selectedAscenseurId,
        'typeDemande': _typeDemande,
        'priorite': 'NORMALE',
        'description': _descriptionController.text.trim(),
      };
      if (_dateSouhaitee != null) {
        dto['dateSouhaitee'] = _dateSouhaitee!.toIso8601String().split('T')[0];
      }

      final created = await _demandeService.creerDemande(dto);
      developer.log(' Demande créée avec ID: ${created.id}', name: 'NouvelleDemande');

      // 2. Uploader les photos
      for (int i = 0; i < _photos.length; i++) {
        if (!mounted) return;
        setState(() {
          _uploadProgress = 'Upload photo ${i + 1}/${_photos.length}...';
        });
        developer.log(' Upload photo ${i + 1}/${_photos.length}', name: 'NouvelleDemande');
        
        await _pieceJointeService.uploaderFichier(
          filePath: _photos[i].path,
          entiteType: 'DEMANDE_MAINTENANCE',
          entiteId: created.id,
        );
      }

      // 3. Uploader le message vocal
      if (_audioPath != null) {
        if (!mounted) return;
        setState(() => _uploadProgress = 'Upload du message vocal...');
        developer.log(' Upload audio', name: 'NouvelleDemande');
        
        await _pieceJointeService.uploaderFichier(
          filePath: _audioPath!,
          entiteType: 'DEMANDE_MAINTENANCE',
          entiteId: created.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande envoyée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e, stack) {
      developer.log(' Erreur: $e', name: 'NouvelleDemande', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: ClientDrawer(currentRoute: '/client-nouvelle-demande'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Nouvelle demande',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _isLoadingAscenseurs ? null : _loadAscenseurs,
            tooltip: 'Recharger les ascenseurs',
          ),
        ],
      ),
      body: _isLoadingAscenseurs
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.orange),
                  SizedBox(height: 16),
                  Text('Chargement des ascenseurs...', style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nouvelle demande de maintenance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Renseignez les détails de votre demande',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        // ─── Ascenseur ───
                        if (_ascenseurs.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Aucun ascenseur disponible',
                                    style: TextStyle(color: Colors.orange, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<int>(
                            value: _selectedAscenseurId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Ascenseur *',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text(
                              '-- Sélectionner un ascenseur --',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: _ascenseurs
                                .map((a) => DropdownMenuItem(
                                      value: a.id,
                                      child: Text(
                                        '${a.nom}${a.siteAdresse != null ? ' (${a.siteAdresse})' : ''}',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedAscenseurId = val),
                            validator: (val) => val == null ? 'Requis' : null,
                          ),
                        const SizedBox(height: 16),

                        // ─── Type ───
                        DropdownButtonFormField<String>(
                          value: _typeDemande,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Type *',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text(
                            '-- Sélectionner un type --',
                            style: TextStyle(fontSize: 13),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PANNE',
                              child: Text('Panne', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'ENTRETIEN_PREVENTIF',
                              child: Text('Entretien préventif', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'BRUIT_ANORMAL',
                              child: Text('Bruit anormal', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'AUTRE',
                              child: Text('Autre', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                          onChanged: (val) => setState(() => _typeDemande = val),
                          validator: (val) => val == null ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),

                        // ─── Date souhaitée ───
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _dateSouhaitee = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date souhaitée',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  _dateSouhaitee == null
                                      ? 'jj/mm/aaaa'
                                      : '${_dateSouhaitee!.day.toString().padLeft(2, '0')}/${_dateSouhaitee!.month.toString().padLeft(2, '0')}/${_dateSouhaitee!.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _dateSouhaitee == null ? Colors.black45 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ─── Description ───
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            hintText: 'Décrivez le problème...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 24),

                        // ─── Photos ───
                        const Text(
                          'Photos (optionnel, max 5)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton.icon(
                            onPressed: _choisirPhotos,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: Text(
                              _photos.isEmpty
                                  ? 'Choisir des photos'
                                  : 'Ajouter des photos (${_photos.length}/5)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(foregroundColor: AppColors.navy),
                          ),
                        ),
                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_photos[i].path),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _photos.removeAt(i)),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ─── Enregistrement vocal ───
                        const Text(
                          'Enregistrement vocal (optionnel)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton.icon(
                            onPressed: _toggleRecord,
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 18,
                              color: _isRecording ? Colors.red : null,
                            ),
                            label: Text(
                              _isRecording
                                  ? 'Arrêter l\'enregistrement'
                                  : (_audioPath != null ? 'Réenregistrer' : 'Enregistrer un message vocal'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isRecording ? Colors.red : null,
                              ),
                            ),
                            style: TextButton.styleFrom(foregroundColor: AppColors.navy),
                          ),
                        ),
                        if (_audioPath != null && !_isRecording) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.audiotrack, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Message vocal enregistré ✓',
                                  style: TextStyle(fontSize: 13, color: Colors.green),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => setState(() => _audioPath = null),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),

                        // ─── Indicateur de progression ───
                        if (_uploadProgress != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _uploadProgress!,
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ─── Bouton envoyer ───
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _ascenseurs.isEmpty) ? null : _submit,
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
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Envoyer la demande',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../services/evaluation_service.dart';
import '../../services/piece_jointe_service.dart';
import '../../theme/app_theme.dart';
import 'client_drawer.dart';

class NouvelleEvaluationScreen extends StatefulWidget {
  const NouvelleEvaluationScreen({super.key});

  @override
  State<NouvelleEvaluationScreen> createState() => _NouvelleEvaluationScreenState();
}

class _NouvelleEvaluationScreenState extends State<NouvelleEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _evaluationService = EvaluationService();
  final _pieceJointeService = PieceJointeService();
  final _recorder = AudioRecorder();
  final _imagePicker = ImagePicker();

  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dateSouhaitee;
  List<XFile> _photos = [];
  String? _audioPath;
  bool _isRecording = false;
  bool _isLoading = false;
  String? _uploadProgress;

  @override
  void dispose() {
    _recorder.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _prendrePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image == null) return;
    setState(() => _photos = [..._photos, image].take(5).toList());
  }

  Future<void> _choisirDepuisGalerie() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _photos = [..._photos, ...picked].take(5).toList());
  }

  Future<void> _toggleRecord() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      } else {
        if (!await _recorder.hasPermission()) return;
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/evaluation_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur enregistrement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrêtez l\'enregistrement avant d\'envoyer'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 'Envoi de la demande...';
    });

    try {
      final dto = <String, dynamic>{
        'ville': _villeController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'description': _descriptionController.text.trim(),
      };
      if (_dateSouhaitee != null) {
        dto['dateSouhaitee'] = _dateSouhaitee!.toIso8601String().split('T')[0];
      }

      final created = await _evaluationService.creer(dto);
      final int createdId = created['id'] as int;

      for (int i = 0; i < _photos.length; i++) {
        if (!mounted) return;
        setState(() => _uploadProgress = 'Upload photo ${i + 1}/${_photos.length}...');
        await _pieceJointeService.uploaderFichier(
          filePath: _photos[i].path,
          entiteType: 'DEMANDE_MAINTENANCE',
          entiteId: createdId,
        );
      }

      if (_audioPath != null) {
        if (!mounted) return;
        setState(() => _uploadProgress = 'Upload du message vocal...');
        await _pieceJointeService.uploaderFichier(
          filePath: _audioPath!,
          entiteType: 'DEMANDE_MAINTENANCE',
          entiteId: createdId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande d\'évaluation envoyée !'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
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
      drawer: ClientDrawer(currentRoute: '/client-nouvelle-evaluation'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Demande d\'évaluation',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
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
                    'Demande d\'évaluation d\'un nouvel ascenseur',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Renseignez les informations du site. Un responsable technique planifiera une visite sur place.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  const Text('LOCALISATION DU NOUVEL ASCENSEUR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _villeController,
                    decoration: const InputDecoration(
                      labelText: 'Ville *',
                      hintText: 'Ex : Casablanca, Mohammedia...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _adresseController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse exacte *',
                      hintText: 'Ex : 12 Boulevard Mohammed V',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 24),

                  const Text('DÉTAILS DE LA DEMANDE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description du contexte *',
                      hintText: 'Précisez s\'il s\'agit d\'une nouvelle installation, d\'une mise aux normes...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 3)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _dateSouhaitee = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de visite souhaitée (facultatif)',
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
                                color: _dateSouhaitee == null ? Colors.black45 : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('PHOTOS (max 5)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: TextButton.icon(
                            onPressed: _prendrePhoto,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Prendre photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.navy),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: TextButton.icon(
                            onPressed: _choisirDepuisGalerie,
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Galerie', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: AppColors.navy),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${_photos.length}/5 photo(s)', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(_photos[i].path), width: 70, height: 70, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.removeAt(i)),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: TextButton.icon(
                      onPressed: _toggleRecord,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 18,
                          color: _isRecording ? Colors.red : null),
                      label: Text(
                        _isRecording ? 'Arrêter l\'enregistrement' : 'Enregistrer un message vocal',
                        style: TextStyle(fontWeight: FontWeight.w600, color: _isRecording ? Colors.red : null),
                      ),
                      style: TextButton.styleFrom(foregroundColor: AppColors.navy),
                    ),
                  ),
                  if (_audioPath != null && !_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Message vocal enregistré ✓',
                              style: TextStyle(fontSize: 13, color: Colors.green))),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => setState(() => _audioPath = null),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  if (_uploadProgress != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_uploadProgress!,
                              style: const TextStyle(color: AppColors.orange, fontSize: 13))),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Soumettre la demande',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
}
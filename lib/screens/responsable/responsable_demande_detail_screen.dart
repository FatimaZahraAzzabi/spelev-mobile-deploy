import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../../services/demande_maintenance_service.dart';
import '../../models/demande_maintenance_model.dart';
import '../../theme/app_theme.dart';
import 'nouveau_bon_travail_screen.dart';

class ResponsableDemandeDetailScreen extends StatefulWidget {
  final DemandeMaintenanceModel demande;

  const ResponsableDemandeDetailScreen({super.key, required this.demande});

  @override
  State<ResponsableDemandeDetailScreen> createState() =>
      _ResponsableDemandeDetailScreenState();
}

class _ResponsableDemandeDetailScreenState
    extends State<ResponsableDemandeDetailScreen> {
  final _service = DemandeMaintenanceService();
  bool _isLoading = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentAudioUrl;
  Uint8List? _currentAudioBytes;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'CRITIQUE': return Colors.red;
      case 'URGENTE': return Colors.orange;
      case 'NORMALE': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE': return Colors.orange;
      case 'ACCEPTEE': return Colors.green;
      case 'REJETEE': return Colors.red;
      case 'ANNULEE': return Colors.grey;
      default: return Colors.blue;
    }
  }

    Future<void> _accepterDemande() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la demande'),
        content: const Text(
            'Êtes-vous sûr de vouloir accepter cette demande ? Vous allez être redirigé vers la création du bon de travail.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _service.accepterDemande(widget.demande.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Demande acceptée avec succès'),
                backgroundColor: Colors.green),
          );
      
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NouveauBonTravailScreen(
                demande: widget.demande, 
              ),
            ),
          );
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
  }

  Future<void> _rejeterDemande() async {
    final motifController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez fournir un motif de rejet :'),
            const SizedBox(height: 12),
            TextField(
              controller: motifController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Pièce non disponible, hors contrat...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().length >= 10) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le motif doit faire au moins 10 caractères'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _service.rejeterDemande(widget.demande.id, motifController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande rejetée'), backgroundColor: Colors.orange),
          );
          Navigator.pop(context, true);
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
  }

  Future<void> _downloadAndPlayAudio(String audioUrl) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse(audioUrl),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _currentAudioBytes = response.bodyBytes;
          _currentAudioUrl = audioUrl;
        });

        await _audioPlayer.play(BytesSource(_currentAudioBytes!));
        setState(() => _isPlaying = true);

        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) setState(() => _isPlaying = false);
        });
      } else {
        debugPrint(' Erreur téléchargement audio: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur de chargement de l\'audio'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint(' Exception audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire l\'audio'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAudio(String audioUrl) async {
    if (_currentAudioUrl == audioUrl && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_currentAudioUrl != audioUrl) {
        await _audioPlayer.stop();
        await _downloadAndPlayAudio(audioUrl);
      } else {
        if (_currentAudioBytes != null) {
          await _audioPlayer.play(BytesSource(_currentAudioBytes!));
          setState(() => _isPlaying = true);
        }
      }

      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;
    final isEnAttente = d.statut.toUpperCase() == 'EN_ATTENTE';

    final images = d.photos.where((p) => p.estImage).toList();
    final audios = d.photos.where((p) => p.estAudio).toList();

    debugPrint(' Images à afficher: ${images.length}');
    debugPrint(' Audios à afficher: ${audios.length}');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Demande N° ${d.id}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatutColor(d.statut).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              d.statut,
              style: TextStyle(color: _getStatutColor(d.statut), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : SingleChildScrollView(
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
                          _infoGrid([
                            _infoItem(Icons.person, 'Client', d.clientNomComplet),
                            _infoItem(Icons.elevator, 'Ascenseur', d.ascenseurNom ?? 'Ascenseur #${d.ascenseurId}'),
                            _infoItem(Icons.category, 'Type de demande', d.typeDemande),
                            _infoItem(Icons.flag, 'Priorité', d.priorite, valueColor: _getPrioriteColor(d.priorite)),
                            _infoItem(Icons.calendar_today, 'Date de création', d.createdAt != null ? _formatDateTime(DateTime.parse(d.createdAt!)) : 'Non renseigné'),
                          ]),
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
                          const Text('DESCRIPTION DU BESOIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Text(d.description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (images.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PHOTOS / PIÈCES JOINTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  return AuthenticatedImage(url: images[index].url);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (audios.isNotEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NOTES AUDIO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                            const SizedBox(height: 16),
                            ...audios.map((audio) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.navy.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _currentAudioUrl == audio.url && _isPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_filled,
                                          color: AppColors.orange,
                                          size: 40,
                                        ),
                                        onPressed: () => _toggleAudio(audio.url),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Enregistrement vocal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                              _currentAudioUrl == audio.url && _isPlaying
                                                  ? 'Lecture en cours...'
                                                  : 'Appuyez pour écouter',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
      
      bottomNavigationBar: isEnAttente
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _rejeterDemande,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _accepterDemande,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accepter la demande', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _infoGrid(List<Widget> items) {
    return Column(children: items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 16), child: item)).toList());
  }

  Widget _infoItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════
// Widget Image Sécurisé (avec token JWT)
// ═══════════════════════════════════════════════════════════
class AuthenticatedImage extends StatefulWidget {
  final String url;
  const AuthenticatedImage({super.key, required this.url});

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse(widget.url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        debugPrint(' Erreur HTTP ${response.statusCode} pour: ${widget.url}');
        if (mounted) setState(() => _hasError = true);
      }
    } catch (e) {
      debugPrint(' Exception chargement image: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    
    if (_hasError || _imageBytes == null) {
      return Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey, size: 30),
            SizedBox(height: 4),
            Text('Erreur', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover),
      ),
    );
  }
}
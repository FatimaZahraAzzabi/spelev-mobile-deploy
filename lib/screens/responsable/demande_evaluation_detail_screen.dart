import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import '../../services/demande_maintenance_service.dart';
import '../../models/demande_maintenance_model.dart';
import '../../theme/app_theme.dart';
import 'nouveau_bon_travail_screen.dart';

class DemandeEvaluationDetailScreen extends StatefulWidget {
  final DemandeMaintenanceModel demande;

  const DemandeEvaluationDetailScreen({
    super.key,
    required this.demande,
  });

  @override
  State<DemandeEvaluationDetailScreen> createState() =>
      _DemandeEvaluationDetailScreenState();
}

class _DemandeEvaluationDetailScreenState
    extends State<DemandeEvaluationDetailScreen> {
  final DemandeMaintenanceService _service =
      DemandeMaintenanceService();

  bool _isAccepting = false;
  bool _isRejecting = false;

  // ============================================================
  // AUDIO
  // ============================================================

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  String? _currentAudioUrl;
  Uint8List? _currentAudioBytes;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ============================================================
  // STATUT
  // ============================================================

  Color _getStatutColor(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        return Colors.orange;

      case 'ACCEPTEE':
        return Colors.green;

      case 'REJETEE':
        return Colors.red;

      case 'RESOLUE':
        return Colors.blue;

      case 'ANNULEE':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  String _getStatutLibelle(String statut) {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        return 'En attente';

      case 'ACCEPTEE':
        return 'Acceptée';

      case 'REJETEE':
        return 'Rejetée';

      case 'RESOLUE':
        return 'Résolue';

      case 'ANNULEE':
        return 'Annulée';

      default:
        return statut;
    }
  }

  // ============================================================
  // ACCEPTER LA DEMANDE
  // ============================================================

  Future<void> _accepterDemande() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir accepter cette demande '
          "d'installation ?\n\n"
          'Vous allez être redirigé vers la création du bon de travail '
          'pour le technicien.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      await _service.accepterDemande(widget.demande.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande acceptée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NouveauBonTravailScreen(
            demande: widget.demande,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  // ============================================================
  // REJETER LA DEMANDE
  // ============================================================

  Future<void> _rejeterDemande() async {
    final motifController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veuillez fournir un motif de rejet :',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motifController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Ex: Informations manquantes, hors zone...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().length >= 10) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Le motif doit faire au moins 10 caractères',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    final motif = motifController.text.trim();

    motifController.dispose();

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isRejecting = true;
    });

    try {
      await _service.rejeterDemande(
        widget.demande.id,
        motif,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande rejetée'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRejecting = false;
        });
      }
    }
  }

  // ============================================================
  // AUDIO : TÉLÉCHARGER + LIRE
  // ============================================================

  Future<void> _downloadAndPlayAudio(String audioUrl) async {
    try {
      const storage = FlutterSecureStorage();

      final token = await storage.read(
        key: 'jwt_token',
      );

      debugPrint('🎵 Chargement audio : $audioUrl');

      final response = await http.get(
        Uri.parse(audioUrl),
        headers: token != null
            ? {
                'Authorization': 'Bearer $token',
              }
            : {},
      );

      debugPrint(
        '🎵 Réponse audio HTTP : ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Erreur téléchargement audio : '
          '${response.statusCode}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur de chargement audio '
                '(${response.statusCode})',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      if (response.bodyBytes.isEmpty) {
        debugPrint('❌ Le fichier audio est vide');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le fichier audio est vide'),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      _currentAudioBytes = response.bodyBytes;
      _currentAudioUrl = audioUrl;

      await _audioPlayer.stop();

      await _audioPlayer.play(
        BytesSource(_currentAudioBytes!),
      );

      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Exception audio : $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de lire l\'audio',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // AUDIO : PLAY / PAUSE
  // ============================================================

  Future<void> _toggleAudio(String audioUrl) async {
    try {
      // Même audio actuellement en lecture
      if (_currentAudioUrl == audioUrl && _isPlaying) {
        await _audioPlayer.pause();

        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }

        return;
      }

      // Même audio mais actuellement en pause
      if (_currentAudioUrl == audioUrl &&
          !_isPlaying &&
          _currentAudioBytes != null) {
        await _audioPlayer.resume();

        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }

        return;
      }

      // Nouvel audio
      await _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentAudioUrl = null;
          _currentAudioBytes = null;
        });
      }

      await _downloadAndPlayAudio(audioUrl);
    } catch (e) {
      debugPrint('❌ Erreur toggle audio : $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;

    final statut = d.statut.toUpperCase();

    final isEnAttente = statut == 'EN_ATTENTE';
    final isAcceptee = statut == 'ACCEPTEE';
    final isResolue = statut == 'RESOLUE';
    final isRejetee = statut == 'REJETEE';

    // ----------------------------------------------------------
    // SÉPARATION IMAGES / AUDIO
    // ----------------------------------------------------------

    final images = d.photos
        .where((p) => p.estImage)
        .toList();

    final audios = d.photos
        .where((p) => p.estAudio)
        .toList();

    debugPrint(
      '📸 Images à afficher : ${images.length}',
    );

    debugPrint(
      '🎵 Audios à afficher : ${audios.length}',
    );

    for (final audio in audios) {
      debugPrint(
        '🎵 Audio URL : ${audio.url}',
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,

        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),

        title: Text(
          'Demande N° ${d.id}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 16,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getStatutColor(d.statut)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatutLibelle(d.statut),
              style: TextStyle(
                color: _getStatutColor(d.statut),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // ====================================================
            // INFORMATIONS CLIENT
            // ====================================================

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMATIONS CLIENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _infoItem(
                      Icons.person,
                      'Client',
                      d.clientNomComplet,
                    ),

                    if (d.clientEmail != null &&
                        d.clientEmail!.isNotEmpty)
                      _infoItem(
                        Icons.email,
                        'Email',
                        d.clientEmail!,
                      ),

                    if (d.clientNomEntreprise != null &&
                        d.clientNomEntreprise!.isNotEmpty)
                      _infoItem(
                        Icons.business,
                        'Entreprise',
                        d.clientNomEntreprise!,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // INFORMATIONS DU SITE
            // ====================================================

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMATIONS DU SITE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (d.adresseSaisie != null &&
                        d.adresseSaisie!.isNotEmpty)
                      _infoItem(
                        Icons.location_on,
                        'Adresse',
                        d.adresseSaisie!,
                      ),

                    if (d.villeSaisie != null &&
                        d.villeSaisie!.isNotEmpty)
                      _infoItem(
                        Icons.location_city,
                        'Ville',
                        d.villeSaisie!,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // DESCRIPTION
            // ====================================================

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESCRIPTION DU BESOIN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      d.description.isNotEmpty
                          ? d.description
                          : 'Aucune description',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // PHOTOS
            // ====================================================

            if (images.isNotEmpty) ...[
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PHOTOS / PIÈCES JOINTES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection:
                              Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder:
                              (context, index) {
                            return AuthenticatedImage(
                              url: images[index].url,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ====================================================
            // NOTES AUDIO
            // ====================================================

            if (audios.isNotEmpty) ...[
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOTES AUDIO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 16),

                      ...audios.map(
                        (audio) {
                          final isThisAudioPlaying =
                              _currentAudioUrl ==
                                      audio.url &&
                                  _isPlaying;

                          return Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            padding:
                                const EdgeInsets.all(12),
                            decoration:
                                BoxDecoration(
                              color: AppColors.navy
                                  .withOpacity(0.05),
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.navy
                                    .withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                // PLAY / PAUSE
                                IconButton(
                                  onPressed: () =>
                                      _toggleAudio(
                                    audio.url,
                                  ),
                                  icon: Icon(
                                    isThisAudioPlaying
                                        ? Icons
                                            .pause_circle_filled
                                        : Icons
                                            .play_circle_filled,
                                    color:
                                        AppColors.orange,
                                    size: 44,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // INFORMATIONS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'Enregistrement vocal',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Text(
                                        isThisAudioPlaying
                                            ? 'Lecture en cours...'
                                            : 'Appuyez pour écouter',
                                        style: TextStyle(
                                          color:
                                              Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isThisAudioPlaying)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          AppColors.orange,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ====================================================
            // DEMANDE ACCEPTÉE
            // ====================================================

            if (isAcceptee) ...[
              const SizedBox(height: 16),

              _buildStatusMessage(
                icon: Icons.hourglass_empty,
                title:
                    'En attente d\'intervention',
                message:
                    'Un bon de travail a été créé. '
                    'Un technicien va être assigné.',
                color: Colors.blue,
              ),
            ],

            // ====================================================
            // DEMANDE RÉSOLUE
            // ====================================================

            if (isResolue) ...[
              const SizedBox(height: 16),

              _buildStatusMessage(
                icon: Icons.check_circle,
                title:
                    'Installation réalisée',
                message:
                    'Cette demande d\'installation '
                    'a été traitée avec succès.',
                color: Colors.green,
              ),
            ],

            // ====================================================
            // DEMANDE REJETÉE
            // ====================================================

            if (isRejetee) ...[
              const SizedBox(height: 16),

              _buildStatusMessage(
                icon: Icons.cancel,
                title: 'Demande rejetée',
                message:
                    d.motifRejet != null &&
                            d.motifRejet!.isNotEmpty
                        ? d.motifRejet!
                        : 'Aucun motif renseigné.',
                color: Colors.red,
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ========================================================
      // BOUTONS EN BAS
      // ========================================================

      bottomNavigationBar: isEnAttente
          ? Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset:
                        const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [

                    // ==============================
                    // BOUTON REJETER
                    // ==============================

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _isRejecting ||
                                    _isAccepting
                                ? null
                                : _rejeterDemande,

                        icon: _isRejecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(
                                Icons.close,
                                size: 18,
                              ),

                        label: _isRejecting
                            ? const Text(
                                'Rejet...',
                              )
                            : const Text(
                                'Rejeter',
                              ),

                        style:
                            OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 12,
                          ),
                          side:
                              const BorderSide(
                            color: Colors.red,
                          ),
                          foregroundColor:
                              Colors.red,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ==============================
                    // BOUTON ACCEPTER
                    // ==============================

                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isAccepting ||
                                    _isRejecting
                                ? null
                                : _accepterDemande,

                        icon: _isAccepting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .assignment_add,
                                size: 18,
                              ),

                        label: _isAccepting
                            ? const Text(
                                'Acceptation...',
                              )
                            : const Text(
                                'Accepter & créer BT',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green,
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 12,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),
                          ),
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

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.orange,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE DE STATUT
  // ============================================================

  Widget _buildStatusMessage({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: TextStyle(
                    color: color
                        .withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// IMAGE AVEC AUTHENTIFICATION JWT
// ================================================================

class AuthenticatedImage extends StatefulWidget {
  final String url;

  const AuthenticatedImage({
    super.key,
    required this.url,
  });

  @override
  State<AuthenticatedImage> createState() =>
      _AuthenticatedImageState();
}

class _AuthenticatedImageState
    extends State<AuthenticatedImage> {
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
      const storage =
          FlutterSecureStorage();

      final token = await storage.read(
        key: 'jwt_token',
      );

      final response = await http.get(
        Uri.parse(widget.url),
        headers: token != null
            ? {
                'Authorization':
                    'Bearer $token',
              }
            : {},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          _imageBytes =
              response.bodyBytes;
          _isLoading = false;
        });
      } else {
        debugPrint(
          '❌ Erreur HTTP image : '
          '${response.statusCode}',
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint(
        '❌ Exception chargement image : $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 100,
        height: 100,
        margin:
            const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: const Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_hasError ||
        _imageBytes == null) {
      return Container(
        width: 100,
        height: 100,
        margin:
            const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 30,
            ),
            SizedBox(height: 4),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      margin:
          const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(8),
        image: DecorationImage(
          image:
              MemoryImage(_imageBytes!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
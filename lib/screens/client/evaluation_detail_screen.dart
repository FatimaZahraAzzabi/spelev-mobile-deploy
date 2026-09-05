import 'dart:io';
import 'dart:convert';  
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../config/api_config.dart';
import '../../models/piece_jointe_model.dart';
import '../../services/evaluation_service.dart';
import '../../theme/app_theme.dart';

class EvaluationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> evaluation;

  const EvaluationDetailScreen({super.key, required this.evaluation});

  @override
  State<EvaluationDetailScreen> createState() => _EvaluationDetailScreenState();
}

class _EvaluationDetailScreenState extends State<EvaluationDetailScreen> {
  final _evaluationService = EvaluationService();
  final _storage = const FlutterSecureStorage();

  Map<String, dynamic>? _detail;
  List<PieceJointeModel> _photos = [];
  bool _isLoading = true;
  bool _isAnnuling = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> _loadDetail() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token manquant");

      final id = widget.evaluation['id'];
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/demandes-maintenance/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = response.body;
        final data = (jsonDecode(json)['data'] ?? jsonDecode(json)) as Map<String, dynamic>;

        // Parser les photos comme dans DemandeDetailScreen
        final piecesBrutes = List<Map<String, dynamic>>.from(data['photos'] ?? []);
        final photosParsees = piecesBrutes.map((p) => PieceJointeModel.fromJson(p)).toList();

        setState(() {
          _detail = data;
          _photos = photosParsees;
        });

        debugPrint('═══════════════════════════════════════');
        debugPrint(' Évaluation #${data['id']} | photos: ${_photos.length}');
        for (int i = 0; i < _photos.length; i++) {
          final p = _photos[i];
          debugPrint('   📎 $i: ${p.nomFichier} | ${p.typeFichier} | ${p.url}');
        }
        debugPrint('═══════════════════════════════════════');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _annuler() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler cette demande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isAnnuling = true);
    try {
      await _evaluationService.annuler(widget.evaluation['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande annulée'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnnuling = false);
    }
  }

  void _voirImageFullscreen(PieceJointeModel p) async {
    final token = await _getToken();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  p.url,
                  fit: BoxFit.contain,
                  headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Impossible de charger l\'image', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statutInfo(String statut) {
    switch (statut) {
      case 'EN_ATTENTE': return ('En attente', Colors.orange);
      case 'ASSIGNEE': return ('Visite planifiée', Colors.blue);
      case 'EN_COURS': return ('Visite en cours', Colors.teal);
      case 'RESOLUE': return ('Ascenseur enregistré', Colors.green);
      case 'REJETEE': return ('Refusée', Colors.red);
      case 'ANNULEE': return ('Annulée', Colors.grey);
      default: return (statut, Colors.grey);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statut = (_detail?['statut'] ?? widget.evaluation['statut'] ?? 'EN_ATTENTE').toString();
    final (label, color) = _statutInfo(statut);

    final images = _photos.where((p) => p.estImage).toList();
    final audios = _photos.where((p) => p.estAudio).toList();
    final autres = _photos.where((p) => !p.estImage && !p.estAudio).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Détail #${widget.evaluation['id']}',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.orange), onPressed: _loadDetail),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── STATUT + INFOS ───
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(label,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                                ),
                                const Spacer(),
                                Text('#${widget.evaluation['id']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black38)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _infoRow(Icons.location_city, 'Ville', _detail?['villeSaisie'] ?? '—'),
                            _infoRow(Icons.home, 'Adresse', _detail?['adresseSaisie'] ?? '—'),
                            _infoRow(Icons.calendar_today, 'Date souhaitée',
                                _detail?['dateSouhaitee'] != null ? _formatDate(_detail?['dateSouhaitee']) : 'Non précisée'),
                            _infoRow(Icons.event, 'Créée le', _formatDate(_detail?['createdAt'])),
                            _infoRow(Icons.attach_file, 'Pièces jointes', '${_photos.length} fichier(s)'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── DESCRIPTION ───
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DESCRIPTION',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                            const SizedBox(height: 8),
                            Text(_detail?['description'] ?? '—',
                                style: const TextStyle(fontSize: 14, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── PHOTOS ───
                    if (images.isNotEmpty) ...[
                      const Text('Photos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: images.length,
                        itemBuilder: (_, i) {
                          final p = images[i];
                          return GestureDetector(
                            onTap: () => _voirImageFullscreen(p),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<String?>(
                                future: _getToken(),
                                builder: (ctx, snap) {
                                  final token = snap.data;
                                  return Image.network(
                                    p.url,
                                    fit: BoxFit.cover,
                                    headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── AUDIOS ───
                    if (audios.isNotEmpty) ...[
                      const Text('Messages vocaux',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 8),
                      ...audios.map((p) => _AudioCard(piece: p)),
                      const SizedBox(height: 16),
                    ],

                    // ─── AUTRES FICHIERS ───
                    if (autres.isNotEmpty) ...[
                      const Text('Autres fichiers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 8),
                      ...autres.map((p) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file, color: AppColors.navy),
                          title: Text(p.nomFichier, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(p.typeFichier ?? 'Fichier', style: const TextStyle(fontSize: 11)),
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],

                    // ─── AUCUNE PIÈCE ───
                    if (_photos.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 12),
                            Text('Aucune pièce jointe', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ─── MOTIF REJET ───
                    if (statut == 'REJETEE' && _detail?['motifRejet'] != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Demande rejetée',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 4),
                                  Text(_detail!['motifRejet'],
                                      style: const TextStyle(fontSize: 13, color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (statut == 'RESOLUE')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('Votre ascenseur est maintenant enregistré.',
                                  style: TextStyle(fontSize: 13, color: Colors.green)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Carte audio avec LECTURE RÉELLE
// ═══════════════════════════════════════════════════════════
class _AudioCard extends StatefulWidget {
  final PieceJointeModel piece;
  const _AudioCard({required this.piece});

  @override
  State<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<_AudioCard> {
  final AudioPlayer _player = AudioPlayer();
  final _storage = const FlutterSecureStorage();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final res = await http.get(
        Uri.parse(widget.piece.url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.piece.nomFichier}');
      await file.writeAsBytes(res.bodyBytes);

      await _player.play(DeviceFileSource(file.path));
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('❌ Lecture audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lecture impossible: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.orange.withOpacity(0.15),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                )
              : Icon(
                  _isPlaying ? Icons.stop : Icons.play_arrow,
                  color: AppColors.orange,
                ),
        ),
        title: Text(
          widget.piece.nomFichier,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _isPlaying ? 'Lecture en cours...' : 'Message vocal',
          style: const TextStyle(fontSize: 11),
        ),
        onTap: _isLoading ? null : _toggle,
      ),
    );
  }
}
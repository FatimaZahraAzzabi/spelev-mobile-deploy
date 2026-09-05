import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../models/demande_maintenance_model.dart';
import '../../models/piece_jointe_model.dart';
import '../../services/demande_maintenance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/badges.dart';

class DemandeDetailScreen extends StatefulWidget {
  final int demandeId;
  const DemandeDetailScreen({super.key, required this.demandeId});

  @override
  State<DemandeDetailScreen> createState() => _DemandeDetailScreenState();
}

class _DemandeDetailScreenState extends State<DemandeDetailScreen> {
  final _service = DemandeMaintenanceService();
  final _storage = const FlutterSecureStorage();
  DemandeMaintenanceModel? _demande;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final d = await _service.getDetail(widget.demandeId);

      debugPrint('═══════════════════════════════════════');
      debugPrint(' Demande #${d.id} | photos: ${d.photos.length}');
      for (int i = 0; i < d.photos.length; i++) {
        final p = d.photos[i];
        debugPrint('   📎 $i: ${p.nomFichier} | ${p.typeFichier} | ${p.url}');
      }
      debugPrint('═══════════════════════════════════════');

      setState(() {
        _demande = d;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
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
                    child: Text('Impossible de charger l\'image',
                        style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Demande #${widget.demandeId}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _demande == null
              ? const Center(child: Text('Demande introuvable'))
              : _buildBody(_demande!),
    );
  }

  Widget _buildBody(DemandeMaintenanceModel d) {
    final images = d.photos.where((p) => p.estImage).toList();
    final audios = d.photos.where((p) => p.estAudio).toList();
    final autres = d.photos.where((p) => !p.estImage && !p.estAudio).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    StatutBadge(statut: d.statut),
                    const Spacer(),
                    PrioriteBadge(priorite: d.priorite),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    labelTypeDemande(d.typeDemande),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.elevator, 'Ascenseur', d.ascenseurNom ?? '#${d.ascenseurId}'),
                  _infoRow(Icons.calendar_today, 'Créée le', formatDateFr(d.createdAt)),
                  if (d.dateSouhaitee != null)
                    _infoRow(Icons.event, 'Date souhaitée', formatDateFr(d.dateSouhaitee)),
                  _infoRow(Icons.attach_file, 'Pièces jointes', '${d.photos.length} fichier(s)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (d.statut == 'REJETEE' && d.motifRejet != null) ...[
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
                        Text(d.motifRejet!,
                            style: const TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(d.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
                          headers: token != null
                              ? {'Authorization': 'Bearer $token'}
                              : null,
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
                            child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey)),
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

          if (audios.isNotEmpty) ...[
            const Text('Messages vocaux',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            ...audios.map((p) => _AudioCard(piece: p)),
            const SizedBox(height: 16),
          ],

          if (autres.isNotEmpty) ...[
            const Text('Autres fichiers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            ...autres.map((p) => Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file, color: AppColors.navy),
                    title: Text(p.nomFichier, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(p.typeFichier ?? 'Fichier',
                        style: const TextStyle(fontSize: 11)),
                  ),
                )),
          ],

          if (d.photos.isEmpty)
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
        ],
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
              child: Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
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
      // 1. Télécharger le fichier via le proxy backend (avec le JWT)
      final token = await _storage.read(key: 'jwt_token');
      final res = await http.get(
        Uri.parse(widget.piece.url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      // 2. Sauvegarder en fichier temporaire
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.piece.nomFichier}');
      await file.writeAsBytes(res.bodyBytes);

      // 3. Lire le fichier local
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
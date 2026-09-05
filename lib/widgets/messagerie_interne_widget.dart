import 'package:flutter/material.dart';
import '../models/commentaire_model.dart';
import '../services/commentaire_service.dart';
import '../theme/app_theme.dart';

class MessagerieInterneWidget extends StatefulWidget {
  final int bonTravailId;

  const MessagerieInterneWidget({super.key, required this.bonTravailId});

  @override
  State<MessagerieInterneWidget> createState() => _MessagerieInterneWidgetState();
}

class _MessagerieInterneWidgetState extends State<MessagerieInterneWidget> {
  final _service = CommentaireService();
  final _controller = TextEditingController();
  List<CommentaireModel> _commentaires = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadCommentaires();
  }

  Future<void> _loadCommentaires() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.lister(widget.bonTravailId);
      if (mounted) setState(() => _commentaires = data);
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

  Future<void> _envoyerCommentaire() async {
    final contenu = _controller.text.trim();
    if (contenu.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _service.ajouter(widget.bonTravailId, contenu);
      _controller.clear();
      await _loadCommentaires();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
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
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _supprimerCommentaire(CommentaireModel commentaire) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.supprimer(widget.bonTravailId, commentaire.id);
        await _loadCommentaires();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message supprimé'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: AppColors.orange),
                const SizedBox(width: 8),
                const Text(
                  'MESSAGERIE INTERNE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadCommentaires,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des commentaires
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                )
              : _commentaires.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun message pour l\'instant.\nCommencez la discussion sur l\'intervention.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _commentaires.length,
                        itemBuilder: (context, index) {
                          final c = _commentaires[index];
                          return _buildMessageBubble(c);
                        },
                      ),
                    ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _envoyerCommentaire,
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CommentaireModel c) {
    final isResponsable = c.auteurRole.contains('RESPONSABLE') || c.auteurRole.contains('ADMIN');
    final isTechnicien = c.auteurRole.contains('TECHNICIEN');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isResponsable ? AppColors.navy : AppColors.orange,
            child: Text(
              c.auteurNom.isNotEmpty ? c.auteurNom[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isResponsable ? Colors.blue[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.auteurNom,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isResponsable ? AppColors.navy.withOpacity(0.1) : AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatRole(c.auteurRole),
                              style: TextStyle(
                                fontSize: 9,
                                color: isResponsable ? AppColors.navy : AppColors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.contenu, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(c.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (isTechnicien)
                      InkWell(
                        onTap: () => _supprimerCommentaire(c),
                        child: Icon(Icons.delete_outline, size: 14, color: Colors.red[300]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toUpperCase()) {
      case 'TECHNICIEN':
        return 'Technicien';
      case 'RESPONSABLE_MAINTENANCE':
        return 'Responsable';
      case 'ADMINISTRATEUR':
        return 'Admin';
      case 'CLIENT':
        return 'Client';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import '../../models/ascenseur_model.dart';
import '../../services/ascenseur_service.dart';
import '../../theme/app_theme.dart';
import 'client_drawer.dart';

class ClientAscenseursScreen extends StatefulWidget {
  const ClientAscenseursScreen({super.key});

  @override
  State<ClientAscenseursScreen> createState() => _ClientAscenseursScreenState();
}

class _ClientAscenseursScreenState extends State<ClientAscenseursScreen> {
  final _service = AscenseurService();
  List<AscenseurModel> _ascenseurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  setState(() => _isLoading = true);
  try {
    final list = await _service.getMesAscenseurs(); 
    setState(() {
      _ascenseurs = list;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: ClientDrawer(currentRoute: '/client-ascenseurs'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Mes ascenseurs', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.orange), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _ascenseurs.isEmpty
              ? const Center(child: Text('Aucun ascenseur', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ascenseurs.length,
                  itemBuilder: (_, i) {
                    final a = _ascenseurs[i];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.navy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.elevator, color: AppColors.navy, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.nom, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (a.siteAdresse != null) // ← Utilise siteAdresse au lieu de adresse
                                    Row(children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.black45),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          a.siteAdresse!, // ← Utilise siteAdresse au lieu de adresse
                                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                      ),
                                    ]),
                                  if (a.marque != null || a.modele != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${a.marque ?? ''} ${a.modele ?? ''}'.trim(),
                                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/client-nouvelle-demande',
                                arguments: a.id,
                              ),
                              child: const Text(
                                'Demander',
                                style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'responsable_drawer.dart';       
import '../../theme/app_theme.dart';   
import '../../services/parc_service.dart';
import '../../models/parc_model.dart';    
import 'nouveau_parc_screen.dart';     

class ParcListScreen extends StatefulWidget {
  const ParcListScreen({super.key});

  @override
  State<ParcListScreen> createState() => _ParcListScreenState();
}

class _ParcListScreenState extends State<ParcListScreen> {
  final _service = ParcService();
  List<ParcModel> _parcs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParcs();
  }

  Future<void> _loadParcs() async {
    setState(() => _isLoading = true);
    try {
      final parcs = await _service.getParcs();
      setState(() {
        _parcs = parcs;
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
      drawer: const ResponsableDrawer(currentRoute: '/parc-list'), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Gestion des Parcs', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parcs.isEmpty
              ? const Center(child: Text('Aucun parc créé. Cliquez sur + pour commencer.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _parcs.length,
                  itemBuilder: (context, index) {
                    final parc = _parcs[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.location_city, color: AppColors.orange),
                        title: Text(parc.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('ID: ${parc.id}'),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NouveauParcScreen()),
          );
          if (result == true) _loadParcs(); 
        },
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
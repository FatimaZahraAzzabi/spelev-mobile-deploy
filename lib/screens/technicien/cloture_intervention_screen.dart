import 'package:flutter/material.dart';
import '../../services/checklist_service.dart';
import '../../theme/app_theme.dart';

class ClotureInterventionScreen extends StatefulWidget {
  final int checklistId;
  final int bonId;
  const ClotureInterventionScreen({super.key, required this.checklistId, required this.bonId});

  @override
  State<ClotureInterventionScreen> createState() => _ClotureInterventionScreenState();
}

class _ClotureInterventionScreenState extends State<ClotureInterventionScreen> {
  final _checklistService = ChecklistService();
  final _formKey = GlobalKey<FormState>();
  final _bilanController = TextEditingController();

  bool _estMaintenance = false;
  bool _estDepannage = false;
  bool _estTravaux = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bilanController.dispose();
    super.dispose();
  }

  Future<void> _cloturer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_estMaintenance && !_estDepannage && !_estTravaux) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner au moins un type d\'intervention'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _checklistService.cloturer(
        checklistId: widget.checklistId,
        bilanIntervention: _bilanController.text.trim(),
        estMaintenance: _estMaintenance,
        estDepannage: _estDepannage,
        estTravaux: _estTravaux,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervention clôturée avec succès'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 2, iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Clôture de l\'intervention', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                      const Text('VALIDATION DU COMPTE-RENDU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      const Text('Bilan d\'intervention *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bilanController, maxLines: 5,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'Rédigez un résumé clair des opérations effectuées...', alignLabelWithHint: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Le bilan est obligatoire' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text('Type(s) d\'intervention concerné(s)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      CheckboxListTile(title: const Text('Maintenance'), value: _estMaintenance, activeColor: AppColors.orange, onChanged: (v) => setState(() => _estMaintenance = v ?? false), contentPadding: EdgeInsets.zero),
                      CheckboxListTile(title: const Text('Dépannage'), value: _estDepannage, activeColor: AppColors.orange, onChanged: (v) => setState(() => _estDepannage = v ?? false), contentPadding: EdgeInsets.zero),
                      CheckboxListTile(title: const Text('Travaux'), value: _estTravaux, activeColor: AppColors.orange, onChanged: (v) => setState(() => _estTravaux = v ?? false), contentPadding: EdgeInsets.zero),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _cloturer,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmer la clôture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
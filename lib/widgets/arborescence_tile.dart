import 'package:flutter/material.dart';
import '../models/assemblage_model.dart';
import '../models/composant_model.dart';
import '../theme/app_theme.dart';

/// Affiche un assemblage et récursivement ses
/// sous-assemblages + composants.
class ArborescenceTile extends StatelessWidget {
  final AssemblageModel assemblage;
  final int depth;

  const ArborescenceTile({
    super.key,
    required this.assemblage,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final composants = assemblage.composants ?? [];
    final sousAssemblages = assemblage.sousAssemblages ?? [];

    final hasChildren =
        composants.isNotEmpty || sousAssemblages.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: depth == 0,
          shape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),

          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: AppColors.navy,
              size: 18,
            ),
          ),

          title: Text(
            assemblage.nom,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          subtitle: hasChildren
              ? Text(
                  '${composants.length} composant(s) · '
                  '${sousAssemblages.length} sous-ensemble(s)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,

          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 12,
            bottom: 12,
          ),

          children: [
            ...composants.map(
              (composant) => _ComposantRow(
                composant: composant,
              ),
            ),

            ...sousAssemblages.map(
              (sousAssemblage) => ArborescenceTile(
                assemblage: sousAssemblage,
                depth: depth + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposantRow extends StatelessWidget {
  final ComposantModel composant;

  const _ComposantRow({
    required this.composant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: composant.actif
                  ? AppColors.success
                  : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  composant.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Réf. ${composant.reference}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              composant.type,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
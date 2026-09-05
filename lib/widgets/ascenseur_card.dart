import 'package:flutter/material.dart';

import '../models/ascenseur_model.dart';
import '../theme/app_theme.dart';

class AscenseurCard extends StatelessWidget {
  final AscenseurModel ascenseur;
  final VoidCallback onTap;

  const AscenseurCard({
    super.key,
    required this.ascenseur,
    required this.onTap,
  });

  Color get _statutColor {
    return ascenseur.actif
        ? AppColors.success
        : AppColors.danger;
  }

  String get _statutLabel {
    return ascenseur.actif ? 'Actif' : 'Inactif';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Icône ascenseur
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.elevator_outlined,
                color: AppColors.navy,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ascenseur.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${ascenseur.clientPrenom ?? ''} '
                    '${ascenseur.clientNom ?? 'Client non défini'}'
                    ' — '
                    '${ascenseur.siteAdresse ?? 'Site non défini'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      if (ascenseur.nombreEtages != null)
                        _pill(
                          '${ascenseur.nombreEtages} étages',
                        ),

                      if (ascenseur.nombreEtages != null &&
                          ascenseur.numeroSerie != null)
                        const SizedBox(width: 6),

                      if (ascenseur.numeroSerie != null)
                        _pill(
                          ascenseur.numeroSerie!,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Statut + flèche
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 108,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statutColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _statutColor,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Flexible(
                          child: Text(
                            _statutLabel,
                            style: TextStyle(
                              color: _statutColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
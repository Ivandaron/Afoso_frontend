import 'dart:ui';

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

const _monthNames = [
  '',
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

class DepositListTile extends StatelessWidget {
  final Deposit deposit;

  const DepositListTile({super.key, required this.deposit});

  @override
  Widget build(BuildContext context) {
    final isPaid = deposit.isPaid;
    final monthName =
        deposit.month >= 1 && deposit.month <= 12
            ? _monthNames[deposit.month]
            : 'Mois ${deposit.month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icône statut
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPaid ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_outline_rounded
                  : Icons.pending_outlined,
              color: isPaid ? AppColors.success : AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName ${deposit.year}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deposit.date.isNotEmpty
                      ? _formatDate(deposit.date)
                      : isPaid
                      ? 'Payé'
                      : 'En attente',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // Montant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${deposit.amount.toStringAsFixed(0)} FCFA',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      isPaid ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'Payé' : 'En attente',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}

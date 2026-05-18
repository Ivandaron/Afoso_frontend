// month_selector.dart - Nouveau fichier
import 'package:afoso1/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthSelector extends StatelessWidget {
  final int selectedMonthsCount;
  final ValueChanged<int> onMonthsCountChanged;
  final double amountPerMonth;
  final double totalAmount;
  final double minimumRequired;
  final bool isValid;

  const MonthSelector({
    super.key,
    required this.selectedMonthsCount,
    required this.onMonthsCountChanged,
    required this.amountPerMonth,
    required this.totalAmount,
    required this.minimumRequired,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOMBRE DE MOIS',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Le paiement commence toujours par le mois en cours.',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMonthChip(1, '1 mois', '${amountPerMonth.toInt()} FCFA'),
            _buildMonthChip(
              2,
              '2 mois',
              '${(amountPerMonth * 2).toInt()} FCFA',
            ),
            _buildMonthChip(
              3,
              '3 mois',
              '${(amountPerMonth * 3).toInt()} FCFA',
            ),
            _buildMonthChip(
              4,
              '4 mois',
              '${(amountPerMonth * 4).toInt()} FCFA',
            ),
            _buildMonthChip(
              6,
              '6 mois',
              '${(amountPerMonth * 6).toInt()} FCFA',
            ),
            _buildMonthChip(
              12,
              '12 mois',
              '${(amountPerMonth * 12).toInt()} FCFA',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedMonthsCount > 1) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isValid ? AppColors.primarySurface : AppColors.dangerLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isValid ? AppColors.primary : AppColors.danger,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.warning_rounded,
                      size: 16,
                      color: isValid ? AppColors.primary : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isValid ? '✅ Montant valide' : '⚠️ Montant insuffisant',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isValid ? AppColors.primary : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total à payer: ${totalAmount.toInt()} FCFA',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Minimum requis: ${minimumRequired.toInt()} FCFA (1000 FCFA × $selectedMonthsCount mois)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: isValid ? AppColors.textSecondary : AppColors.danger,
                  ),
                ),
                if (selectedMonthsCount > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📅 Mois qui seront payés: ${_getMonthsToPay(selectedMonthsCount).join(", ")}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMonthChip(int months, String label, String total) {
    final isSelected = selectedMonthsCount == months;
    return GestureDetector(
      onTap: () => onMonthsCountChanged(months),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              total,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getMonthsToPay(int monthsCount) {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 0; i < monthsCount; i++) {
      final date = DateTime(now.year, now.month + i);
      months.add('${_monthNames[date.month]} ${date.year}');
    }
    return months;
  }
}

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

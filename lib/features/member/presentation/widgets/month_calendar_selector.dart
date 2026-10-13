import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/features/member/data/models/deposit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthCalendarSelector extends StatelessWidget {
  final DepositCalendar calendar;
  final List<MonthYear> selectedMonths;
  final ValueChanged<MonthYear> onToggle;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;

  const MonthCalendarSelector({
    super.key,
    required this.calendar,
    required this.selectedMonths,
    required this.onToggle,
    required this.onPrevYear,
    required this.onNextYear,
  });

  bool _isSelected(CalendarMonthItem m) {
    return selectedMonths.any(
      (s) => s.month == m.month && s.year == m.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildYearSelector(),
          const SizedBox(height: 16),
          _buildGrid(context),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevYear,
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Center(
            child: Text(
              '${calendar.year}',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onNextYear,
          icon: const Icon(Icons.chevron_right_rounded, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final crossAxisCount = isWide ? 6 : 3;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.0,
      children: calendar.months.map((m) {
        final isSelected = _isSelected(m);
        final canTap = m.selectable && !m.mandatory;

        return _MonthCell(
          item: m,
          isSelected: isSelected || m.mandatory,
          canTap: canTap,
          onTap: canTap ? () => onToggle(m.monthYear) : null,
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(color: AppColors.success, label: 'Payé'),
        _LegendItem(color: AppColors.danger, label: 'En retard'),
        _LegendItem(color: AppColors.warning, label: 'Mois courant'),
        _LegendItem(color: AppColors.primary, label: 'À venir'),
        _LegendItem(color: AppColors.textHint, label: 'Indisponible'),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  final CalendarMonthItem item;
  final bool isSelected;
  final bool canTap;
  final VoidCallback? onTap;

  const _MonthCell({
    required this.item,
    required this.isSelected,
    required this.canTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, icon) = _styles();
    final isBlocked = item.blockedReason != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? fgColor.withOpacity(0.15) : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.mandatory
                ? AppColors.danger
                : isSelected
                    ? fgColor
                    : fgColor.withOpacity(0.3),
            width: item.mandatory
                ? 2.5
                : isSelected
                    ? 2.5
                    : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Opacity(
          opacity: isBlocked ? 0.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.monthName.length > 4
                          ? item.monthName.substring(0, 4)
                          : item.monthName,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                      ),
                    ),
                  ),
                  if (item.mandatory)
                    const Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: AppColors.danger,
                    )
                  else if (isSelected)
                    Icon(Icons.check_circle_rounded, size: 14, color: fgColor)
                  else if (isBlocked)
                    const Icon(
                      Icons.block_rounded,
                      size: 12,
                      color: AppColors.textHint,
                    )
                  else
                    Icon(icon, size: 12, color: fgColor),
                ],
              ),
              if (item.paidAmount > 0)
                Text(
                  '${item.paidAmount.toInt()} F',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: fgColor,
                  ),
                )
              else if (item.mandatory)
                Text(
                  'À régler',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                )
              else
                Text(
                  item.statusLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: fgColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, IconData) _styles() {
    switch (item.status) {
      case 'PAID':
        if (item.isAdvance) {
          return (
            const Color(0xFFEDE9FE),
            const Color(0xFF7C3AED),
            Icons.rocket_launch_rounded,
          );
        }
        return (
          AppColors.successLight,
          AppColors.success,
          Icons.check_circle_rounded,
        );
      case 'OVERDUE':
        return (
          AppColors.dangerLight,
          AppColors.danger,
          Icons.error_rounded,
        );
      case 'PENDING':
        return (
          AppColors.warningLight,
          AppColors.warning,
          Icons.pending_rounded,
        );
      case 'AVAILABLE':
        return (
          AppColors.primarySurface,
          AppColors.primary,
          Icons.add_circle_outline_rounded,
        );
      case 'LOCKED':
      default:
        return (
          AppColors.background,
          AppColors.textHint,
          Icons.lock_outline_rounded,
        );
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

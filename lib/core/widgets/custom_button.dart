import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AfosoButton — Bouton principal avec état loading
// FIX overflow: mainAxisSize.min + Flexible sur le texte
// ─────────────────────────────────────────────────────────────────────────────
class AfosoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AfosoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  static final _baseShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static const _padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: BorderSide(
              color: backgroundColor ?? AppColors.primary,
              width: 1.5,
            ),
            shape: _baseShape,
            foregroundColor: foregroundColor ?? AppColors.primary,
            padding: _padding,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.5),
          shape: _baseShape,
          padding: _padding,
        ),
        child: child,
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }

    final textStyle = GoogleFonts.dmSans(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );

    if (icon != null) {
      // FIX: mainAxisSize.min évite que le Row prenne toute la largeur
      // Flexible sur le texte évite l'overflow quand le label est long
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          icon!,
        ],
      );
    }

    return Text(label, style: textStyle);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AfosoDropdown — Select stylisé
// ─────────────────────────────────────────────────────────────────────────────
class AfosoDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;

  const AfosoDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(prefixIcon: prefixIcon),
          style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textPrimary),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }
}

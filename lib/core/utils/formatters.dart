import 'package:intl/intl.dart';

/// Utilitaires de formatage pour AFOSO
class Formatters {
  Formatters._();

  // ── MONTANTS ──────────────────────────────────────────────────────────────

  /// 1 234 567 FCFA
  static String amount(double value, {bool withCurrency = true}) {
    final formatted = NumberFormat(
      '#,##0',
      'fr_FR',
    ).format(value).replaceAll(',', ' ');
    return withCurrency ? '$formatted FCFA' : formatted;
  }

  /// Format court : 1.2M, 45K, 5000
  static String amountShort(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M FCFA';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K FCFA';
    }
    return '${value.toStringAsFixed(0)} FCFA';
  }

  /// Seulement la valeur courte sans devise
  static String amountShortNoUnit(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  // ── DATES ─────────────────────────────────────────────────────────────────

  /// 25/02/2026
  static String date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  /// 25 fév. 2026
  static String dateLong(DateTime d) =>
      DateFormat('d MMM yyyy', 'fr_FR').format(d);

  /// 25/02/2026 à 14:30
  static String dateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(d);

  /// Parse une chaîne ISO et formate en dd/MM/yyyy
  static String dateFromString(String raw, {String fallback = '—'}) {
    try {
      final d = DateTime.parse(raw);
      return date(d);
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : fallback;
    }
  }

  /// Parse une chaîne ISO et formate en long
  static String dateLongFromString(String raw, {String fallback = '—'}) {
    try {
      return dateLong(DateTime.parse(raw));
    } catch (_) {
      return fallback;
    }
  }

  // ── MOIS ──────────────────────────────────────────────────────────────────

  static const _months = [
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

  /// Numéro 1-12 → "Janvier"
  static String monthName(int month) {
    if (month < 1 || month > 12) return 'Mois $month';
    return _months[month];
  }

  /// "Janvier 2026"
  static String monthYear(int month, int year) => '${monthName(month)} $year';

  // ── TÉLÉPHONE ─────────────────────────────────────────────────────────────

  /// 693123456 → 6 93 12 34 56
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '${digits[0]} ${digits.substring(1, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
    }
    return raw;
  }

  // ── STATUTS ───────────────────────────────────────────────────────────────

  static String memberStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Actif';
      case 'INACTIVE':
        return 'Inactif';
      case 'PENDING':
        return 'En attente';
      case 'SUSPENDED':
        return 'Suspendu';
      default:
        return status;
    }
  }

  static String paymentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'SUCCESS':
      case 'COMPLETED':
        return 'Payé';
      case 'FAILURE':
      case 'FAILED':
        return 'Échoué';
      default:
        return status;
    }
  }

  static String fundStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'CLOSED':
        return 'Fermée';
      case 'DISBURSED':
        return 'Décaissée';
      default:
        return status;
    }
  }

  // ── PROGRESSION ──────────────────────────────────────────────────────────

  /// 0.756 → "75.6%"
  static String percent(double ratio) => '${(ratio * 100).toStringAsFixed(1)}%';

  /// Affiche "+12%" ou "-5%" avec signe
  static String progression(String raw) {
    if (raw.startsWith('-')) return raw;
    if (raw == '0%' || raw == '0.00%') return '0%';
    return '+$raw';
  }
}

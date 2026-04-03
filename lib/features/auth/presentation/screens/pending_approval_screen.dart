import 'dart:async';

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/features/auth/data/models/RegistrationResponse.dart';
import 'package:afoso1/features/auth/presentation/providers/register_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran d'attente après soumission de l'inscription
/// Vérifie le statut du paiement CAMPAY toutes les 5 secondes
class PaymentPendingScreen extends ConsumerStatefulWidget {
  final RegistrationResponse registration;

  const PaymentPendingScreen({super.key, required this.registration});

  @override
  ConsumerState<PaymentPendingScreen> createState() =>
      _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends ConsumerState<PaymentPendingScreen> {
  Timer? _pollingTimer;
  String _status = 'PENDING';
  int _attempt = 0;
  static const int _maxAttempts = 24; // 24 * 5s = 2 minutes

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (widget.registration.externalReference == null) return;

    _attempt++;

    final result = await ref
        .read(registerProvider.notifier)
        .checkPaymentStatus(widget.registration.externalReference!);

    if (result == null) return;

    setState(() => _status = result.status);

    if (result.isSuccess) {
      _pollingTimer?.cancel();
      // Attendre 1s pour l'animation, puis rediriger
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.go('/login');
      }
    } else if (result.isFailure) {
      _pollingTimer?.cancel();
    } else if (_attempt >= _maxAttempts) {
      _pollingTimer?.cancel();
      setState(() => _status = 'TIMEOUT');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Header
              FadeInDown(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AFOSO',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Indicateur de statut
              _buildStatusIndicator(),
              const SizedBox(height: 32),
              // Détails de la transaction
              _buildTransactionDetails(),
              const Spacer(),
              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_status == 'SUCCESS') {
      return FadeInUp(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Paiement confirmé ! 🎉',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre inscription est en cours de validation\npar notre équipe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_status == 'FAILURE') {
      return FadeInUp(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: AppColors.danger,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Paiement échoué',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le paiement n\'a pas pu être traité.\nVeuillez réessayer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_status == 'TIMEOUT') {
      return FadeInUp(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.timer_off_outlined,
                color: AppColors.warning,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Délai dépassé',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le paiement prend trop de temps.\nVérifiez l\'état sur votre téléphone.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // PENDING — animation de chargement
    return FadeInUp(
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirme le paiement',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un message vous a été envoyé sur votre\ntéléphone. Confirmez le paiement.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _DetailRow(
              label: 'Montant',
              value:
                  '${widget.registration.registrationFee?.toStringAsFixed(0) ?? '5 000'} FCFA',
              isHighlight: true,
            ),
            const Divider(height: 20),
            _DetailRow(
              label: 'Référence',
              value: widget.registration.transactionReference ?? '-',
            ),
            const Divider(height: 20),
            _DetailRow(label: 'Statut', valueWidget: _buildStatusBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (_status) {
      case 'SUCCESS':
        color = AppColors.success;
        label = 'Confirmé';
        icon = Icons.check_circle_rounded;
        break;
      case 'FAILURE':
        color = AppColors.danger;
        label = 'Échoué';
        icon = Icons.cancel_rounded;
        break;
      case 'TIMEOUT':
        color = AppColors.warning;
        label = 'Expiré';
        icon = Icons.timer_off_outlined;
        break;
      default:
        color = AppColors.warning;
        label = 'En attente';
        icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_status == 'SUCCESS') {
      return FadeInUp(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: Text(
              'Aller à la connexion',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    if (_status == 'FAILURE' || _status == 'TIMEOUT') {
      return FadeInUp(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Réessayer l\'inscription'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Retour à la connexion'),
              ),
            ),
          ],
        ),
      );
    }

    // PENDING — bouton vérifier manuellement
    return FadeInUp(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkStatus,
              child: const Text('Vérifier le statut'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vérification automatique dans quelques secondes...',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isHighlight;

  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        valueWidget ??
            Text(
              value ?? '-',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
      ],
    );
  }
}

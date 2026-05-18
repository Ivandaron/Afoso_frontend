import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/storage/secure_storage.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _termsController = TextEditingController();
  final _policyController = TextEditingController();
  final _alertController = TextEditingController();
  bool _isLoading = true;
  bool _isSavingTermsPolicy = false;
  bool _isSendingAlert = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _termsController.dispose();
    _policyController.dispose();
    _alertController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final terms = await SecureStorageService.getAdminTerms();
    final policy = await SecureStorageService.getAdminPolicy();
    final alert = await SecureStorageService.getAdminAlertMessage();
    if (mounted) {
      setState(() {
        _termsController.text = terms ?? '';
        _policyController.text = policy ?? '';
        _alertController.text = alert ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTermsAndPolicy() async {
    if (_termsController.text.trim().isEmpty &&
        _policyController.text.trim().isEmpty) {
      _showError('Veuillez remplir au moins un champ');
      return;
    }

    setState(() => _isSavingTermsPolicy = true);
    try {
      await SecureStorageService.saveAdminTerms(_termsController.text.trim());
      await SecureStorageService.saveAdminPolicy(_policyController.text.trim());

      if (mounted) {
        setState(() => _isSavingTermsPolicy = false);
        _showSuccessDialog(
          title: '✅ Conditions enregistrées',
          message:
              'Les conditions générales et la politique de confidentialité ont été mises à jour avec succès.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingTermsPolicy = false);
        _showError('Erreur lors de l\'enregistrement');
      }
    }
  }

  Future<void> _sendAlertMessage() async {
    if (_alertController.text.trim().isEmpty) {
      _showError('Le message d\'alerte ne peut pas être vide');
      return;
    }

    setState(() => _isSendingAlert = true);
    try {
      await SecureStorageService.saveAdminAlertMessage(
        _alertController.text.trim(),
      );
      ref
          .read(adminAlertProvider.notifier)
          .setAlert(_alertController.text.trim());

      if (mounted) {
        setState(() => _isSendingAlert = false);
        _showSuccessDialog(
          title: '📢 Message d\'alerte envoyé',
          message:
              'Le message d\'alerte a été envoyé à tous les membres actifs. Ils le verront à la prochaine actualisation de leur tableau de bord.',
          isAlert: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingAlert = false);
        _showError('Erreur lors de l\'envoi du message');
      }
    }
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    bool isAlert = false,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Administration - Paramètres')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section 1: Conditions générales et politique ──────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Textes officiels',
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Configurez les conditions générales et la politique de confidentialité',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            label: 'Conditions générales',
                            controller: _termsController,
                            hint: 'Tapez les conditions générales ici...',
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            label: 'Politique de confidentialité',
                            controller: _policyController,
                            hint:
                                'Tapez la politique de confidentialité ici...',
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed:
                                _isSavingTermsPolicy
                                    ? null
                                    : _saveTermsAndPolicy,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child:
                                _isSavingTermsPolicy
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Enregistrer les textes officiels',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Section 2: Message d'alerte ──────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Message d\'alerte aux membres',
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ce message sera affiché à tous les membres actifs sur leur tableau de bord',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            label: 'Texte du message d\'alerte',
                            controller: _alertController,
                            hint:
                                'Écrivez le message d\'alerte pour les membres...',
                            maxLines: 6,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed:
                                _isSendingAlert ? null : _sendAlertMessage,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                            ),
                            child:
                                _isSendingAlert
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send_rounded, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Envoyer l\'alerte à tous les membres',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildSection({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 8,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: 4,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

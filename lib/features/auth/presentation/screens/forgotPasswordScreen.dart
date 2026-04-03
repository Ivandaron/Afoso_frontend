import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/features/auth/data/models/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnack('Veuillez saisir votre numéro de téléphone', isError: true);
      return;
    }
    if (Validators.phone(_phoneController.text) != null) {
      _showSnack('Numéro de téléphone invalide', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthRepository().forgotPassword(_phoneController.text.trim());
      setState(() => _emailSent = true);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: const Text('Récupération'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              FadeInDown(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.key_rounded,
                    color: AppColors.warning,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInLeft(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  _emailSent ? 'Code envoyé !' : 'Mot de passe oublié ?',
                  style: GoogleFonts.dmSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  _emailSent
                      ? 'Un code de réinitialisation a été envoyé\npar SMS sur votre numéro.'
                      : 'Saisissez votre numéro de téléphone.\nNous vous enverrons un code par SMS.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (!_emailSent) ...[
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: AfosoTextField(
                    label: 'Numéro de téléphone',
                    hint: 'Ex: 612345678',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSubmit(),
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: AfosoButton(
                    label: 'Envoyer le code',
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ] else ...[
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Consultez vos SMS et suivez les instructions pour réinitialiser votre mot de passe.',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.success,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AfosoButton(
                  label: 'Retour à la connexion',
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 18),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Retour à la connexion',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

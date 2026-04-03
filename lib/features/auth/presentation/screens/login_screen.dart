import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:afoso1/features/auth/presentation/screens/brandPanel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted && !success) {
      final error = ref.read(authProvider).errorMessage;
      _showError(error ?? 'Identifiants incorrects');
    }
    // La navigation est gérée automatiquement par GoRouter via le redirect
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;

    if (isLargeScreen) {
      // Layout desktop / tablet — deux colonnes
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            const Expanded(child: BrandPanel()),
            Expanded(child: _buildFormPanel(isLoading)),
          ],
        ),
      );
    }

    // Layout mobile — une seule colonne avec hero
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [_buildMobileHeader(), _buildFormPanel(isLoading)],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AFOSO',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Microfinance Solidaire',
              style: GoogleFonts.dmSans(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(bool isLoading) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue 👋',
              style: GoogleFonts.dmSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connectez-vous à votre espace AFOSO',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 36),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Téléphone
                  FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                    child: AfosoTextField(
                      label: 'Numéro de téléphone',
                      hint: 'Ex: 612345678',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      focusNode: _phoneFocus,
                      textInputAction: TextInputAction.next,
                      validator: Validators.phone,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onFieldSubmitted:
                          (_) => FocusScope.of(
                            context,
                          ).requestFocus(_passwordFocus),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mot de passe
                  FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 400),
                    child: AfosoTextField(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                      showPasswordToggle: true,
                      focusNode: _passwordFocus,
                      textInputAction: TextInputAction.done,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? 'Le mot de passe est requis'
                                  : null,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Bouton connexion
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 500),
                    child: AfosoButton(
                      label: 'Se connecter',
                      onPressed: _handleLogin,
                      isLoading: isLoading,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Séparateur
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Pas encore membre ?',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 600),
              child: AfosoButton(
                label: "S'inscrire",
                onPressed: () => context.push('/register'),
                isOutlined: true,
                icon: const Icon(Icons.person_add_outlined, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/core/widgets/loading_overlay.dart';
import 'package:afoso1/features/auth/data/models/PaymentStatusResponse.dart';
import 'package:afoso1/features/auth/data/models/RegisterRequest.dart';
import 'package:afoso1/features/auth/presentation/providers/register_state.dart';
import 'package:afoso1/features/auth/presentation/screens/brandPanel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers étape 1 — Infos personnelles
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _birthDate;

  // Controllers étape 2 — Sécurité
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _passwordStrength = 0;

  // Controllers étape 3 — Paiement
  PaymentMethod _selectedPaymentMethod = PaymentMethod.campay;
  final _paymentPhoneController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      helpText: 'Date de naissance',
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _onPasswordChanged(String value) {
    setState(() => _passwordStrength = passwordStrength(value));
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty ||
            _phoneController.text.trim().isEmpty ||
            _emailController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty ||
            _birthDate == null) {
          _showError('Veuillez remplir tous les champs');
          return false;
        }
        if (Validators.phone(_phoneController.text) != null) {
          _showError('Numéro de téléphone invalide');
          return false;
        }
        if (Validators.email(_emailController.text) != null) {
          _showError('Adresse email invalide');
          return false;
        }
        return true;
      case 1:
        if (Validators.password(_passwordController.text) != null) {
          _showError('Le mot de passe ne respecte pas les critères');
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          _showError('Les mots de passe ne correspondent pas');
          return false;
        }
        return true;
      case 2:
        if (_paymentPhoneController.text.trim().isEmpty) {
          _showError('Numéro de paiement requis');
          return false;
        }
        if (!_acceptedTerms) {
          _showError('Veuillez accepter les conditions générales');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_validateCurrentStep()) return;

    final request = RegisterRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      birthDate: DateFormat('yyyy-MM-dd').format(_birthDate!),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text,
      paymentMethod: _selectedPaymentMethod.value,
      paymentPhone: _paymentPhoneController.text.trim(),
    );

    await ref.read(registerProvider.notifier).register(request);

    final state = ref.read(registerProvider);
    if (mounted && state.status == RegisterStatus.error) {
      _showError(state.errorMessage ?? 'Erreur lors de l\'inscription');
    }
    // La navigation vers pending_payment est gérée via le consumer dans build()
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    // Rediriger vers l'écran de paiement en attente + afficher les erreurs.
    ref.listen(registerProvider, (_, next) {
      if (next.status == RegisterStatus.waitingPayment &&
          next.registration != null) {
        context.push('/payment-pending', extra: next.registration);
      }
      if (next.status == RegisterStatus.error &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        _showError(next.errorMessage!);
      }
    });

    final isLargeScreen = MediaQuery.of(context).size.width >= 800;
    final isLoading = registerState.status == RegisterStatus.loading;

    if (isLargeScreen) {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inscription'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SafeArea(child: _buildFormPanel(isLoading)),
    );
  }

  Widget _buildFormPanel(bool isLoading) {
    return Column(
      children: [
        // Stepper header
        _buildStepperHeader(),
        // Contenu de l'étape
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),
        ),
        // Navigation bas
        _buildNavigationButtons(isLoading),
      ],
    );
  }

  Widget _buildStepperHeader() {
    final steps = [
      ('Profil', Icons.person_outline_rounded),
      ('Sécurité', Icons.lock_outline_rounded),
      ('Paiement', Icons.payment_rounded),
    ];

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer votre compte',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (i) {
              final isActive = i == _currentStep;
              final isCompleted = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  isCompleted
                                      ? AppColors.success
                                      : isActive
                                      ? AppColors.primary
                                      : AppColors.border,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              isCompleted ? Icons.check_rounded : steps[i].$2,
                              color:
                                  isCompleted || isActive
                                      ? Colors.white
                                      : AppColors.textHint,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            steps[i].$1,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color:
                                  isActive
                                      ? AppColors.primary
                                      : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 2,
                            color:
                                isCompleted
                                    ? AppColors.success
                                    : AppColors.border,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ── ÉTAPE 1 : Informations personnelles ────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      children: [
        const AfosoSection(
          title: 'INFORMATIONS PERSONNELLES',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AfosoTextField(
                label: 'Prénom',
                hint: 'Jean',
                controller: _firstNameController,
                validator: (v) => Validators.name(v, fieldName: 'Le prénom'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AfosoTextField(
                label: 'Nom',
                hint: 'Kouamé',
                controller: _lastNameController,
                validator: (v) => Validators.name(v, fieldName: 'Le nom'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AfosoTextField(
                label: 'Téléphone',
                hint: '654345678',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AfosoTextField(
                label: 'Email',
                hint: 'jean@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de naissance',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _birthDate != null
                                ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                                : 'JJ/MM/AAAA',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color:
                                  _birthDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AfosoTextField(
                label: 'Ville',
                hint: 'Douala',
                controller: _cityController,
                validator: Validators.city,
                prefixIcon: const Icon(
                  Icons.location_city_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AfosoTextField(
          label: 'Adresse complète',
          hint: 'Quartier, rue, numéro...',
          controller: _addressController,
          validator: Validators.address,
          prefixIcon: const Icon(
            Icons.home_outlined,
            size: 20,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  // ── ÉTAPE 2 : Sécurité ─────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        const AfosoSection(
          title: 'SÉCURITÉ DU COMPTE',
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 16),
        AfosoTextField(
          label: 'Mot de passe',
          hint: '••••••••',
          controller: _passwordController,
          obscureText: true,
          showPasswordToggle: true,
          validator: Validators.password,
          onChanged: _onPasswordChanged,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 10),
        // Barre de force du mot de passe
        if (_passwordController.text.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passwordStrength / 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _passwordStrength <= 1
                          ? AppColors.danger
                          : _passwordStrength == 2
                          ? AppColors.warning
                          : _passwordStrength == 3
                          ? Colors.orange
                          : AppColors.success,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                passwordStrengthLabel(_passwordStrength),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      _passwordStrength <= 1
                          ? AppColors.danger
                          : _passwordStrength == 2
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        AfosoTextField(
          label: 'Confirmer le mot de passe',
          hint: '••••••••',
          controller: _confirmPasswordController,
          obscureText: true,
          showPasswordToggle: true,
          validator: Validators.confirmPassword(_passwordController.text),
          prefixIcon: const Icon(
            Icons.lock_person_outlined,
            size: 20,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 24),
        // Critères du mot de passe
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Critères du mot de passe',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              _CriteriaItem(
                label: 'Minimum 8 caractères',
                met: _passwordController.text.length >= 8,
              ),
              _CriteriaItem(
                label: 'Au moins une majuscule',
                met: _passwordController.text.contains(RegExp(r'[A-Z]')),
              ),
              _CriteriaItem(
                label: 'Au moins un chiffre',
                met: _passwordController.text.contains(RegExp(r'[0-9]')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ÉTAPE 3 : Paiement ─────────────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      children: [
        // Badge frais d'inscription
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Frais d\'inscription',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '1 000 FCFA',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const AfosoSection(
          title: 'MÉTHODE DE PAIEMENT',
          icon: Icons.payment_rounded,
        ),
        const SizedBox(height: 12),
        // Sélection méthode
        ...PaymentMethod.values.map((method) {
          final isSelected = _selectedPaymentMethod == method;
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = method),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySurface : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(method.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      method.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        AfosoTextField(
          label: 'Numéro de paiement',
          hint: '654345678',
          controller: _paymentPhoneController,
          keyboardType: TextInputType.phone,
          validator: Validators.phone,
          prefixIcon: const Icon(
            Icons.phone_outlined,
            size: 20,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 20),
        // Checkbox CGU
        GestureDetector(
          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _acceptedTerms ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        _acceptedTerms ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child:
                    _acceptedTerms
                        ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: "J'accepte les "),
                      TextSpan(
                        text: 'conditions générales',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' et la '),
                      TextSpan(
                        text: 'politique de confidentialité',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' d\'AFOSO'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isLoading) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          // Bouton précédent
          if (_currentStep > 0)
            Expanded(
              flex: 2,
              child: AfosoButton(
                label: 'Précédent',
                isOutlined: true,
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          // Bouton suivant / soumettre
          Expanded(
            flex: 3,
            child: AfosoButton(
              label:
                  _currentStep < 2
                      ? 'Continuer'
                      : "S'inscrire et payer 1 000 FCFA",
              isLoading: isLoading,
              onPressed: () {
                if (_currentStep < 2) {
                  if (_validateCurrentStep()) {
                    setState(() => _currentStep++);
                  }
                } else {
                  _handleSubmit();
                }
              },
              icon:
                  _currentStep < 2
                      ? const Icon(Icons.arrow_forward_rounded, size: 18)
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaItem extends StatelessWidget {
  final String label;
  final bool met;

  const _CriteriaItem({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 16,
              color: met ? AppColors.success : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: met ? AppColors.textPrimary : AppColors.textHint,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/network/api_client.dart';
import 'package:afoso1/core/utils/validators.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/core/widgets/custom_button.dart';
import 'package:afoso1/core/widgets/custom_text_field.dart';
import 'package:afoso1/features/auth/presentation/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final _accountStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final response = await ApiClient.instance.get('/api/accounts/stats');
  final json = response.data as Map<String, dynamic>;
  return json['data'] as Map<String, dynamic>? ?? {};
});

final _userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final response = await ApiClient.instance.get('/api/auth/me');
  final json = response.data as Map<String, dynamic>;
  return json['data'] as Map<String, dynamic>? ?? {};
});

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN PROFIL
// ─────────────────────────────────────────────────────────────────────────────

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _showChangePassword = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_userProfileProvider);
    final statsAsync = ref.watch(_accountStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(_userProfileProvider);
              ref.invalidate(_accountStatsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(_userProfileProvider);
          ref.invalidate(_accountStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar + infos identité ──────────────────────────────────
              profileAsync.when(
                loading: () => const _ProfileCardSkeleton(),
                error:
                    (e, _) => _ErrorCard(
                      msg: 'Impossible de charger le profil',
                      onRetry: () => ref.invalidate(_userProfileProvider),
                    ),
                data:
                    (profile) =>
                        FadeInDown(child: _ProfileCard(profile: profile)),
              ),
              const SizedBox(height: 20),

              // ── Stats financières ────────────────────────────────────────
              statsAsync.when(
                loading: () => const _StatsRowSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
                data:
                    (stats) => FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: _AccountStatsRow(stats: stats),
                    ),
              ),
              const SizedBox(height: 24),

              // ── Menu actions ─────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: _SectionTitle('Paramètres du compte'),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Changer le mot de passe',
                      color: AppColors.primary,
                      onTap:
                          () => setState(
                            () => _showChangePassword = !_showChangePassword,
                          ),
                      trailing: Icon(
                        _showChangePassword
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (_showChangePassword)
                      FadeInDown(
                        child: _ChangePasswordForm(
                          onSuccess:
                              () => setState(() => _showChangePassword = false),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _MenuTile(
                      icon: Icons.history_rounded,
                      label: 'Historique des transactions',
                      color: AppColors.warning,
                      onTap: () => context.go('/member/deposit'),
                    ),
                    const SizedBox(height: 4),
                    _MenuTile(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'Mes contributions solidaires',
                      color: AppColors.success,
                      onTap: () => context.go('/member/solidarity'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Déconnexion ──────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: AfosoButton(
                  label: 'Se déconnecter',
                  isOutlined: true,
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.danger,
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Déconnexion',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Voulez-vous vous déconnecter ?',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Déconnecter'),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS INTERNES
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['fullName'] as String? ?? 'Membre';
    final phone = profile['phone'] as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final matricule = profile['matricule'] as String? ?? '';
    final status = profile['status'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.dmSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (matricule.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Matricule : $matricule',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          // Infos
          if (phone.isNotEmpty)
            _InfoRow(icon: Icons.phone_outlined, value: phone),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.email_outlined, value: email),
          ],
          if (status.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusChip(status: status),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        color = AppColors.success;
        label = '✅ Compte actif';
        break;
      case 'INACTIVE':
        color = AppColors.textHint;
        label = '⏸ Inactif';
        break;
      case 'SUSPENDED':
        color = AppColors.danger;
        label = '🚫 Suspendu';
        break;
      default:
        color = AppColors.warning;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AccountStatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _AccountStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final balance = (stats['balance'] as num?)?.toDouble() ?? 0.0;
    final totalDeposits = (stats['totalDeposits'] as num?)?.toDouble() ?? 0.0;
    final txCount = (stats['transactionCount'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Solde',
            value: '${_fmt(balance)} F',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Total épargne',
            value: '${_fmt(totalDeposits)} F',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Transactions',
            value: '$txCount',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMULAIRE CHANGEMENT MOT DE PASSE
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _ChangePasswordForm({required this.onSuccess});

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldCtrl.text.isEmpty ||
        _newCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      _snack('Tous les champs sont requis', isError: true);
      return;
    }
    if (Validators.password(_newCtrl.text) != null) {
      _snack(
        'Nouveau mot de passe : min 8 car., 1 maj., 1 chiffre',
        isError: true,
      );
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _snack('Les mots de passe ne correspondent pas', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post(
        '/api/auth/change-password',
        data: {'oldPassword': _oldCtrl.text, 'newPassword': _newCtrl.text},
      );
      _snack('Mot de passe modifié avec succès 🔒');
      widget.onSuccess();
    } catch (e) {
      _snack(
        e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('ApiException: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          AfosoTextField(
            label: 'Mot de passe actuel',
            hint: '••••••••',
            controller: _oldCtrl,
            obscureText: true,
            showPasswordToggle: true,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          AfosoTextField(
            label: 'Nouveau mot de passe',
            hint: '••••••••',
            controller: _newCtrl,
            obscureText: true,
            showPasswordToggle: true,
            validator: Validators.password,
            prefixIcon: const Icon(
              Icons.lock_person_outlined,
              size: 18,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          AfosoTextField(
            label: 'Confirmer le nouveau',
            hint: '••••••••',
            controller: _confirmCtrl,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            prefixIcon: const Icon(
              Icons.lock_reset_rounded,
              size: 18,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          AfosoButton(
            label: 'Modifier le mot de passe',
            isLoading: _isLoading,
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETONS & ERREURS
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (_) => Expanded(
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorCard({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.dangerLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            msg,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.danger),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Réessayer',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    ),
  );
}

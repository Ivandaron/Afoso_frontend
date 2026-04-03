// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER local paginé
// ─────────────────────────────────────────────────────────────────────────────
import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final _allPendingProvider =
    FutureProvider.autoDispose<List<PendingRegistration>>((ref) async {
      return ref
          .read(adminRepositoryProvider)
          .getPendingRegistrations(size: 50);
    });

// ─────────────────────────────────────────────────────────────────────────────
// ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class AdminRegistrationsScreen extends ConsumerStatefulWidget {
  const AdminRegistrationsScreen({super.key});

  @override
  ConsumerState<AdminRegistrationsScreen> createState() =>
      _AdminRegistrationsScreenState();
}

class _AdminRegistrationsScreenState
    extends ConsumerState<AdminRegistrationsScreen> {
  String _search = '';

  void _onActionDone() {
    ref.invalidate(_allPendingProvider);
    ref.invalidate(pendingRegistrationsProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(_allPendingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inscriptions en attente'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_allPendingProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou téléphone…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: listAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error:
            (e, _) =>
                _ErrorState(onRetry: () => ref.invalidate(_allPendingProvider)),
        data: (all) {
          final filtered =
              _search.isEmpty
                  ? all
                  : all
                      .where(
                        (r) =>
                            r.fullName.toLowerCase().contains(_search) ||
                            (r.phone.isNotEmpty && r.phone.contains(_search)),
                      )
                      .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _search.isEmpty
                        ? 'Aucune inscription en attente 🎉'
                        : 'Aucun résultat pour "$_search"',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(_allPendingProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder:
                  (_, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 40),
                    child: _RegistrationCard(
                      registration: filtered[i],
                      onActionDone: _onActionDone,
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DE DEMANDE D'INSCRIPTION
// ─────────────────────────────────────────────────────────────────────────────
class _RegistrationCard extends ConsumerStatefulWidget {
  final PendingRegistration registration;
  final VoidCallback onActionDone;

  const _RegistrationCard({
    required this.registration,
    required this.onActionDone,
  });

  @override
  ConsumerState<_RegistrationCard> createState() => _RegistrationCardState();
}

class _RegistrationCardState extends ConsumerState<_RegistrationCard> {
  bool _isExpanded = false;
  bool _isProcessing = false;

  PendingRegistration get r => widget.registration;

  // ── Approbation ─────────────────────────────────────────────────────────────
  Future<void> _confirmAndApprove() async {
    final confirmed = await _showApproveDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveRegistration(r.id, notes: 'Approuvé via l\'application');
      if (mounted) {
        _snack('✅ ${r.fullName} a été approuvé(e) !');
        widget.onActionDone();
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showApproveDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête vert
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.success,
                        child: Text(
                          r.firstName.isNotEmpty
                              ? r.firstName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.dmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Approuver cette inscription ?',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Infos membre
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _InfoRow(
                        Icons.person_outline_rounded,
                        'Nom complet',
                        r.fullName.isNotEmpty ? r.fullName : '—',
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        Icons.phone_outlined,
                        'Téléphone',
                        r.phone.isNotEmpty ? r.phone : '—',
                      ),
                      if (r.email != null && r.email!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(Icons.email_outlined, 'Email', r.email!),
                      ],
                      if (r.city != null && r.city!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(Icons.location_on_outlined, 'Ville', r.city!),
                      ],
                      if (r.registrationFee != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          Icons.payment_rounded,
                          'Frais payés',
                          '${r.registrationFee!.toStringAsFixed(0)} FCFA',
                          valueColor: AppColors.success,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _InfoRow(
                        Icons.calendar_today_outlined,
                        'Demandé le',
                        _fmtDate(r.createdAt),
                      ),
                      const SizedBox(height: 10),
                      // Statut paiement
                      _PaymentStatusBadge(status: r.paymentStatus),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  // ── Rejet ───────────────────────────────────────────────────────────────────
  Future<void> _confirmAndReject() async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .rejectRegistration(r.id, reason: reason);
      if (mounted) {
        _snack('Inscription de ${r.fullName} rejetée');
        widget.onActionDone();
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final ctrl = TextEditingController();
    String? result;

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête rouge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.danger,
                        child: Text(
                          r.firstName.isNotEmpty
                              ? r.firstName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.dmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rejeter l\'inscription de\n${r.fullName} ?',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Récap + motif
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        Icons.phone_outlined,
                        'Téléphone',
                        r.phone.isNotEmpty ? r.phone : '—',
                      ),
                      if (r.city != null && r.city!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(Icons.location_on_outlined, 'Ville', r.city!),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Motif du rejet (obligatoire)',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ctrl,
                        maxLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText:
                              'Pièces manquantes, informations incorrectes, doublon…',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              StatefulBuilder(
                builder:
                    (ctx2, setSt) => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (ctrl.text.trim().isEmpty) {
                                setSt(
                                  () {},
                                ); // force rebuild pour afficher erreur
                                return;
                              }
                              result = ctrl.text.trim();
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Rejeter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
            ],
          ),
    );

    return result;
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

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header (toujours visible) ──────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      r.firstName.isNotEmpty
                          ? r.firstName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Nom + téléphone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.fullName.isNotEmpty ? r.fullName : '—',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              r.phone.isNotEmpty ? r.phone : '—',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (r.city != null && r.city!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  r.city!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _PaymentStatusBadge(
                        status: r.paymentStatus,
                        compact: true,
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Détails expandables ────────────────────────────────────────────
          if (_isExpanded) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grille infos
                  _InfoGrid(registration: r),
                  const SizedBox(height: 16),
                  // Actions
                  if (_isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _confirmAndReject,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Rejeter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _confirmAndApprove,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approuver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRILLE D'INFORMATIONS COMPLÈTE
// ─────────────────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final PendingRegistration registration;
  const _InfoGrid({required this.registration});

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = registration;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  icon: Icons.badge_outlined,
                  label: 'Prénom',
                  value: r.firstName.isNotEmpty ? r.firstName : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCell(
                  icon: Icons.person_outlined,
                  label: 'Nom',
                  value: r.lastName.isNotEmpty ? r.lastName : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            Icons.phone_outlined,
            'Téléphone',
            r.phone.isNotEmpty ? r.phone : '—',
          ),
          if (r.email != null && r.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(Icons.email_outlined, 'Email', r.email!),
          ],
          if (r.city != null && r.city!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(Icons.location_on_outlined, 'Ville', r.city!),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            Icons.calendar_today_outlined,
            'Demandé le',
            _fmtDate(r.createdAt),
          ),
          if (r.registrationFee != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              Icons.payment_rounded,
              'Frais payés',
              '${r.registrationFee!.toStringAsFixed(0)} FCFA',
              valueColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE STATUT PAIEMENT
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;
  const _PaymentStatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
        color = AppColors.success;
        label = compact ? '✓ Payé' : '✅ Paiement confirmé';
        icon = Icons.check_circle_outline;
        break;
      case 'FAILURE':
      case 'FAILED':
        color = AppColors.danger;
        label = compact ? '✗ Échoué' : '❌ Paiement échoué';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.warning;
        label = compact ? '⏳ En attente' : '⏳ Paiement en attente';
        icon = Icons.pending_outlined;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child:
          compact
              ? Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              )
              : Row(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// ÉTAT D'ERREUR
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.dmSans(color: AppColors.danger, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

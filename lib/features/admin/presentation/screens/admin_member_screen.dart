import 'dart:ui';

import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:afoso1/features/admin/data/models/admin_model.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:afoso1/features/admin/presentation/screens/member_contribution_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membersSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des membres'),
        actions: [
          IconButton(
            onPressed:
                () => ref.read(membersSearchProvider.notifier).search(_query),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => _query = v);
                // Debounce simple : on ne lance la recherche qu'à 3+ chars ou vide
                if (v.length >= 3 || v.isEmpty) {
                  ref.read(membersSearchProvider.notifier).search(v);
                }
              },
              onSubmitted:
                  (v) => ref.read(membersSearchProvider.notifier).search(v),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, matricule, téléphone…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon:
                    _query.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                            ref.read(membersSearchProvider.notifier).search('');
                          },
                        )
                        : null,
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
      body:
          state.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : state.error != null && state.members.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: GoogleFonts.dmSans(
                        color: AppColors.danger,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () => ref
                              .read(membersSearchProvider.notifier)
                              .search(_query),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : state.members.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _query.isEmpty
                          ? 'Aucun membre'
                          : 'Aucun résultat pour "$_query"',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Compteur
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${state.members.length} membre(s)',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (state.isLoading) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh:
                          () async => ref
                              .read(membersSearchProvider.notifier)
                              .search(_query),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.members.length,
                        itemBuilder:
                            (_, i) => FadeInUp(
                              delay: Duration(milliseconds: i * 30),
                              child: _MemberCard(
                                member: state.members[i],
                                onToggle:
                                    (active) => ref
                                        .read(membersSearchProvider.notifier)
                                        .toggleStatus(
                                          state.members[i].id,
                                          active,
                                        ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _MemberCard extends StatefulWidget {
  final AdminMember member;
  final Future<void> Function(bool active) onToggle;

  const _MemberCard({required this.member, required this.onToggle});

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _isExpanded = false;
  bool _toggling = false;

  Future<void> _handleToggle(bool newValue) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              newValue ? 'Activer le compte' : 'Désactiver le compte',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            content: Text(
              newValue
                  ? '${widget.member.fullName} pourra se connecter et utiliser l\'application.'
                  : '${widget.member.fullName} ne pourra plus se connecter.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      newValue ? AppColors.success : AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(newValue ? 'Activer' : 'Désactiver'),
              ),
            ],
          ),
    );

    if (ok == true && mounted) {
      setState(() => _toggling = true);
      await widget.onToggle(newValue);
      if (mounted) setState(() => _toggling = false);
    }
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  String _fmtBalance(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final isActive = m.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.textHint;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        isActive ? AppColors.primarySurface : AppColors.border,
                    child: Text(
                      m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color:
                            isActive ? AppColors.primary : AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.fullName,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.phone,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (m.matricule != null) ...[
                              const SizedBox(width: 8),
                              const Text(
                                '·',
                                style: TextStyle(color: AppColors.textHint),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                m.matricule!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // ── Solde visible directement ──────────────────────
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.balance != null
                                  ? '${_fmtBalance(m.balance!)} FCFA'
                                  : 'Solde : —',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    m.balance != null && m.balance! > 0
                                        ? AppColors.primary
                                        : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status + expand
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
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
                children: [
                  // Infos
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.person_outlined,
                          label: 'Statut',
                          value: m.status,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (m.city != null)
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: 'Ville',
                            value: m.city!,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (m.email != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: m.email!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Inscrit le',
                    value: _formatDate(m.createdAt),
                  ),
                  if (m.balance != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Solde',
                      value: '${m.balance!.toStringAsFixed(0)} FCFA',
                      valueColor: AppColors.primary,
                    ),
                  ],
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MemberContributionHistoryScreen(
                                memberId: m.id,
                                memberName: m.fullName,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Voir le détail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Toggle actif / inactif
                  if (_toggling)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child:
                              isActive
                                  ? OutlinedButton.icon(
                                    onPressed: () => _handleToggle(false),
                                    icon: const Icon(
                                      Icons.pause_circle_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Désactiver'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.warning,
                                      side: const BorderSide(
                                        color: AppColors.warning,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )
                                  : ElevatedButton.icon(
                                    onPressed: () => _handleToggle(true),
                                    icon: const Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Activer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textHint),
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

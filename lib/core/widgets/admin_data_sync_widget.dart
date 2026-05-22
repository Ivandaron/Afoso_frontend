import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/core/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDataSyncWidget extends ConsumerStatefulWidget {
  const AdminDataSyncWidget({super.key});

  @override
  ConsumerState<AdminDataSyncWidget> createState() =>
      _AdminDataSyncWidgetState();
}

class _AdminDataSyncWidgetState extends ConsumerState<AdminDataSyncWidget> {
  bool _isSyncing = false;
  String? _lastSyncDate;
  int _pendingImports = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
  }

  Future<void> _loadSyncInfo() async {
    // Charger les infos de synchronisation
    // À implémenter avec votre API
  }

  Future<void> _syncAllData() async {
    setState(() => _isSyncing = true);
    try {
      // Appel API pour synchroniser toutes les données
      // final response = await _api.post('/api/admin/sync-all-data');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _showSnackBar('✅ Synchronisation terminée avec succès');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Erreur lors de la synchronisation', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synchronisation des données',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastSyncDate != null
                      ? 'Dernière sync: $_lastSyncDate'
                      : 'Importez les données Excel pour synchroniser',
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                if (_pendingImports > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_pendingImports import(s) en attente',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isSyncing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _syncAllData,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Sync'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

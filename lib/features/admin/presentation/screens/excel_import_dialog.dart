// excel_import_dialog.dart - Nouveau fichier
import 'dart:io';
import 'package:afoso1/core/constants/app_colors.dart';
import 'package:afoso1/features/admin/data/admin_repository.dart';
import 'package:afoso1/features/admin/presentation/providers/admin_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;

Future<void> _showExcelImportDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<ExcelImportResult?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ExcelImportDialogContent(),
  );

  if (result != null && context.mounted) {
    // Rafraîchir le dashboard après import
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(membersSearchProvider);

    // Afficher le résumé de l'import
    _showImportSummaryDialog(context, result);
  }
}

class _ExcelImportDialogContent extends ConsumerStatefulWidget {
  const _ExcelImportDialogContent();

  @override
  ConsumerState<_ExcelImportDialogContent> createState() =>
      _ExcelImportDialogContentState();
}

class _ExcelImportDialogContentState
    extends ConsumerState<_ExcelImportDialogContent> {
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _importFile() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    await ref
        .read(excelImportProvider.notifier)
        .importFile(_selectedFile!.path, path.basename(_selectedFile!.path));

    final state = ref.read(excelImportProvider);
    if (mounted) {
      if (state.status == ExcelImportStatus.success) {
        Navigator.of(context).pop(state.result);
      } else if (state.status == ExcelImportStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Erreur lors de l\'import'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(excelImportProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_upload_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import Excel des membres',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description du format attendu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Format attendu du fichier Excel:',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FormatRow('A', 'Prénom', 'obligatoire'),
                  _FormatRow('B', 'Nom', 'obligatoire'),
                  _FormatRow('C', 'Téléphone', 'obligatoire'),
                  _FormatRow('D', 'Email', 'obligatoire'),
                  _FormatRow('E', 'Date naissance (YYYY-MM-DD)', 'obligatoire'),
                  _FormatRow('F', 'Ville', 'obligatoire'),
                  _FormatRow('G', 'Adresse', 'optionnel'),
                  _FormatRow(
                    'H',
                    'Solde du compte (FCFA)',
                    'optionnel, défaut 0',
                  ),
                  _FormatRow('I', 'N° compte original', 'optionnel'),
                  _FormatRow('J', 'ID membre original', 'optionnel'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Zone de sélection de fichier
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.file_present_rounded
                          : Icons.upload_file_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null
                          ? path.basename(_selectedFile!.path)
                          : 'Cliquez pour sélectionner un fichier Excel',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color:
                            _selectedFile != null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progression
            if (importState.status == ExcelImportStatus.loading) ...[
              LinearProgressIndicator(value: importState.progress),
              const SizedBox(height: 12),
              Text(
                'Import en cours... ${(importState.progress * 100).toInt()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isUploading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_selectedFile == null || _isUploading)
                            ? null
                            : _importFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Importer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final String column;
  final String field;
  final String requirement;

  const _FormatRow(this.column, this.field, this.requirement);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                column,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            field,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  requirement == 'obligatoire'
                      ? AppColors.dangerLight
                      : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              requirement,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color:
                    requirement == 'obligatoire'
                        ? AppColors.danger
                        : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showImportSummaryDialog(BuildContext context, ExcelImportResult result) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                result.failedImports > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color:
                    result.failedImports > 0
                        ? AppColors.warning
                        : AppColors.success,
              ),
              const SizedBox(width: 10),
              Text('Résultat de l\'import'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow('Fichier', result.fileName),
              _SummaryRow(
                'Total enregistrements',
                result.totalRecords.toString(),
              ),
              _SummaryRow(
                'Importés avec succès',
                result.successfulImports.toString(),
                color: AppColors.success,
              ),
              _SummaryRow(
                'Échecs',
                result.failedImports.toString(),
                color: result.failedImports > 0 ? AppColors.danger : null,
              ),
              if (result.errors.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Détails des erreurs:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        result.errors.length > 5 ? 5 : result.errors.length,
                    itemBuilder:
                        (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${result.errors[i]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                  ),
                ),
                if (result.errors.length > 5)
                  Text(
                    '... et ${result.errors.length - 5} autre(s) erreur(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

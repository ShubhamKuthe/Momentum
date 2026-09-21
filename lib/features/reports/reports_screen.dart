import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/theme/app_theme.dart';
import '../../models/report_file_entry.dart';
import '../../services/database_service.dart';
import '../../services/export_service.dart';
import '../../state/habit_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.provider,
  });

  final HabitProvider provider;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  List<ReportFileEntry> _reports = <ReportFileEntry>[];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await _databaseService.getReportFiles();
    if (!mounted) {
      return;
    }

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _saveReport() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final savedPath = await ExportService.instance.exportDoctorReadyWorkbook(
        widget.provider,
      );
      await _loadReports();
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null || savedPath.isEmpty
                ? 'Momentum Report exported'
                : 'Momentum Report saved',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openReport(ReportFileEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = entry.path.trim();
    if (path.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This report is not available.')),
      );
      return;
    }

    if (!path.startsWith('content://')) {
      final exists = await File(path).exists();
      if (!exists) {
        await _databaseService.removeReportFile(path);
        await _loadReports();
        if (!mounted) {
          return;
        }

        messenger.showSnackBar(
          const SnackBar(content: Text('Report file was not found on device.')),
        );
        return;
      }
    }

    final result = await OpenFilex.open(path);
    if (!mounted) {
      return;
    }

    if (result.type != ResultType.done) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.message.trim().isNotEmpty
                ? result.message
                : 'Could not open this report.',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmDelete(ReportFileEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete report?'),
          content: Text(
            'Remove ${entry.displayName} from Momentum Reports?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _deleteReport(ReportFileEntry entry) async {
    final path = entry.path.trim();
    if (path.isNotEmpty && !path.startsWith('content://')) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    await _databaseService.removeReportFile(path);
    await _loadReports();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.displayName} deleted')),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year}  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Momentum Reports'),
        backgroundColor: palette.background,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All downloaded report files are saved here.',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap any report to open it.',
                    style: TextStyle(
                      color: palette.textSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveReport,
                      child: Text(
                        _isSaving
                            ? 'Saving Momentum Report...'
                            : 'Save Momentum Report',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'SAVED FILES',
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reports.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 34,
                      color: palette.textSoft,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reports saved yet',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Save your first Momentum Report and it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._reports.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(entry.path),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(entry),
                    onDismissed: (_) => _deleteReport(entry),
                    background: Container(
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _openReport(entry),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: context.isMomentumDark
                                    ? palette.accentSoft
                                    : AppColors.emberDim,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.table_chart_rounded,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(entry.createdAt),
                                    style: TextStyle(
                                      color: palette.textSoft,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: palette.textSoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

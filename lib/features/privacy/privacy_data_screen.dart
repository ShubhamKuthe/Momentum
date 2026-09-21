import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/habit_provider.dart';
import '../reports/reports_screen.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final palette = context.momentum;
        const privacySummary =
            'Momentum uses a minimal backend for registration and account access, while personal habit data stays on the device unless the user exports it.';

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: const Text('Privacy & Data'),
            backgroundColor: palette.background,
          ),
          body: RefreshIndicator(
            onRefresh: provider.refreshSyncedData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOCAL-FIRST BY DESIGN',
                        style: TextStyle(
                          color: palette.textSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        privacySummary,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Stored in backend'),
                const SizedBox(height: 10),
                const _DataCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Account access only',
                  items: [
                    'Name and email used for sign-in',
                    'Password stored securely by the auth system',
                    'Basic account access metadata if needed later',
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Stored on device'),
                const SizedBox(height: 10),
                const _DataCard(
                  icon: Icons.smartphone_rounded,
                  title: 'Personal habit data',
                  items: [
                    'Habits and cue/trigger text',
                    'Progress logs and streak history',
                    'Adaptive goal suggestions and approvals',
                    'Reminder preferences and health sync state',
                    'Weekly reports and behavior insights',
                  ],
                ),
                const SizedBox(height: 18),
                const _SectionLabel('User control'),
                const SizedBox(height: 10),
                const _DataCard(
                  icon: Icons.download_rounded,
                  title: 'Export when you choose',
                  items: [
                    'No habit logs are uploaded by default',
                    'Research-ready CSV export is manual',
                    'Users keep control over when data leaves the device',
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isMomentumDark
                        ? palette.successSoft
                        : AppColors.mossDim,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Why this matters: even if a backend account is compromised, the user personal behavior history is not automatically exposed because it remains local-first in this Momentum build.',
                    style: TextStyle(
                      color: palette.success,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.text,
                      foregroundColor: palette.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(
                          const ClipboardData(text: privacySummary));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Privacy summary copied')),
                        );
                      }
                    },
                    child: const Text('Copy privacy summary'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                      side: BorderSide(color: palette.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportsScreen(provider: provider),
                        ),
                      );
                    },
                    child: const Text('Open Momentum Reports'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: palette.textSoft,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.isMomentumDark
                      ? palette.accentSoft
                      : AppColors.emberDim,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.moss,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

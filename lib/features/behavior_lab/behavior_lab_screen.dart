import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/habit_provider.dart';

class BehaviorLabScreen extends StatelessWidget {
  const BehaviorLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final palette = context.momentum;
        final insights = provider.overallBehaviorInsights();
        final summaryText = [
          'Best window: ${provider.bestWindowOverall()}',
          'Logs stored: ${provider.totalLogsCount()}',
          'Adaptive trail: ${provider.adaptiveDecisionsCount()}',
          'Active habits: ${provider.habits.length}',
          '',
          ...insights,
        ].join('\n');

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: const Text('Behavior Lab'),
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
                      'LOCAL-FIRST COACHING',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Momentum learns from cues, completion timing, and your adaptive-goal decisions while keeping personal habit data local-first. A backend can handle account access separately from this behavior history.',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      provider.researchModeSummary(),
                      style: TextStyle(
                        color: palette.textSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _EvidenceCard(
                      label: 'Best window',
                      value: provider.bestWindowOverall(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EvidenceCard(
                      label: 'Logs stored',
                      value: '${provider.totalLogsCount()}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _EvidenceCard(
                      label: 'Adaptive trail',
                      value: '${provider.adaptiveDecisionsCount()}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EvidenceCard(
                      label: 'Active habits',
                      value: '${provider.habits.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'BEHAVIOR INSIGHTS',
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...insights.map((insight) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: context.isMomentumDark
                              ? palette.successSoft
                              : AppColors.mossDim,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          color: palette.success,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight,
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
              const SizedBox(height: 12),
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
                    await Clipboard.setData(ClipboardData(text: summaryText));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Behavior summary copied')),
                      );
                    }
                  },
                  child: const Text('Copy behavior summary'),
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

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

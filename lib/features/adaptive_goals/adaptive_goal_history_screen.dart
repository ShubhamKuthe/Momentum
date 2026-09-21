import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/adaptive_goal_entry.dart';

class AdaptiveGoalHistoryScreen extends StatelessWidget {
  const AdaptiveGoalHistoryScreen({
    super.key,
    required this.entries,
  });

  final List<AdaptiveGoalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Adaptive goal history')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Momentum keeps a visible record of every proposed goal change so approval decisions can be demonstrated clearly.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.slate,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          if (sortedEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: const Column(
                children: [
                  Icon(Icons.timeline_rounded, size: 34, color: AppColors.slate),
                  SizedBox(height: 12),
                  Text(
                    'No adaptive suggestions yet',
                    style: TextStyle(
                      color: AppColors.inkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Once Momentum proposes a target change, it will appear here with the date and approval status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            )
          else
            ...sortedEntries.map((entry) => _HistoryCard(entry: entry)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final AdaptiveGoalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${entry.oldTarget} -> ${entry.suggestedTarget}',
                style: const TextStyle(
                  color: AppColors.inkText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _StatusPill(status: entry.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMd().add_jm().format(entry.createdAt),
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Old target ${entry.oldTarget}, suggested ${entry.suggestedTarget}.',
            style: const TextStyle(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'accepted' => AppColors.mossDim,
      'rejected' => AppColors.emberDim,
      'kept' => AppColors.paperDim,
      _ => AppColors.paperDim,
    };
    final textColor = switch (status) {
      'accepted' => AppColors.moss,
      'rejected' => AppColors.ember,
      'kept' => AppColors.inkText,
      _ => AppColors.inkText,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

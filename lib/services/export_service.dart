import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:syncfusion_officechart/officechart.dart';

import '../core/habits/habit_customization.dart';
import '../models/adaptive_goal_entry.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/report_file_entry.dart';
import '../state/habit_provider.dart';
import 'database_service.dart';

class ExportService {
  ExportService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  static ExportService get instance => ExportService();

  final DatabaseService _databaseService;

  final DateFormat _displayDate = DateFormat('dd MMM yyyy');
  final DateFormat _displayDateTime = DateFormat('dd MMM yyyy, HH:mm');
  final DateFormat _exportStamp = DateFormat('yyyy-MM-dd_HHmm');
  final DateFormat _compactDate = DateFormat('dd MMM');
  final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  Future<String?> exportDoctorReadyWorkbook(HabitProvider provider) async {
    final identity = await _loadIdentity();
    final habits = provider.habits.toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    final logs = _collectLogs(provider, habits);
    final adaptiveEntries = provider.allAdaptiveGoalEntries();
    final stepHistory = provider.stepHistoryForRecentDays(days: 30);

    final workbook = Workbook();
    try {
      final summarySheet = workbook.worksheets[0];
      summarySheet.name = 'Summary';
      final habitSheet = workbook.worksheets.addWithName('Habit Summary');
      final logsSheet = workbook.worksheets.addWithName('Daily Logs');
      final adaptiveSheet = workbook.worksheets.addWithName('Adaptive Goals');
      final analyticsSheet = workbook.worksheets.addWithName('Analytics');
      final syncSheet = workbook.worksheets.addWithName('Health Sync');

      _buildSummarySheet(
        sheet: summarySheet,
        provider: provider,
        identity: identity,
      );
      _buildHabitSummarySheet(
        sheet: habitSheet,
        provider: provider,
        habits: habits,
      );
      _buildLogsSheet(
        sheet: logsSheet,
        provider: provider,
        logs: logs,
      );
      _buildAdaptiveSheet(
        sheet: adaptiveSheet,
        habits: habits,
        entries: adaptiveEntries,
      );
      _buildAnalyticsSheet(
        sheet: analyticsSheet,
        provider: provider,
        habits: habits,
        stepHistory: stepHistory,
      );
      _buildHealthSyncSheet(
        sheet: syncSheet,
        provider: provider,
        identity: identity,
        stepHistory: stepHistory,
      );

      final bytes = Uint8List.fromList(workbook.saveSync());
      final filename = 'Momentum Report ${_exportStamp.format(DateTime.now())}';

      String? savedPath;
      try {
        savedPath = await FileSaver.instance.saveAs(
          name: filename,
          bytes: bytes,
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } catch (_) {
        savedPath = null;
      }

      savedPath ??= await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      final localReportPath = await _saveLocalReportCopy(
        bytes: bytes,
        filename: '$filename.xlsx',
      );

      if (localReportPath.trim().isNotEmpty) {
        await _databaseService.saveReportFile(
          ReportFileEntry(
            path: localReportPath,
            displayName: '$filename.xlsx',
            createdAt: DateTime.now(),
            fileExtension: 'xlsx',
          ),
        );
      }

      return savedPath.trim().isNotEmpty ? savedPath : localReportPath;
    } finally {
      workbook.dispose();
    }
  }

  Future<String> _saveLocalReportCopy({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDirectory = Directory(
        path.join(directory.path, 'momentum_reports'),
      );
      if (!await reportsDirectory.exists()) {
        await reportsDirectory.create(recursive: true);
      }

      final reportFile = File(path.join(reportsDirectory.path, filename));
      await reportFile.writeAsBytes(bytes, flush: true);
      return reportFile.path;
    } catch (_) {
      return '';
    }
  }

  Future<_ExportIdentity> _loadIdentity() async {
    final name = await _databaseService.getUserName();
    final email = await _databaseService.getUserEmail();
    final gender = await _databaseService.getUserGender();
    final dob = await _databaseService.getUserDob();
    final startDate = await _databaseService.getUserStartDate();
    return _ExportIdentity(
      name: name.trim().isEmpty ? 'Momentum User' : name.trim(),
      email: email.trim(),
      gender: gender.trim(),
      dateOfBirth: dob,
      startDate: startDate,
    );
  }

  List<_LogExportRow> _collectLogs(
    HabitProvider provider,
    List<Habit> habits,
  ) {
    final rows = <_LogExportRow>[];
    for (final habit in habits) {
      for (final log in provider.logsForHabit(habit.id)) {
        rows.add(_LogExportRow(habit: habit, log: log));
      }
    }
    rows.sort((left, right) => right.log.date.compareTo(left.log.date));
    return rows;
  }

  void _buildSummarySheet({
    required Worksheet sheet,
    required HabitProvider provider,
    required _ExportIdentity identity,
  }) {
    sheet.getRangeByIndex(1, 1, 1, 8).merge();
    final titleCell = sheet.getRangeByIndex(1, 1);
    titleCell.setText('Momentum Doctor-Ready Report');
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontSize = 20;
    titleCell.cellStyle.fontColorRgb = const Color(0xFF1E2533);
    titleCell.cellStyle.backColorRgb = const Color(0xFFF7F1E8);
    titleCell.cellStyle.hAlign = HAlignType.center;
    titleCell.cellStyle.vAlign = VAlignType.center;
    titleCell.rowHeight = 28;

    sheet.getRangeByIndex(2, 1, 2, 8).merge();
    final subtitleCell = sheet.getRangeByIndex(2, 1);
    subtitleCell.setText(
      'Local-first habit history export for review, supervision, or wellbeing check-ins.',
    );
    subtitleCell.cellStyle.fontColorRgb = const Color(0xFF626C7B);
    subtitleCell.cellStyle.hAlign = HAlignType.center;

    _writeSectionHeader(sheet, row: 4, title: 'Patient / User');
    _writeKeyValue(sheet, row: 5, label: 'Name', value: identity.name);
    _writeKeyValue(
      sheet,
      row: 6,
      label: 'Email',
      value: identity.email.isEmpty ? 'Not provided' : identity.email,
    );
    _writeKeyValue(
      sheet,
      row: 7,
      label: 'Gender',
      value: identity.gender.isEmpty ? 'Not added' : identity.gender,
    );
    _writeKeyValue(
      sheet,
      row: 8,
      label: 'Date of birth',
      value: identity.dateOfBirth == null
          ? 'Not added'
          : _displayDate.format(identity.dateOfBirth!),
    );
    _writeKeyValue(
      sheet,
      row: 9,
      label: 'Started using Momentum',
      value: identity.startDate == null
          ? 'Not recorded'
          : _displayDate.format(identity.startDate!),
    );
    _writeKeyValue(
      sheet,
      row: 10,
      label: 'Report generated',
      value: _displayDateTime.format(DateTime.now()),
    );

    _writeSectionHeader(sheet, row: 12, title: 'Clinical / Progress Snapshot');
    _writeMetricCard(
      sheet,
      row: 13,
      column: 1,
      label: 'Active habits',
      value: provider.habits.length.toString(),
    );
    _writeMetricCard(
      sheet,
      row: 13,
      column: 3,
      label: '7-day completion',
      value: '${(provider.completionPercentageLast7Days() * 100).round()}%',
    );
    _writeMetricCard(
      sheet,
      row: 13,
      column: 5,
      label: 'Best streak',
      value: '${provider.bestOverallStreak()} days',
    );
    _writeMetricCard(
      sheet,
      row: 13,
      column: 7,
      label: 'Progress logs',
      value: provider.totalLogsCount().toString(),
    );

    _writeMetricCard(
      sheet,
      row: 17,
      column: 1,
      label: 'Adaptive decisions',
      value: provider.adaptiveDecisionsCount().toString(),
    );
    _writeMetricCard(
      sheet,
      row: 17,
      column: 3,
      label: 'Automaticity score',
      value: provider.overallAutomaticityScore().round().toString(),
    );
    _writeMetricCard(
      sheet,
      row: 17,
      column: 5,
      label: 'Best time window',
      value: provider.bestWindowOverall(),
    );
    _writeMetricCard(
      sheet,
      row: 17,
      column: 7,
      label: 'Health sync',
      value: provider.healthSyncSnapshot.connected
          ? provider.healthSyncSnapshot.sourceLabel
          : 'Not connected',
    );

    _writeSectionHeader(sheet, row: 21, title: 'Behavior Notes');
    _writeParagraph(
      sheet,
      row: 22,
      text: provider.todayPatternSummary(),
    );
    _writeParagraph(
      sheet,
      row: 24,
      text: provider.weeklyMotivationalFeedback(),
      accent: true,
    );

    final insights = provider.overallBehaviorInsights();
    var row = 27;
    _writeSectionHeader(sheet, row: row, title: 'Top observations');
    row += 1;
    for (final insight in insights) {
      _writeBullet(sheet, row: row, text: insight);
      row += 2;
    }

    for (var column = 1; column <= 8; column++) {
      sheet.autoFitColumn(column);
    }
    sheet.getRangeByIndex(1, 1).columnWidth = 24;
    sheet.getRangeByIndex(1, 2).columnWidth = 18;
    for (var column = 3; column <= 8; column++) {
      sheet.getRangeByIndex(1, column).columnWidth = 18;
    }
  }

  void _buildHabitSummarySheet({
    required Worksheet sheet,
    required HabitProvider provider,
    required List<Habit> habits,
  }) {
    const headers = <String>[
      'Habit',
      'Category',
      'Target',
      'Unit',
      'Frequency',
      'Cue',
      'Today',
      '7d completed',
      'Avg 7d %',
      'Current streak',
      'Best streak',
      'Automaticity',
      'Cue strength',
      'Best window',
      'Reminder',
      'Mode',
      'Manual log',
      'Last completed',
    ];

    _writeTableHeader(sheet, row: 1, headers: headers);
    var row = 2;
    for (final habit in habits) {
      final category = resolvedHabitCategory(habit).label;
      final reminder = habit.reminderTime == null
          ? 'Not set'
          : _formatReminderTime(habit.reminderTime!);
      final values = <String>[
        habit.name,
        category,
        habit.targetValue.toString(),
        habit.unit,
        habit.frequency,
        habit.cue,
        provider.progressForToday(habit).toString(),
        provider.completionDaysLast7(habit).toString(),
        '${(provider.averageRatioForHabit(habit) * 100).round()}%',
        habit.currentStreak.toString(),
        habit.bestStreak.toString(),
        provider.automaticityScore(habit).round().toString(),
        '${provider.cueStrengthScore(habit)} (${provider.cueStrengthLabel(habit)})',
        provider.bestWindowForHabit(habit),
        reminder,
        habit.reminderMode,
        habit.manualLoggingEnabled ? 'Enabled' : 'Off',
        habit.lastCompletedDate == null
            ? '-'
            : _displayDate.format(habit.lastCompletedDate!),
      ];
      _writeTableRow(sheet, row: row, values: values);
      row++;
    }

    if (habits.isEmpty) {
      _writeTableRow(
        sheet,
        row: row,
        values: List<String>.filled(headers.length, ''),
      );
      sheet.getRangeByIndex(row, 1).setText('No habits added yet');
    }

    for (var column = 1; column <= headers.length; column++) {
      sheet.autoFitColumn(column);
    }
    for (var column = 1; column <= headers.length; column++) {
      sheet.getRangeByIndex(1, column).columnWidth = 18;
    }
  }

  void _buildLogsSheet({
    required Worksheet sheet,
    required HabitProvider provider,
    required List<_LogExportRow> logs,
  }) {
    const headers = <String>[
      'Habit',
      'Category',
      'Date',
      'Time',
      'Value',
      'Unit',
      'Source',
      'Time window',
      'Progress %',
      'Habit ID',
      'Log ID',
    ];

    _writeTableHeader(sheet, row: 1, headers: headers);
    var row = 2;
    for (final record in logs) {
      final progressRatio = record.habit.targetValue <= 0
          ? 0
          : ((record.log.value / record.habit.targetValue) * 100).round();
      _writeTableRow(
        sheet,
        row: row,
        values: [
          record.habit.name,
          resolvedHabitCategory(record.habit).label,
          _displayDate.format(record.log.date),
          DateFormat('HH:mm').format(record.log.date),
          record.log.value.toString(),
          record.habit.unit,
          record.log.isManualEntry ? 'Manual' : 'Synced',
          _windowForHour(record.log.date.hour),
          '$progressRatio%',
          record.habit.id,
          record.log.id,
        ],
      );
      row++;
    }

    if (logs.isEmpty) {
      _writeTableRow(
        sheet,
        row: row,
        values: List<String>.filled(headers.length, ''),
      );
      sheet.getRangeByIndex(row, 1).setText('No progress logs yet');
    }

    for (var column = 1; column <= headers.length; column++) {
      sheet.autoFitColumn(column);
    }
  }

  void _buildAdaptiveSheet({
    required Worksheet sheet,
    required List<Habit> habits,
    required List<AdaptiveGoalEntry> entries,
  }) {
    const headers = <String>[
      'Habit',
      'Date',
      'Old target',
      'Suggested target',
      'Status',
      'Habit ID',
      'Entry ID',
    ];

    final habitLookup = <String, Habit>{
      for (final habit in habits) habit.id: habit,
    };

    _writeTableHeader(sheet, row: 1, headers: headers);
    var row = 2;
    for (final entry in entries) {
      final habit = habitLookup[entry.habitId];
      _writeTableRow(
        sheet,
        row: row,
        values: [
          habit?.name ?? 'Unknown habit',
          _displayDateTime.format(entry.createdAt),
          entry.oldTarget.toString(),
          entry.suggestedTarget.toString(),
          entry.status,
          entry.habitId,
          entry.id,
        ],
      );
      row++;
    }

    if (entries.isEmpty) {
      _writeTableRow(
        sheet,
        row: row,
        values: List<String>.filled(headers.length, ''),
      );
      sheet.getRangeByIndex(row, 1).setText('No adaptive goal history yet');
    }

    for (var column = 1; column <= headers.length; column++) {
      sheet.autoFitColumn(column);
    }
  }

  void _buildAnalyticsSheet({
    required Worksheet sheet,
    required HabitProvider provider,
    required List<Habit> habits,
    required Map<DateTime, int> stepHistory,
  }) {
    _writeSectionHeader(sheet, row: 1, title: '30-day completion trend');
    _writeTableHeader(sheet, row: 2, headers: const ['Date', 'Completion %']);
    final overallRatios = provider.last30OverallRatios();
    for (var index = 0; index < overallRatios.length; index++) {
      final row = 3 + index;
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      _writeTableRow(
        sheet,
        row: row,
        values: [
          _compactDate.format(date),
          (overallRatios[index] * 100).round().toString(),
        ],
      );
    }

    _writeSectionHeader(sheet, row: 1, column: 4, title: '30-day step history');
    _writeTableHeader(sheet,
        row: 2, column: 4, headers: const ['Date', 'Steps']);
    final sortedSteps = stepHistory.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (var index = 0; index < sortedSteps.length; index++) {
      final row = 3 + index;
      _writeTableRow(
        sheet,
        row: row,
        column: 4,
        values: [
          _compactDate.format(sortedSteps[index].key),
          sortedSteps[index].value.toString(),
        ],
      );
    }

    _writeSectionHeader(sheet, row: 1, column: 7, title: 'Habit comparison');
    _writeTableHeader(
      sheet,
      row: 2,
      column: 7,
      headers: const ['Habit', '7-day %', 'Streak'],
    );
    for (var index = 0; index < habits.length; index++) {
      final row = 3 + index;
      final habit = habits[index];
      _writeTableRow(
        sheet,
        row: row,
        column: 7,
        values: [
          habit.name,
          (provider.averageRatioForHabit(habit) * 100).round().toString(),
          habit.currentStreak.toString(),
        ],
      );
    }
    if (habits.isEmpty) {
      _writeTableRow(
        sheet,
        row: 3,
        column: 7,
        values: const ['No habits', '0', '0'],
      );
    }

    final charts = ChartCollection(sheet);

    final completionChart = charts.add();
    completionChart.chartType = ExcelChartType.line;
    completionChart.dataRange = sheet.getRangeByName('A2:B32');
    completionChart.chartTitle = 'Completion trend';
    completionChart.hasLegend = false;
    completionChart.topRow = 1;
    completionChart.leftColumn = 10;
    completionChart.bottomRow = 16;
    completionChart.rightColumn = 17;

    final stepChart = charts.add();
    stepChart.chartType = ExcelChartType.column;
    stepChart.dataRange = sheet.getRangeByName(
        'D2:E${sortedSteps.isEmpty ? 3 : sortedSteps.length + 2}');
    stepChart.chartTitle = 'Step history';
    stepChart.hasLegend = false;
    stepChart.topRow = 18;
    stepChart.leftColumn = 10;
    stepChart.bottomRow = 33;
    stepChart.rightColumn = 17;

    final habitChart = charts.add();
    habitChart.chartType = ExcelChartType.bar;
    habitChart.dataRange =
        sheet.getRangeByName('G2:H${habits.isEmpty ? 3 : habits.length + 2}');
    habitChart.chartTitle = 'Habit consistency';
    habitChart.hasLegend = false;
    habitChart.topRow = 35;
    habitChart.leftColumn = 10;
    habitChart.bottomRow = 50;
    habitChart.rightColumn = 17;

    sheet.charts = charts;

    for (var column = 1; column <= 9; column++) {
      sheet.autoFitColumn(column);
    }
    sheet.getRangeByIndex(1, 1).columnWidth = 12;
    sheet.getRangeByIndex(1, 4).columnWidth = 12;
    sheet.getRangeByIndex(1, 7).columnWidth = 20;
  }

  void _buildHealthSyncSheet({
    required Worksheet sheet,
    required HabitProvider provider,
    required _ExportIdentity identity,
    required Map<DateTime, int> stepHistory,
  }) {
    final snapshot = provider.healthSyncSnapshot;
    _writeSectionHeader(sheet, row: 1, title: 'Health sync overview');
    _writeKeyValue(sheet, row: 2, label: 'User', value: identity.name);
    _writeKeyValue(
      sheet,
      row: 3,
      label: 'Source',
      value: snapshot.sourceLabel,
    );
    _writeKeyValue(
      sheet,
      row: 4,
      label: 'Connected',
      value: snapshot.connected ? 'Yes' : 'No',
    );
    _writeKeyValue(
      sheet,
      row: 5,
      label: 'Permission',
      value: snapshot.permissionState,
    );
    _writeKeyValue(
      sheet,
      row: 6,
      label: 'Availability',
      value: snapshot.availability,
    );
    _writeKeyValue(
      sheet,
      row: 7,
      label: 'Last sync',
      value: snapshot.lastSyncedAt == null
          ? 'Never'
          : _displayDateTime.format(snapshot.lastSyncedAt!),
    );
    _writeKeyValue(
      sheet,
      row: 8,
      label: 'Last synced steps',
      value: (snapshot.lastSyncedSteps ?? 0).toString(),
    );
    _writeKeyValue(
      sheet,
      row: 9,
      label: 'Last error',
      value: snapshot.lastError?.isEmpty ?? true ? 'None' : snapshot.lastError!,
    );

    _writeSectionHeader(sheet, row: 11, title: 'Recent synced step calendar');
    _writeTableHeader(sheet, row: 12, headers: const ['Date', 'Steps']);
    final sortedEntries = stepHistory.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    var row = 13;
    for (final entry in sortedEntries) {
      _writeTableRow(
        sheet,
        row: row,
        values: [
          _isoDate.format(entry.key),
          entry.value.toString(),
        ],
      );
      row++;
    }

    for (var column = 1; column <= 2; column++) {
      sheet.autoFitColumn(column);
    }
  }

  void _writeSectionHeader(
    Worksheet sheet, {
    required int row,
    int column = 1,
    required String title,
  }) {
    final cell = sheet.getRangeByIndex(row, column);
    cell.setText(title);
    cell.cellStyle.bold = true;
    cell.cellStyle.fontSize = 14;
    cell.cellStyle.fontColorRgb = const Color(0xFF1E2533);
  }

  void _writeKeyValue(
    Worksheet sheet, {
    required int row,
    required String label,
    required String value,
  }) {
    final labelCell = sheet.getRangeByIndex(row, 1);
    labelCell.setText(label);
    labelCell.cellStyle.bold = true;
    labelCell.cellStyle.fontColorRgb = const Color(0xFF5D6675);

    final valueCell = sheet.getRangeByIndex(row, 2);
    valueCell.setText(value);
    valueCell.cellStyle.fontColorRgb = const Color(0xFF1E2533);
  }

  void _writeMetricCard(
    Worksheet sheet, {
    required int row,
    required int column,
    required String label,
    required String value,
  }) {
    final range = sheet.getRangeByIndex(row, column, row + 2, column + 1);
    range.cellStyle.backColorRgb = const Color(0xFFF4F6FB);
    range.cellStyle.borders.all.lineStyle = LineStyle.thin;
    range.cellStyle.borders.all.color = '#D8DEE9';

    final labelCell = sheet.getRangeByIndex(row, column);
    labelCell.setText(label);
    labelCell.cellStyle.bold = true;
    labelCell.cellStyle.fontColorRgb = const Color(0xFF667085);

    final valueCell = sheet.getRangeByIndex(row + 1, column);
    valueCell.setText(value);
    valueCell.cellStyle.bold = true;
    valueCell.cellStyle.fontSize = 16;
    valueCell.cellStyle.fontColorRgb = const Color(0xFF1E2533);
  }

  void _writeParagraph(
    Worksheet sheet, {
    required int row,
    required String text,
    bool accent = false,
  }) {
    final range = sheet.getRangeByIndex(row, 1, row + 1, 8);
    range.merge();
    range.setText(text);
    range.cellStyle.wrapText = true;
    range.cellStyle.fontColorRgb =
        accent ? const Color(0xFF185B3D) : const Color(0xFF4B5563);
    if (accent) {
      range.cellStyle.backColorRgb = const Color(0xFFE9F8EF);
    }
    range.rowHeight = accent ? 36 : 30;
  }

  void _writeBullet(
    Worksheet sheet, {
    required int row,
    required String text,
  }) {
    final bulletCell = sheet.getRangeByIndex(row, 1);
    bulletCell.setText('-');
    bulletCell.cellStyle.bold = true;
    bulletCell.cellStyle.fontColorRgb = const Color(0xFFFF6B57);

    final textRange = sheet.getRangeByIndex(row, 2, row + 1, 8);
    textRange.merge();
    textRange.setText(text);
    textRange.cellStyle.wrapText = true;
    textRange.cellStyle.fontColorRgb = const Color(0xFF4B5563);
    textRange.rowHeight = 28;
  }

  void _writeTableHeader(
    Worksheet sheet, {
    required int row,
    int column = 1,
    required List<String> headers,
  }) {
    for (var index = 0; index < headers.length; index++) {
      final cell = sheet.getRangeByIndex(row, column + index);
      cell.setText(headers[index]);
      cell.cellStyle.bold = true;
      cell.cellStyle.fontColorRgb = Colors.white;
      cell.cellStyle.backColorRgb = const Color(0xFF212737);
    }
  }

  void _writeTableRow(
    Worksheet sheet, {
    required int row,
    int column = 1,
    required List<String> values,
  }) {
    for (var index = 0; index < values.length; index++) {
      final cell = sheet.getRangeByIndex(row, column + index);
      cell.setText(values[index]);
      cell.cellStyle.wrapText = true;
      cell.cellStyle.fontColorRgb = const Color(0xFF2A3141);
    }
  }

  String _windowForHour(int hour) {
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 17) {
      return 'afternoon';
    }
    if (hour < 21) {
      return 'evening';
    }
    return 'night';
  }

  String _formatReminderTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}

class _ExportIdentity {
  const _ExportIdentity({
    required this.name,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.startDate,
  });

  final String name;
  final String email;
  final String gender;
  final DateTime? dateOfBirth;
  final DateTime? startDate;
}

class _LogExportRow {
  const _LogExportRow({
    required this.habit,
    required this.log,
  });

  final Habit habit;
  final HabitLog log;
}

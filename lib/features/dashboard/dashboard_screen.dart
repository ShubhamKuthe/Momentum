// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:ui' show lerpDouble;

import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/habits/habit_customization.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/responsive.dart';
import '../../models/adaptive_goal_entry.dart';
import '../../models/habit.dart';
import '../../services/database_service.dart';
import '../../state/habit_provider.dart';
import '../../widgets/account_settings_widgets.dart';
import '../../widgets/animated_empty_state.dart';
import '../../widgets/animated_habit_card.dart';
import '../../widgets/animated_progress_ring.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/momentum_bottom_nav.dart';
import '../../widgets/step_habit_card.dart';
import '../../widgets/water_habit_card.dart';
import '../behavior_lab/behavior_lab_screen.dart';
import '../create_edit_habit/create_edit_habit_screen.dart';
import '../health_sync/health_sync_screen.dart';
import '../habit_detail/habit_detail_screen.dart';
import '../privacy/privacy_data_screen.dart';
import '../reports/reports_screen.dart';
import '../reminders/reminder_setup_screen.dart';

BoxDecoration _momentumPanelDecoration(
  BuildContext context, {
  double radius = AppRadii.card,
  Color? color,
}) {
  final palette = context.momentum;
  final baseColor = color ?? palette.surface;

  return BoxDecoration(
    color: baseColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: context.isMomentumDark
          ? palette.border.withValues(alpha: 0.78)
          : palette.border,
    ),
    boxShadow: AppElevations.card(
      palette.shadow,
      isDark: context.isMomentumDark,
    ),
  );
}

Widget _settingsLeadingIcon(BuildContext context, {required IconData icon}) {
  final palette = context.momentum;
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: context.isMomentumDark ? palette.accentSoft : AppColors.emberDim,
      borderRadius: BorderRadius.circular(AppRadii.badge),
    ),
    child: Icon(icon, color: palette.accent, size: 17),
  );
}

class _HabitCategoryOption {
  const _HabitCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const List<_HabitCategoryOption> _habitCategoryOptions = [
  _HabitCategoryOption(
    id: 'all',
    label: 'All Categories',
    icon: Icons.grid_view_rounded,
  ),
  _HabitCategoryOption(
    id: 'steps',
    label: 'Steps',
    icon: Icons.directions_walk_rounded,
  ),
  _HabitCategoryOption(
    id: 'workout',
    label: 'Workout',
    icon: Icons.fitness_center_rounded,
  ),
  _HabitCategoryOption(
    id: 'water',
    label: 'Water',
    icon: Icons.water_drop_rounded,
  ),
  _HabitCategoryOption(
    id: 'sleep',
    label: 'Sleep',
    icon: Icons.bedtime_rounded,
  ),
  _HabitCategoryOption(
    id: 'mindfulness',
    label: 'Mindfulness',
    icon: Icons.spa_rounded,
  ),
  _HabitCategoryOption(
    id: 'custom',
    label: 'Custom',
    icon: Icons.auto_awesome_rounded,
  ),
];

String _habitCategoryForHabit(Habit habit) {
  return resolvedHabitCategoryId(habit);
}

String _habitCategoryLabel(String id) {
  return _habitCategoryOptions.firstWhere((option) => option.id == id).label;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.isDarkTheme,
    required this.onThemeChanged,
    required this.isLargeText,
    required this.onTextScaleChanged,
    required this.onSignOut,
  });

  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;
  final bool isLargeText;
  final ValueChanged<bool> onTextScaleChanged;
  final Future<void> Function() onSignOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  String _userName = 'there';
  String _userEmail = '';
  String _userAvatarBase64 = '';
  String _goalType = 'steps';

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadIdentity() async {
    final userName = await _databaseService.getUserName();
    final userEmail = await _databaseService.getUserEmail();
    final userAvatarBase64 = await _databaseService.getUserAvatar();
    final goalType = await _databaseService.getOnboardingGoalType();
    if (!mounted) {
      return;
    }
    setState(() {
      _userName = userName.isEmpty ? 'there' : userName;
      _userEmail = userEmail;
      _userAvatarBase64 = userAvatarBase64;
      _goalType = goalType;
    });
  }

  Future<void> _openCreateHabit(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateEditHabitScreen()));
  }

  Future<void> _openReportsPage(
    BuildContext context,
    HabitProvider provider,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(provider: provider),
      ),
    );
  }

  Future<void> _openReminderSetup(
    BuildContext context,
    HabitProvider provider,
  ) async {
    if (provider.habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create your first habit to set up reminders.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReminderSetupScreen(
          habit: provider.habits.first,
          provider: provider,
        ),
      ),
    );
  }

  Future<void> _openQuickProfileSheet(
    BuildContext context,
    HabitProvider provider,
  ) async {
    final initial =
        _userName.isEmpty ? 'M' : _userName.characters.first.toUpperCase();
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    final result = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.none,
      constraints: const BoxConstraints(),
      builder: (sheetContext) {
        Future<void> closeSheetAndSignOut() async {
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }
          await widget.onSignOut();
        }

        return MomentumSheetFrame(
          child: _QuickProfileSheet(
            initial: initial,
            userName: _userName,
            userEmail: _userEmail,
            avatarBase64: _userAvatarBase64,
            isDarkTheme: widget.isDarkTheme,
            onThemeChanged: widget.onThemeChanged,
            isLargeText: widget.isLargeText,
            onTextScaleChanged: widget.onTextScaleChanged,
            onSignOut: closeSheetAndSignOut,
            onNotifications: () async {
              await _openReminderSetup(sheetContext, provider);
            },
            onOpenBehaviorLab: () {
              Navigator.of(sheetContext).push(
                MaterialPageRoute(builder: (_) => const BehaviorLabScreen()),
              );
            },
            onOpenHealthSync: () {
              Navigator.of(sheetContext).push(
                MaterialPageRoute(builder: (_) => const HealthSyncScreen()),
              );
            },
            onExport: () async {
              Navigator.of(sheetContext).pop();
              await _openReportsPage(context, provider);
            },
            onPrivacy: () {
              Navigator.of(sheetContext).push(
                MaterialPageRoute(builder: (_) => const PrivacyDataScreen()),
              );
            },
          ),
        );
      },
    );

    if (result == 'openAccount' && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 240));
      if (!mounted) {
        return;
      }
      await rootNavigator.push(
        _buildAccountDetailsRoute(rootNavigator, initial),
      );
    }

    await _loadIdentity();
  }

  Route<void> _buildAccountDetailsRoute(
    NavigatorState rootNavigator,
    String initial,
  ) {
    return PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _AccountDetailsScreen(
        databaseService: _databaseService,
        initial: initial,
        userName: _userName,
        userEmail: _userEmail,
        avatarBase64: _userAvatarBase64,
        onSignOut: () async {
          if (rootNavigator.canPop()) {
            rootNavigator.pop();
          }
          await widget.onSignOut();
        },
      ),
    );
  }

  Future<void> _refreshCurrentPage(HabitProvider provider) async {
    await provider.refreshSyncedData();
    if (!mounted) {
      return;
    }

    final hasConnectedStepSync = provider.healthSyncSnapshot.connected &&
        provider.habits.any(provider.isStepHabit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text(
          hasConnectedStepSync
              ? 'Momentum refreshed and synced latest step data.'
              : 'Momentum refreshed.',
        ),
      ),
    );
  }

  int _pageIndexForNavIndex(int navIndex) {
    switch (navIndex) {
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      case 0:
      default:
        return 0;
    }
  }

  int _navIndexForPageIndex(int pageIndex) {
    switch (pageIndex) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 4;
      case 0:
      default:
        return 0;
    }
  }

  Future<void> _handleNavSelection(int navIndex) async {
    final targetPage = _pageIndexForNavIndex(navIndex);
    if (_selectedIndex != navIndex && mounted) {
      setState(() => _selectedIndex = navIndex);
    }

    if (!_pageController.hasClients) {
      return;
    }

    final currentPage =
        _pageController.page?.round() ?? _pageIndexForNavIndex(_selectedIndex);
    if (currentPage == targetPage) {
      return;
    }

    await _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: palette.background,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: palette.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: palette.background,
        body: Consumer<HabitProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.habits.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (pageIndex) {
                      final navIndex = _navIndexForPageIndex(pageIndex);
                      if (_selectedIndex != navIndex && mounted) {
                        setState(() => _selectedIndex = navIndex);
                      }
                    },
                    children: _buildPages(context, provider),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: MomentumBottomNav(
                      selectedIndex: _selectedIndex,
                      onItemSelected: (index) {
                        _handleNavSelection(index);
                      },
                      onAddTap: () => _openCreateHabit(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildPages(BuildContext context, HabitProvider provider) {
    final displayName = _userName.split(' ').first;
    final profileInitial =
        displayName.isEmpty ? 'M' : displayName.characters.first.toUpperCase();

    return [
      _HomeTab(
        provider: provider,
        userName: _userName,
        goalType: _goalType,
        onCreateHabit: () => _openCreateHabit(context),
        onOpenQuickProfile: () => _openQuickProfileSheet(context, provider),
        onRefresh: () => _refreshCurrentPage(provider),
        onOpenHabit: (habit) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habitId: habit.id),
            ),
          );
        },
        profileAvatarBase64: _userAvatarBase64,
      ),
      _HabitsTab(
        provider: provider,
        goalType: _goalType,
        onCreateHabit: () => _openCreateHabit(context),
        onOpenQuickProfile: () => _openQuickProfileSheet(context, provider),
        onRefresh: () => _refreshCurrentPage(provider),
        onOpenHabit: (habit) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habitId: habit.id),
            ),
          );
        },
        profileInitial: profileInitial,
        profileAvatarBase64: _userAvatarBase64,
      ),
      _InsightsTab(
        provider: provider,
        onOpenQuickProfile: () => _openQuickProfileSheet(context, provider),
        onRefresh: () => _refreshCurrentPage(provider),
        profileInitial: profileInitial,
        profileAvatarBase64: _userAvatarBase64,
      ),
      _StatsTab(
        provider: provider,
        onOpenQuickProfile: () => _openQuickProfileSheet(context, provider),
        onRefresh: () => _refreshCurrentPage(provider),
        onOpenHealthSync: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HealthSyncScreen()));
        },
        profileInitial: profileInitial,
        profileAvatarBase64: _userAvatarBase64,
      ),
    ];
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.provider,
    required this.userName,
    required this.goalType,
    required this.onCreateHabit,
    required this.onOpenQuickProfile,
    required this.onRefresh,
    required this.onOpenHabit,
    required this.profileAvatarBase64,
  });

  final HabitProvider provider;
  final String userName;
  final String goalType;
  final Future<void> Function() onCreateHabit;
  final Future<void> Function() onOpenQuickProfile;
  final Future<void> Function() onRefresh;
  final ValueChanged<Habit> onOpenHabit;
  final String profileAvatarBase64;

  Future<void> _handleQuickLog(BuildContext context, Habit habit) async {
    await provider.quickLog(habit);
    if (!context.mounted) {
      return;
    }
    await _showCompletionMoodSheet(context, provider, habit);
  }

  @override
  Widget build(BuildContext context) {
    final habits = provider.habits;
    final responsive = context.responsive;
    final compact = responsive.width < 390;
    final progress = provider.overallProgressToday;
    final todayText = DateFormat('EEEE, d MMM').format(DateTime.now());
    final displayName = userName.split(' ').first;
    final completedCount = habits.where(provider.isCompletedToday).length;
    final remainingCount = habits.length - completedCount;
    final activeCount = habits.where((habit) {
      return provider.progressForToday(habit) > 0 &&
          !provider.isCompletedToday(habit);
    }).length;
    final groupedHabits = <String, List<Habit>>{
      for (final label in _routineGroupOrder) label: <Habit>[],
    };
    for (final habit in habits) {
      final label = provider.routineWindowLabel(habit);
      groupedHabits.putIfAbsent(label, () => <Habit>[]).add(habit);
    }

    return _CollapsingHeaderScrollView(
      title: 'Habits',
      subtitle: '$todayText - $displayName',
      horizontalPadding: responsive.pagePadding,
      titleFontSize: responsive.font(compact ? 27 : 29, min: 26, max: 30),
      onRefresh: onRefresh,
      headerAction: _ProfileAvatarButton(
        initial: displayName.isEmpty
            ? 'M'
            : displayName.characters.first.toUpperCase(),
        imageBase64: profileAvatarBase64,
        onTap: onOpenQuickProfile,
      ),
      bodyChildren: [
        SizedBox(height: responsive.value(18, min: 14, max: 22)),
        AnimatedHabitCard(
          index: 0,
          child: _HabitScoreSummaryCard(
            progress: progress,
            completedCount: completedCount,
            remainingCount: remainingCount,
            activeCount: activeCount,
          ),
        ),
        SizedBox(height: responsive.value(18, min: 14, max: 22)),
        const _SectionTitle('Today'),
        SizedBox(height: responsive.value(10, min: 8, max: 12)),
        if (habits.isEmpty)
          _HomeEmptyState(onCreateHabit: onCreateHabit, goalType: goalType)
        else
          ..._routineGroupOrder.where((label) {
            return (groupedHabits[label] ?? const <Habit>[]).isNotEmpty;
          }).expand((label) {
            final sectionHabits = groupedHabits[label] ?? const <Habit>[];
            return <Widget>[
              _RoutineGroupHeader(
                label: label,
                count: sectionHabits.length,
              ),
              SizedBox(height: responsive.value(8, min: 6, max: 10)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sectionHabits.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: compact ? 10 : 12,
                  mainAxisSpacing: compact ? 10 : 12,
                  mainAxisExtent: responsive.isSmallPhone ? 218 : 226,
                ),
                itemBuilder: (context, index) {
                  final habit = sectionHabits[index];
                  return AnimatedHabitCard(
                    index: index + 1,
                    child: _HomeHabitProgressCard(
                      habit: habit,
                      progress: provider.progressForToday(habit),
                      isCompleted: provider.isCompletedToday(habit),
                      mood: provider.completionMoodForToday(habit),
                      onTap: () => onOpenHabit(habit),
                      onQuickLog: () => _handleQuickLog(context, habit),
                    ),
                  );
                },
              ),
              SizedBox(height: responsive.value(14, min: 12, max: 18)),
            ];
          }),
      ],
    );
  }
}

class _HabitsTab extends StatefulWidget {
  const _HabitsTab({
    required this.provider,
    required this.goalType,
    required this.onCreateHabit,
    required this.onOpenQuickProfile,
    required this.onRefresh,
    required this.onOpenHabit,
    required this.profileInitial,
    required this.profileAvatarBase64,
  });

  final HabitProvider provider;
  final String goalType;
  final Future<void> Function() onCreateHabit;
  final Future<void> Function() onOpenQuickProfile;
  final Future<void> Function() onRefresh;
  final ValueChanged<Habit> onOpenHabit;
  final String profileInitial;
  final String profileAvatarBase64;

  @override
  State<_HabitsTab> createState() => _HabitsTabState();
}

class _HabitsTabState extends State<_HabitsTab> {
  String _selectedCategoryId = 'all';
  final Set<String> _pendingDeletedHabitIds = <String>{};
  String? _armedDeleteHabitId;

  void _clearDeleteArm() {
    if (_armedDeleteHabitId == null || !mounted) {
      return;
    }
    setState(() => _armedDeleteHabitId = null);
  }

  void _armDeleteSwipe(Habit habit) {
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() => _armedDeleteHabitId = habit.id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1600),
            content: Text('Swipe left on ${habit.name} to delete'),
          ),
        );
    }
  }

  Future<void> _openCategories() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            _HabitCategoriesScreen(selectedCategoryId: _selectedCategoryId),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedCategoryId = selected);
    }
  }

  Future<bool> _confirmDeleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.momentum;
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Delete habit?',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Remove ${habit.name} from your habits?',
            style: TextStyle(
              color: palette.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ember,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<bool> _deleteHabit(Habit habit) async {
    setState(() => _pendingDeletedHabitIds.add(habit.id));
    try {
      await widget.provider.deleteHabit(habit.id);
      if (!mounted) {
        return true;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Habit deleted')));
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      setState(() => _pendingDeletedHabitIds.remove(habit.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete habit')));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = widget.provider.habits;
    final compact = MediaQuery.of(context).size.width < 390;
    final palette = context.momentum;
    final filteredHabits = _selectedCategoryId == 'all'
        ? habits
        : habits
            .where(
              (habit) => _habitCategoryForHabit(habit) == _selectedCategoryId,
            )
            .toList();
    final visibleHabits = filteredHabits
        .where((habit) => !_pendingDeletedHabitIds.contains(habit.id))
        .toList();

    return _CollapsingHeaderScrollView(
      title: 'Your habits',
      subtitle: '${habits.length} active routines',
      horizontalPadding: context.responsive.pagePadding,
      titleFontSize: context.responsive.font(
        compact ? 22 : 24,
        min: 21,
        max: 25,
      ),
      minHeaderExtent: 72,
      maxHeaderExtent: 124,
      onRefresh: widget.onRefresh,
      headerAction: _ProfileAvatarButton(
        initial: widget.profileInitial,
        imageBase64: widget.profileAvatarBase64,
        onTap: widget.onOpenQuickProfile,
      ),
      bodyChildren: [
        SizedBox(height: context.responsive.value(18, min: 14, max: 22)),
        AnimatedHabitCard(
          index: 0,
          child: InkWell(
            onTap: _openCategories,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: _momentumPanelDecoration(context, radius: 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _selectedCategoryId == 'all'
                          ? palette.successSoft
                          : palette.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.apps_rounded,
                      color: _selectedCategoryId == 'all'
                          ? palette.success
                          : palette.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'See all categories',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCategoryId == 'all'
                              ? 'All habits'
                              : 'Selected: ${_habitCategoryLabel(_selectedCategoryId)}',
                          style: TextStyle(
                            color: _selectedCategoryId == 'all'
                                ? palette.textSoft
                                : palette.success,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: palette.textSoft),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.responsive.value(18, min: 14, max: 22)),
        if (visibleHabits.isEmpty)
          _HomeEmptyState(
            onCreateHabit: widget.onCreateHabit,
            goalType: widget.goalType,
          )
        else
          ...visibleHabits.asMap().entries.map((entry) {
            final index = entry.key;
            final habit = entry.value;
            final currentProgress = widget.provider.progressForToday(habit);
            final isCompleted = widget.provider.isCompletedToday(habit);
            final categoryId = _habitCategoryForHabit(habit);
            final normalizedName = habit.name.toLowerCase();
            final normalizedUnit = habit.unit.toLowerCase();
            final isStepsHabit = widget.provider.isStepHabit(habit);
            final isWaterHabit = categoryId == 'water' ||
                normalizedName.contains('water') ||
                normalizedName.contains('hydrat') ||
                normalizedUnit.contains('glass') ||
                normalizedUnit.contains('ml') ||
                normalizedUnit.contains('litre');

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visibleHabits.length - 1 ? 0 : 12,
              ),
              child: _HoldSwipeDeleteTile(
                key: ValueKey('habit-swipe-${habit.id}'),
                compact: compact,
                onHoldStart: () => _armDeleteSwipe(habit),
                onDeleteTap: () async {
                  final confirmed = await _confirmDeleteHabit(habit);
                  if (!confirmed) {
                    return false;
                  }
                  return _deleteHabit(habit);
                },
                onClosed: _clearDeleteArm,
                child: AnimatedHabitCard(
                  index: index + 1,
                  child: isStepsHabit
                      ? StepHabitCard(
                          title: habit.name,
                          currentSteps: currentProgress,
                          targetSteps: habit.targetValue,
                          status: widget.provider.stepStatusLabel(habit),
                          accentColor: resolvedHabitAccentColor(habit),
                          onManualLog: widget.provider.canManualLogHabit(habit)
                              ? () => widget.provider.quickLog(habit)
                              : null,
                          onTap: () {
                            _clearDeleteArm();
                            widget.onOpenHabit(habit);
                          },
                        )
                      : isWaterHabit
                          ? WaterHabitCard(
                              title: habit.name,
                              currentValue: currentProgress,
                              targetValue: habit.targetValue,
                              unit: habit.unit,
                              status: currentProgress > 0
                                  ? 'Tracking hydration'
                                  : 'Manual fallback',
                              accentColor: resolvedHabitAccentColor(habit),
                              onManualLog: () =>
                                  widget.provider.quickLog(habit),
                              onTap: () {
                                _clearDeleteArm();
                                widget.onOpenHabit(habit);
                              },
                            )
                          : HabitCard(
                              name: habit.name,
                              cue:
                                  '${habit.frequency} - ${habit.cue.isEmpty ? 'No cue yet' : habit.cue}',
                              target: habit.targetValue,
                              unit: habit.unit,
                              currentProgress: currentProgress,
                              streak: habit.currentStreak,
                              isCompleted: isCompleted,
                              leadingIcon: resolvedHabitIcon(habit),
                              accentColor: resolvedHabitAccentColor(habit),
                              onQuickLog: () {
                                _clearDeleteArm();
                                widget.provider.quickLog(habit);
                              },
                              onTap: () {
                                _clearDeleteArm();
                                widget.onOpenHabit(habit);
                              },
                            ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _HoldSwipeDeleteTile extends StatefulWidget {
  const _HoldSwipeDeleteTile({
    super.key,
    required this.child,
    required this.compact,
    required this.onHoldStart,
    required this.onDeleteTap,
    required this.onClosed,
  });

  final Widget child;
  final bool compact;
  final VoidCallback onHoldStart;
  final Future<bool> Function() onDeleteTap;
  final VoidCallback onClosed;

  @override
  State<_HoldSwipeDeleteTile> createState() => _HoldSwipeDeleteTileState();
}

class _HoldSwipeDeleteTileState extends State<_HoldSwipeDeleteTile> {
  static const double _revealWidth = 108;
  static const double _openThreshold = 46;
  double _dragExtent = 0;
  bool _armed = false;
  bool _isDeleting = false;

  double get _offsetX => -_dragExtent;

  void _closeDelete({bool notify = true}) {
    if ((_dragExtent == 0 && !_armed) || !mounted) {
      return;
    }
    setState(() {
      _dragExtent = 0;
      _armed = false;
    });
    if (notify) {
      widget.onClosed();
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    widget.onHoldStart();
    if (!mounted) {
      return;
    }
    setState(() => _armed = true);
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_armed || !mounted) {
      return;
    }
    final nextExtent = (-details.offsetFromOrigin.dx).clamp(0.0, _revealWidth);
    setState(() => _dragExtent = nextExtent);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_armed || !mounted) {
      return;
    }
    setState(() {
      _dragExtent = _dragExtent >= _openThreshold ? _revealWidth : 0;
      _armed = false;
    });
    if (_dragExtent == 0) {
      widget.onClosed();
    }
  }

  Future<void> _handleDeleteTap() async {
    if (_isDeleting) {
      return;
    }
    setState(() => _isDeleting = true);
    final deleted = await widget.onDeleteTap();
    if (!mounted) {
      return;
    }
    setState(() => _isDeleting = false);
    if (!deleted) {
      _closeDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dragExtent > 0 ? _closeDelete : null,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMove,
      onLongPressEnd: _handleLongPressEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: _SwipeDeleteBackground(
              compact: widget.compact,
              visible: _dragExtent > 0,
              isDeleting: _isDeleting,
              onTap: _handleDeleteTap,
            ),
          ),
          AnimatedContainer(
            duration:
                _armed ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_offsetX, 0, 0),
            child: AnimatedScale(
              scale: _armed ? 0.992 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({
    required this.compact,
    required this.visible,
    required this.isDeleting,
    required this.onTap,
  });

  final bool compact;
  final bool visible;
  final bool isDeleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible || isDeleting,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ember,
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: compact ? 16 : 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                child: isDeleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({
    required this.provider,
    required this.onOpenQuickProfile,
    required this.onRefresh,
    required this.profileInitial,
    required this.profileAvatarBase64,
  });

  final HabitProvider provider;
  final Future<void> Function() onOpenQuickProfile;
  final Future<void> Function() onRefresh;
  final String profileInitial;
  final String profileAvatarBase64;

  Future<void> _openChecklistSheet(BuildContext context) async {
    final habits = provider.habits;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = sheetContext.momentum;
        return Container(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: palette.border),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Today list',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...habits.map((habit) {
                final completed = provider.isCompletedToday(habit);
                final remaining = provider.remainingForToday(habit);
                final canManualLog = provider.canManualLogHabit(habit);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: completed || !canManualLog
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.of(sheetContext).pop();
                            await provider.quickLog(habit);
                            if (!context.mounted) {
                              return;
                            }
                            await _showCompletionMoodSheet(
                              context,
                              provider,
                              habit,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${habit.name} updated'),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: _momentumPanelDecoration(
                        sheetContext,
                        radius: 20,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            completed
                                ? Icons.check_circle_rounded
                                : resolvedHabitIcon(habit),
                            color: completed
                                ? Colors.greenAccent.shade400
                                : resolvedHabitAccentColor(habit),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            completed
                                ? 'Done'
                                : canManualLog
                                    ? '$remaining left'
                                    : 'Sync only',
                            style: TextStyle(
                              color: palette.textSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final habits = provider.habits;
    Habit? nextHabit;
    for (final habit in habits) {
      if (!provider.isCompletedToday(habit)) {
        nextHabit = habit;
        break;
      }
    }
    nextHabit ??= habits.isNotEmpty ? habits.first : null;

    Habit? reminderHabit;
    for (final habit in habits) {
      if (habit.reminderTime != null) {
        reminderHabit = habit;
        break;
      }
    }
    reminderHabit ??= nextHabit;
    final syncSnapshot = provider.healthSyncSnapshot;
    final reminderSelection = reminderHabit;
    Habit? quickLogHabit;
    for (final habit in habits) {
      if (!provider.isCompletedToday(habit) &&
          provider.canManualLogHabit(habit)) {
        quickLogHabit = habit;
        break;
      }
    }

    return _CollapsingHeaderScrollView(
      title: 'Coach',
      subtitle: 'Today made simple',
      horizontalPadding: responsive.pagePadding,
      titleFontSize: responsive.font(
        responsive.isSmallPhone ? 22 : 24,
        min: 21,
        max: 25,
      ),
      onRefresh: onRefresh,
      headerAction: _ProfileAvatarButton(
        initial: profileInitial,
        imageBase64: profileAvatarBase64,
        onTap: onOpenQuickProfile,
      ),
      bodyChildren: [
        SizedBox(height: responsive.value(18, min: 14, max: 22)),
        if (nextHabit == null)
          AnimatedEmptyState(
            icon: Icons.flag_rounded,
            title: 'Start your first habit',
            body: 'Coach shows your next move.',
            ctaLabel: 'Go to habits',
            onTap: () async =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          )
        else
          AnimatedHabitCard(
            index: 0,
            child: _CoachFocusCard(habit: nextHabit, provider: provider),
          ),
        SizedBox(height: responsive.value(18, min: 14, max: 22)),
        Row(
          children: [
            Expanded(
              child: AnimatedHabitCard(
                index: 1,
                child: _CoachMiniCard(
                  title: 'Reminder',
                  value: reminderSelection == null
                      ? 'Off'
                      : reminderSelection.reminderTime == null
                          ? 'Off'
                          : switch (reminderSelection.reminderMode) {
                              'persistent' => 'Persistent',
                              'vibrate' => 'Vibrate',
                              _ => 'Standard',
                            },
                  onTap: reminderSelection == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReminderSetupScreen(
                                habit: reminderSelection,
                                provider: provider,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedHabitCard(
                index: 2,
                child: _CoachMiniCard(
                  title: 'Sync',
                  value: syncSnapshot.connected ? 'Connected' : 'Manual',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HealthSyncScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.value(22, min: 18, max: 26)),
        const _SectionTitle('Quick actions'),
        SizedBox(height: responsive.value(12, min: 10, max: 14)),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _CoachActionTile(
              icon: Icons.notifications_active_rounded,
              label: 'Reminders',
              onTap: reminderSelection == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReminderSetupScreen(
                            habit: reminderSelection,
                            provider: provider,
                          ),
                        ),
                      );
                    },
            ),
            _CoachActionTile(
              icon: Icons.favorite_rounded,
              label: 'Health sync',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HealthSyncScreen()),
                );
              },
            ),
            _CoachActionTile(
              icon: Icons.add_task_rounded,
              label: 'Quick log',
              onTap: () async {
                if (quickLogHabit == null) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No unfinished habit is available for manual logging.',
                      ),
                    ),
                  );
                  return;
                }

                final selectedHabit = quickLogHabit;
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await provider.quickLog(selectedHabit);
                  if (!context.mounted) {
                    return;
                  }
                  await _showCompletionMoodSheet(
                    context,
                    provider,
                    selectedHabit,
                  );
                  final updatedProgress = provider.progressForToday(
                    selectedHabit,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${selectedHabit.name}: $updatedProgress / ${selectedHabit.targetValue} ${selectedHabit.unit}',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Momentum could not quick log that habit right now.',
                      ),
                    ),
                  );
                }
              },
            ),
            _CoachActionTile(
              icon: Icons.checklist_rounded,
              label: 'Today list',
              onTap: habits.isEmpty ? null : () => _openChecklistSheet(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoachFocusCard extends StatelessWidget {
  const _CoachFocusCard({required this.habit, required this.provider});

  final Habit habit;
  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final accent = resolvedHabitAccentColor(habit);
    final remaining = provider.remainingForToday(habit);
    final canManualLog = provider.canManualLogHabit(habit);
    final status = remaining <= 0
        ? 'Done today'
        : '${remaining.toString()} ${habit.unit} left';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _momentumPanelDecoration(
        context,
        color: context.isMomentumDark
            ? Color.lerp(palette.surface, accent, 0.16)
            : Color.lerp(Colors.white, accent, 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(resolvedHabitIcon(habit), color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Do next',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            habit.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: provider.progressRatioForToday(habit),
              minHeight: 8,
              backgroundColor: palette.surfaceStrong,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          if (canManualLog)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => provider.quickLog(habit),
                child: const Text('Log now'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoachMiniCard extends StatelessWidget {
  const _CoachMiniCard({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _momentumPanelDecoration(context, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachActionTile extends StatelessWidget {
  const _CoachActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _momentumPanelDecoration(context, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.isMomentumDark
                    ? palette.accentSoft
                    : AppColors.emberDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: palette.accent, size: 22),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCategoriesScreen extends StatelessWidget {
  const _HabitCategoriesScreen({required this.selectedCategoryId});

  final String selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: palette.text,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'All Categories',
              style: TextStyle(
                color: palette.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: _momentumPanelDecoration(context, radius: 28),
              child: Column(
                children: _habitCategoryOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final selected = category.id == selectedCategoryId;

                  return _CategoryRow(
                    category: category,
                    selected: selected,
                    showDivider: index != 0,
                    onTap: () => Navigator.of(context).pop(category.id),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitScoreSummaryCard extends StatelessWidget {
  const _HabitScoreSummaryCard({
    required this.progress,
    required this.completedCount,
    required this.remainingCount,
    required this.activeCount,
  });

  final double progress;
  final int completedCount;
  final int remainingCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final compact = MediaQuery.of(context).size.width < 390;

    return Container(
      padding: EdgeInsets.all(compact ? 15 : 17),
      decoration: _momentumPanelDecoration(context, radius: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _SummaryLegendItem(
                  color: palette.accent,
                  label: 'Completed',
                  value: '$completedCount',
                ),
                const SizedBox(height: 10),
                _SummaryLegendItem(
                  color: const Color(0xFFFFC94A),
                  label: 'Remaining',
                  value: '$remainingCount',
                ),
                const SizedBox(height: 10),
                _SummaryLegendItem(
                  color: context.isMomentumDark
                      ? palette.text
                      : const Color(0xFF292C34),
                  label: 'Active',
                  value: '$activeCount',
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            children: [
              AnimatedProgressRing(
                progress: progress,
                size: compact ? 98 : 108,
                strokeWidth: compact ? 10 : 12,
                label: 'SCORE',
                color: palette.accent,
                trackColor: palette.ringTrack,
                innerColor: context.isMomentumDark
                    ? palette.background
                    : palette.surfaceStrong,
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: palette.text,
                  fontSize: compact ? 16 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLegendItem extends StatelessWidget {
  const _SummaryLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: palette.textSoft,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HomeHabitProgressCard extends StatelessWidget {
  const _HomeHabitProgressCard({
    required this.habit,
    required this.progress,
    required this.isCompleted,
    required this.mood,
    required this.onTap,
    required this.onQuickLog,
  });

  final Habit habit;
  final int progress;
  final bool isCompleted;
  final String? mood;
  final VoidCallback onTap;
  final VoidCallback onQuickLog;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 390;
    final ratio = habit.targetValue == 0
        ? 0.0
        : (progress / habit.targetValue).clamp(0.0, 1.0);
    final cardTheme = _homeHabitCardTheme(context, habit);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(compact ? 14 : 16),
          height: double.infinity,
          decoration: BoxDecoration(
            color: cardTheme.background,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: cardTheme.background.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 34 : 38,
                    height: compact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cardTheme.icon,
                      color: cardTheme.foreground,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onQuickLog,
                    child: Container(
                      width: compact ? 22 : 24,
                      height: compact ? 22 : 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.white.withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.add_rounded,
                        color: cardTheme.foreground,
                        size: compact ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                habit.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cardTheme.titleColor,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                habit.frequency,
                style: TextStyle(
                  color: cardTheme.subtitleColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.32),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cardTheme.progressColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCompleted
                    ? 'Completed'
                    : '$progress / ${habit.targetValue} ${habit.unit}',
                style: TextStyle(
                  color: cardTheme.subtitleColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (mood != null && mood!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mood!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> _routineGroupOrder = <String>[
  'Morning',
  'Afternoon',
  'Evening',
  'Anytime',
];

class _RoutineGroupHeader extends StatelessWidget {
  const _RoutineGroupHeader({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCompletionMoodSheet(
  BuildContext context,
  HabitProvider provider,
  Habit habit,
) async {
  if (!context.mounted ||
      provider.isStepHabit(habit) ||
      !provider.isCompletedToday(habit) ||
      (provider.completionMoodForToday(habit)?.isNotEmpty ?? false)) {
    return;
  }

  const moods = <({String label, String emoji})>[
    (label: 'Easy', emoji: '🙂'),
    (label: 'Good', emoji: '😌'),
    (label: 'Proud', emoji: '🔥'),
    (label: 'Tough', emoji: '😮‍💨'),
  ];

  final palette = context.momentum;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.border),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How did ${habit.name.toLowerCase()} feel?',
              style: TextStyle(
                color: palette.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: moods.map((mood) {
                return GestureDetector(
                  onTap: () async {
                    await provider.saveCompletionMoodForToday(
                      habit,
                      '${mood.emoji} ${mood.label}',
                    );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: _momentumPanelDecoration(
                      sheetContext,
                      radius: 18,
                    ),
                    child: Text(
                      '${mood.emoji} ${mood.label}',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}

class _HomeHabitCardTheme {
  const _HomeHabitCardTheme({
    required this.background,
    required this.foreground,
    required this.titleColor,
    required this.subtitleColor,
    required this.progressColor,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final Color titleColor;
  final Color subtitleColor;
  final Color progressColor;
  final IconData icon;
}

_HomeHabitCardTheme _homeHabitCardTheme(BuildContext context, Habit habit) {
  final isDark = context.isMomentumDark;
  final accent = resolvedHabitAccentColor(habit);

  return _HomeHabitCardTheme(
    background: isDark ? Color.lerp(Colors.black, accent, 0.28)! : accent,
    foreground: isDark ? Color.lerp(accent, Colors.white, 0.18)! : accent,
    titleColor: Colors.white,
    subtitleColor: Colors.white.withValues(alpha: 0.84),
    progressColor: Colors.white,
    icon: resolvedHabitIcon(habit),
  );
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({
    required this.provider,
    required this.onOpenQuickProfile,
    required this.onRefresh,
    required this.onOpenHealthSync,
    required this.profileInitial,
    required this.profileAvatarBase64,
  });

  final HabitProvider provider;
  final Future<void> Function() onOpenQuickProfile;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenHealthSync;
  final String profileInitial;
  final String profileAvatarBase64;

  @override
  Widget build(BuildContext context) {
    final unlocked = provider.unlockedBadgesCount();
    final compact = MediaQuery.of(context).size.width < 390;
    final habits = provider.habits;
    final completionPct =
        (provider.completionPercentageLast7Days() * 100).round();
    final bestStreak = provider.bestOverallStreak();
    final mostConsistent = provider.mostConsistentHabit();
    final points = provider.last30OverallRatios();
    final weeklyRatios =
        points.length >= 7 ? points.sublist(points.length - 7) : points;
    final automaticity = provider.overallAutomaticityScore().round();
    final stepHabits = habits.where(provider.isStepHabit).toList();
    final stepHistory = stepHabits.isEmpty
        ? const <DateTime, int>{}
        : provider.stepHistoryForRecentDays(days: 30);
    final stepSnapshot = provider.healthSyncSnapshot;

    final responsive = context.responsive;

    return _CollapsingHeaderScrollView(
      title: 'Stats',
      subtitle: 'Weekly snapshot',
      horizontalPadding: responsive.pagePadding,
      titleFontSize: responsive.font(compact ? 22 : 24, min: 21, max: 25),
      onRefresh: onRefresh,
      headerAction: _ProfileAvatarButton(
        initial: profileInitial,
        imageBase64: profileAvatarBase64,
        onTap: onOpenQuickProfile,
      ),
      bodyChildren: [
        SizedBox(height: responsive.value(18, min: 14, max: 22)),
        AnimatedHabitCard(
          index: 0,
          child: _StatsOverviewHeroCard(
            completionPct: completionPct,
            bestStreak: bestStreak,
            activeHabits: habits.length,
            unlockedBadges: unlocked,
            automaticityScore: automaticity,
            mostConsistent: mostConsistent,
          ),
        ),
        if (stepHabits.isNotEmpty) ...[
          SizedBox(height: responsive.value(18, min: 14, max: 22)),
          const _SectionTitle('Sync'),
          SizedBox(height: responsive.value(12, min: 10, max: 14)),
          AnimatedHabitCard(
            index: 1,
            child: _StatsStepSyncCard(
              history: stepHistory,
              sourceLabel: stepSnapshot.sourceLabel,
              connected: stepSnapshot.connected,
              onOpenHealthSync: onOpenHealthSync,
            ),
          ),
        ],
        SizedBox(height: responsive.value(18, min: 14, max: 22)),
        const _SectionTitle('Habits'),
        SizedBox(height: responsive.value(12, min: 10, max: 14)),
        if (habits.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _momentumPanelDecoration(context),
            child: Text(
              'Add a habit to start filling this dashboard.',
              style: TextStyle(
                color: context.momentum.textSoft,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          )
        else
          GridView.builder(
            itemCount: habits.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: compact ? 10 : 12,
              crossAxisSpacing: compact ? 10 : 12,
              mainAxisExtent: responsive.isSmallPhone ? 272 : 286,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedHabitCard(
                index: index + (stepHabits.isEmpty ? 1 : 2),
                child: _HabitAnalyticsCard(
                  habit: habits[index],
                  provider: provider,
                ),
              );
            },
          ),
        SizedBox(height: responsive.value(22, min: 18, max: 26)),
        const _SectionTitle('Week'),
        SizedBox(height: responsive.value(12, min: 10, max: 14)),
        AnimatedHabitCard(
          index: habits.length + (stepHabits.isEmpty ? 2 : 3),
          child: _AnimatedWeeklyBarsCard(ratios: weeklyRatios),
        ),
        SizedBox(height: responsive.value(22, min: 18, max: 26)),
        const _SectionTitle('Badges'),
        SizedBox(height: responsive.value(12, min: 10, max: 14)),
        GridView.builder(
          itemCount: 6,
          gridDelegate: responsive.adaptiveGrid(
            maxCrossAxisExtent: responsive.isSmallPhone ? 108 : 122,
            mainAxisSpacing: compact ? 10 : 12,
            crossAxisSpacing: compact ? 10 : 12,
            mainAxisExtent: responsive.isSmallPhone ? 116 : 126,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final items = [
              _AnimatedBadgeReveal(
                index: 0,
                child: _BadgeCard(
                  icon: Icons.local_fire_department_rounded,
                  label: '7-day',
                  unlocked: unlocked >= 1,
                ),
              ),
              _AnimatedBadgeReveal(
                index: 1,
                child: _BadgeCard(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Early bird',
                  unlocked: unlocked >= 2,
                ),
              ),
              _AnimatedBadgeReveal(
                index: 2,
                child: _BadgeCard(
                  icon: Icons.emoji_events_rounded,
                  label: '10k club',
                  unlocked: unlocked >= 3,
                ),
              ),
              const _AnimatedBadgeReveal(
                index: 3,
                child: _BadgeCard(
                  icon: Icons.lock_rounded,
                  label: 'Locked',
                  unlocked: false,
                ),
              ),
              const _AnimatedBadgeReveal(
                index: 4,
                child: _BadgeCard(
                  icon: Icons.lock_rounded,
                  label: 'Locked',
                  unlocked: false,
                ),
              ),
              const _AnimatedBadgeReveal(
                index: 5,
                child: _BadgeCard(
                  icon: Icons.lock_rounded,
                  label: 'Locked',
                  unlocked: false,
                ),
              ),
            ];
            return items[index];
          },
        ),
      ],
    );
  }
}

class _CollapsingHeaderScrollView extends StatelessWidget {
  const _CollapsingHeaderScrollView({
    required this.title,
    required this.subtitle,
    required this.bodyChildren,
    required this.horizontalPadding,
    required this.titleFontSize,
    required this.onRefresh,
    this.minHeaderExtent = 62,
    this.maxHeaderExtent = 110,
    this.headerAction,
  });

  final String title;
  final String subtitle;
  final List<Widget> bodyChildren;
  final double horizontalPadding;
  final double titleFontSize;
  final Future<void> Function() onRefresh;
  final double minHeaderExtent;
  final double maxHeaderExtent;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topInset = MediaQuery.paddingOf(context).top;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CollapsingHeaderDelegate(
              title: title,
              subtitle: subtitle,
              horizontalPadding: horizontalPadding,
              titleFontSize: titleFontSize,
              minExtentValue: minHeaderExtent,
              maxExtentValue: maxHeaderExtent,
              topInset: topInset,
              headerAction: headerAction,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              responsive.value(10, min: 8, max: 12),
              horizontalPadding,
              responsive.value(110, min: 98, max: 124),
            ),
            sliver: SliverList(delegate: SliverChildListDelegate(bodyChildren)),
          ),
        ],
      ),
    );
  }
}

class _CollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CollapsingHeaderDelegate({
    required this.title,
    required this.subtitle,
    required this.horizontalPadding,
    required this.titleFontSize,
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.topInset,
    this.headerAction,
  });

  final String title;
  final String subtitle;
  final double horizontalPadding;
  final double titleFontSize;
  final double minExtentValue;
  final double maxExtentValue;
  final double topInset;
  final Widget? headerAction;

  @override
  double get minExtent => minExtentValue + topInset;

  @override
  double get maxExtent => maxExtentValue + topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final palette = context.momentum;
    final responsive = context.responsive;
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubicEmphasized.transform(progress);
    final expandedPhase = (progress / 0.58).clamp(0.0, 1.0);
    final collapsedPhase = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    final expandedOpacity = 1 - Curves.easeIn.transform(expandedPhase);
    final collapsedOpacity = Curves.easeOutCubic.transform(collapsedPhase);
    final avatarSize = responsive.value(42, min: 40, max: 44);
    final avatarExpandedTop = topInset + responsive.value(24, min: 20, max: 28);
    final avatarCollapsedTop = topInset + responsive.value(10, min: 8, max: 12);
    final avatarTop =
        lerpDouble(avatarExpandedTop, avatarCollapsedTop, eased) ??
            avatarCollapsedTop;

    return ColoredBox(
      color: palette.background,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: responsive.value(14, min: 12, max: 16),
              child: ColoredBox(color: palette.background),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topInset + responsive.value(12, min: 10, max: 14),
                horizontalPadding,
                responsive.value(8, min: 6, max: 10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: expandedOpacity,
                      child: Transform.translate(
                        offset: Offset(0, -10 * eased),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              SizedBox(
                                height: responsive.value(3, min: 2, max: 4),
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: responsive.font(
                                        13.5,
                                        min: 13,
                                        max: 14,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF8A8F98),
                                      height: 1.2,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (headerAction != null)
                    SizedBox(
                      width:
                          avatarSize + responsive.value(12, min: 10, max: 14),
                    ),
                ],
              ),
            ),
            if (headerAction != null)
              Positioned(
                top: avatarTop,
                right: horizontalPadding,
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: headerAction!,
                ),
              ),
            if (collapsedOpacity > 0)
              Opacity(
                opacity: collapsedOpacity,
                child: Transform.translate(
                  offset: Offset(0, 6 * (1 - eased)),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: headerAction == null ? 72 : 88,
                      right: headerAction == null ? 72 : 88,
                    ),
                    child: Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.titleFontSize != titleFontSize ||
        oldDelegate.minExtentValue != minExtentValue ||
        oldDelegate.maxExtentValue != maxExtentValue ||
        oldDelegate.topInset != topInset ||
        oldDelegate.headerAction != headerAction;
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.initial,
    required this.imageBase64,
    required this.onTap,
  });

  final String initial;
  final String imageBase64;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              context.isMomentumDark ? palette.surfaceStrong : palette.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.isMomentumDark
                ? palette.borderSoft.withValues(alpha: 0.7)
                : palette.border,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: context.isMomentumDark ? 0.18 : 0.08,
              ),
              blurRadius: context.isMomentumDark ? 14 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: MomentumProfileAvatar(
          initial: initial,
          imageBase64: imageBase64,
          size: 42,
          backgroundColor:
              context.isMomentumDark ? palette.surfaceStrong : palette.surface,
          borderColor: Colors.transparent,
          textStyle: TextStyle(
            color: palette.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _QuickProfileSheet extends StatefulWidget {
  const _QuickProfileSheet({
    required this.initial,
    required this.userName,
    required this.userEmail,
    required this.avatarBase64,
    required this.isDarkTheme,
    required this.onThemeChanged,
    required this.isLargeText,
    required this.onTextScaleChanged,
    required this.onSignOut,
    required this.onNotifications,
    required this.onOpenBehaviorLab,
    required this.onOpenHealthSync,
    required this.onExport,
    required this.onPrivacy,
  });

  final String initial;
  final String userName;
  final String userEmail;
  final String avatarBase64;
  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;
  final bool isLargeText;
  final ValueChanged<bool> onTextScaleChanged;
  final Future<void> Function() onSignOut;
  final VoidCallback onNotifications;
  final VoidCallback onOpenBehaviorLab;
  final VoidCallback onOpenHealthSync;
  final VoidCallback onExport;
  final VoidCallback onPrivacy;

  @override
  State<_QuickProfileSheet> createState() => _QuickProfileSheetState();
}

class _QuickProfileSheetState extends State<_QuickProfileSheet> {
  final DatabaseService _databaseService = DatabaseService();
  bool _darkTheme = false;
  bool _largeText = false;
  bool _shareStreaks = false;
  bool _loaded = false;
  String _avatarBase64 = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarBase64 = await _databaseService.getUserAvatar();
    if (!mounted) {
      return;
    }
    setState(() {
      _darkTheme = prefs.getBool('profile.darkTheme') ?? widget.isDarkTheme;
      _largeText = prefs.getBool('profile.largeText') ?? widget.isLargeText;
      _shareStreaks = prefs.getBool('profile.shareStreaks') ?? false;
      _avatarBase64 = avatarBase64.isEmpty ? widget.avatarBase64 : avatarBase64;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openAccountDetails() async {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop('openAccount');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final name = widget.userName.isEmpty ? 'Momentum user' : widget.userName;
    final email =
        widget.userEmail.isEmpty ? 'No email added yet' : widget.userEmail;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: isDark ? null : palette.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    palette.surfaceStrong.withValues(alpha: 0.98),
                    palette.surface.withValues(alpha: 0.99),
                    palette.background.withValues(alpha: 0.99),
                  ]
                : [palette.surface, palette.surface, palette.background],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: isDark ? 0.52 : 0.12),
              blurRadius: isDark ? 38 : 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccountHeader(
                title: 'Account',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              AnimatedHabitCard(
                index: 0,
                child: ProfileAccountCard(
                  initial: widget.initial,
                  name: name,
                  secondaryText: email,
                  imageBase64: _avatarBase64,
                  onTap: _openAccountDetails,
                ),
              ),
              const SizedBox(height: 18),
              const AnimatedHabitCard(index: 1, child: SectionLabel('Main')),
              const SizedBox(height: 12),
              AnimatedHabitCard(
                index: 2,
                child: SettingsGroupCard(
                  children: [
                    PressableSettingsRow(
                      title: 'Notifications',
                      subtitle: 'Reminder settings',
                      onTap: widget.onNotifications,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const AnimatedHabitCard(
                index: 3,
                child: SectionLabel('Momentum'),
              ),
              const SizedBox(height: 12),
              AnimatedHabitCard(
                index: 4,
                child: SettingsGroupCard(
                  children: [
                    PressableSettingsRow(
                      title: 'Behavior Lab',
                      subtitle: 'Patterns and goal changes',
                      onTap: widget.onOpenBehaviorLab,
                      leading: _settingsLeadingIcon(
                        context,
                        icon: Icons.route_rounded,
                      ),
                    ),
                    PressableSettingsRow(
                      title: 'Health Sync',
                      subtitle: 'Google Health and Apple Health',
                      onTap: widget.onOpenHealthSync,
                      showDivider: true,
                      leading: _settingsLeadingIcon(
                        context,
                        icon: Icons.favorite_rounded,
                      ),
                    ),
                    PressableSettingsRow(
                      title: 'Privacy & Data',
                      subtitle: 'Local storage and export',
                      onTap: widget.onPrivacy,
                      showDivider: true,
                      leading: _settingsLeadingIcon(
                        context,
                        icon: Icons.lock_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const AnimatedHabitCard(
                index: 5,
                child: SectionLabel('Preferences'),
              ),
              const SizedBox(height: 12),
              if (!_loaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                AnimatedHabitCard(
                  index: 6,
                  child: SettingsGroupCard(
                    children: [
                      SettingsToggleRow(
                        title: 'Dark Theme',
                        subtitle: 'Glossy night mode',
                        value: _darkTheme,
                        onChanged: (value) async {
                          setState(() => _darkTheme = value);
                          await _save('profile.darkTheme', value);
                          widget.onThemeChanged(value);
                        },
                      ),
                      SettingsToggleRow(
                        title: 'Larger Text',
                        subtitle: 'Bigger text',
                        value: _largeText,
                        showDivider: true,
                        onChanged: (value) async {
                          setState(() => _largeText = value);
                          await _save('profile.largeText', value);
                          widget.onTextScaleChanged(value);
                        },
                      ),
                      SettingsToggleRow(
                        title: 'Share Streaks',
                        subtitle: 'Share progress',
                        value: _shareStreaks,
                        showDivider: true,
                        onChanged: (value) {
                          setState(() => _shareStreaks = value);
                          _save('profile.shareStreaks', value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AnimatedHabitCard(
                index: 7,
                child: SettingsGroupCard(
                  accent: true,
                  children: [
                    PressableSettingsRow(
                      title: 'Momentum Reports',
                      subtitle: 'Open saved report files',
                      onTap: widget.onExport,
                      accent: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDetailsScreen extends StatefulWidget {
  const _AccountDetailsScreen({
    required this.databaseService,
    required this.initial,
    required this.userName,
    required this.userEmail,
    required this.avatarBase64,
    required this.onSignOut,
  });

  final DatabaseService databaseService;
  final String initial;
  final String userName;
  final String userEmail;
  final String avatarBase64;
  final Future<void> Function() onSignOut;

  @override
  State<_AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<_AccountDetailsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String _displayName = '';
  String _gender = '';
  String _avatarBase64 = '';
  DateTime? _dob;
  DateTime? _startDate;
  bool _loading = true;
  bool _savingAvatar = false;

  String get _resolvedName {
    final directName = _displayName.trim();
    if (directName.isNotEmpty) {
      return directName;
    }
    final fallback = widget.userName.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return 'Momentum user';
  }

  String get _profileInitial {
    final source = _resolvedName.trim().isNotEmpty
        ? _resolvedName.trim()
        : widget.userEmail.trim();
    if (source.isEmpty) {
      return widget.initial;
    }
    return source.characters.first.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    final storedName = await widget.databaseService.getUserName();
    final gender = await widget.databaseService.getUserGender();
    final avatarBase64 = await widget.databaseService.getUserAvatar();
    final dob = await widget.databaseService.getUserDob();
    var startDate = await widget.databaseService.getUserStartDate();
    final resolvedName =
        storedName.trim().isEmpty ? widget.userName : storedName;

    startDate ??= DateTime.now();
    await widget.databaseService.saveUserIdentity(
      name: resolvedName,
      email: widget.userEmail,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _displayName = resolvedName;
      _gender = gender;
      _avatarBase64 = avatarBase64.isEmpty ? widget.avatarBase64 : avatarBase64;
      _dob = dob;
      _startDate = startDate;
      _loading = false;
    });
  }

  Future<void> _startProfilePhotoFlow() async {
    if (_savingAvatar) {
      return;
    }

    final source = await _pickImageSource();
    if (source == null) {
      return;
    }

    await _pickProfilePhotoFromSource(source);
  }

  Future<void> _pickProfilePhotoFromSource(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 76,
        maxWidth: 1200,
      );
      if (file == null) {
        return;
      }

      setState(() => _savingAvatar = true);
      final cropped = await _cropProfilePhoto(file.path);
      final bytes =
          await (cropped == null ? file : XFile(cropped.path)).readAsBytes();
      final encoded = base64Encode(bytes);
      await widget.databaseService.saveUserAvatar(encoded);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarBase64 = encoded;
        _savingAvatar = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _savingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Momentum could not update the profile photo.'),
        ),
      );
    }
  }

  Future<ImageSource?> _pickImageSource() async {
    final palette = context.momentum;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    return showModalBottomSheet<ImageSource>(
      context: rootContext,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MomentumSheetFrame(
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.borderSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile photo',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _PhotoSourceTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'Take selfie',
                  onTap: () => Navigator.of(
                    sheetContext,
                    rootNavigator: true,
                  ).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _PhotoSourceTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from gallery',
                  onTap: () => Navigator.of(
                    sheetContext,
                    rootNavigator: true,
                  ).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openProfilePhotoViewer() async {
    final palette = context.momentum;
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    await showModalBottomSheet<void>(
      context: rootContext,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.96),
      builder: (sheetContext) {
        final responsive = sheetContext.responsive;
        final previewSize = (MediaQuery.sizeOf(sheetContext).width * 0.58)
            .clamp(190.0, 260.0)
            .toDouble();
        final topPadding = MediaQuery.paddingOf(sheetContext).top;

        Future<void> handleSource(ImageSource source) async {
          Navigator.of(sheetContext, rootNavigator: true).pop();
          await Future<void>.delayed(Duration.zero);
          await _pickProfilePhotoFromSource(source);
        }

        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: palette.background)),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.of(sheetContext, rootNavigator: true).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                top: topPadding + responsive.value(72, min: 56, max: 96),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: previewSize,
                    height: previewSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: MomentumProfileAvatar(
                      initial: widget.initial,
                      imageBase64: _avatarBase64,
                      size: previewSize,
                      backgroundColor: palette.surface,
                      borderColor: palette.border.withValues(alpha: 0.55),
                      textStyle: TextStyle(
                        color: palette.text,
                        fontSize: previewSize * 0.24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: MomentumSheetFrame(
                  margin: EdgeInsets.fromLTRB(
                    0,
                    responsive.value(12, min: 10, max: 18),
                    0,
                    0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: palette.borderSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Profile photo',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PhotoSourceTile(
                          icon: Icons.photo_camera_rounded,
                          label: 'Take selfie',
                          onTap: () => handleSource(ImageSource.camera),
                        ),
                        const SizedBox(height: 10),
                        _PhotoSourceTile(
                          icon: Icons.photo_library_rounded,
                          label: 'Choose from gallery',
                          onTap: () => handleSource(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<CroppedFile?> _cropProfilePhoto(String sourcePath) async {
    if (kIsWeb) {
      return null;
    }

    final palette = context.momentum;
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 88,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop profile photo',
          toolbarColor: palette.surface,
          toolbarWidgetColor: palette.text,
          backgroundColor: palette.background,
          activeControlsWidgetColor: palette.accent,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.55),
          cropFrameColor: palette.accent.withValues(alpha: 0.9),
          cropGridColor: palette.borderSoft,
          hideBottomControls: true,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Profile photo',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          rotateButtonsHidden: false,
          resetButtonHidden: false,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
  }

  Future<void> _removeProfilePhoto() async {
    await widget.databaseService.clearUserAvatar();
    if (!mounted) {
      return;
    }
    setState(() => _avatarBase64 = '');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
  }

  Future<void> _editDisplayName() async {
    final palette = context.momentum;
    final controller = TextEditingController(text: _resolvedName);
    final formKey = GlobalKey<FormState>();

    final updatedName = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        final responsive = sheetContext.responsive;
        final viewInsets = MediaQuery.viewInsetsOf(sheetContext);

        return MomentumSheetFrame(
          margin: EdgeInsets.fromLTRB(
            0,
            responsive.value(12, min: 10, max: 18),
            0,
            0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(responsive.radius(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18 + viewInsets.bottom,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.borderSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Change name',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Add your name';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      Navigator.of(sheetContext, rootNavigator: true).pop(
                        controller.text.trim(),
                      );
                    },
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
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.of(sheetContext, rootNavigator: true).pop(
                          controller.text.trim(),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (updatedName == null || updatedName.trim().isEmpty) {
      return;
    }

    await widget.databaseService.saveUserIdentity(
      name: updatedName.trim(),
      email: widget.userEmail,
    );

    if (!mounted) {
      return;
    }

    setState(() => _displayName = updatedName.trim());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Name updated')));
  }

  Future<void> _pickGender() async {
    final palette = context.momentum;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        const options = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
        final responsive = sheetContext.responsive;
        final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.62;

        return MomentumSheetFrame(
          margin: EdgeInsets.fromLTRB(
            0,
            responsive.value(12, min: 10, max: 18),
            0,
            0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(responsive.radius(28)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  bottomInset + responsive.value(8, min: 6, max: 10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: responsive.value(14, min: 12, max: 16)),
                    Container(
                      width: responsive.value(44, min: 40, max: 48),
                      height: responsive.value(5, min: 4, max: 6),
                      decoration: BoxDecoration(
                        color: palette.borderSoft,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                    SizedBox(height: responsive.value(14, min: 12, max: 16)),
                    Text(
                      'Select gender',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: responsive.font(18, min: 17, max: 20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: responsive.value(10, min: 8, max: 12)),
                    ...options.map((option) {
                      final isSelected = option == _gender;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          responsive.value(16, min: 14, max: 18),
                          0,
                          responsive.value(16, min: 14, max: 18),
                          responsive.value(6, min: 4, max: 8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(
                              sheetContext,
                              rootNavigator: true,
                            ).pop(option),
                            child: Ink(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.value(
                                  16,
                                  min: 14,
                                  max: 18,
                                ),
                                vertical: responsive.value(
                                  14,
                                  min: 12,
                                  max: 16,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? palette.accentSoft.withValues(
                                        alpha:
                                            context.isMomentumDark ? 0.3 : 0.55,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontSize: responsive.font(
                                          16,
                                          min: 15,
                                          max: 17,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: palette.success,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.value(16, min: 14, max: 18),
                        0,
                        responsive.value(16, min: 14, max: 18),
                        responsive.value(6, min: 4, max: 8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.of(
                            sheetContext,
                            rootNavigator: true,
                          ).pop(''),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.value(
                                16,
                                min: 14,
                                max: 18,
                              ),
                              vertical: responsive.value(14, min: 12, max: 16),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: responsive.font(16, min: 15, max: 17),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.value(8, min: 6, max: 10)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    await widget.databaseService.saveUserGender(selected);
    if (!mounted) {
      return;
    }
    setState(() => _gender = selected);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked == null) {
      return;
    }

    await widget.databaseService.saveUserDob(picked);
    if (!mounted) {
      return;
    }
    setState(() => _dob = picked);
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.momentum;
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Change password',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (value) {
                    if ((value ?? '').trim().length < 6) {
                      return 'Use at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim() !=
                        passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel', style: TextStyle(color: palette.textSoft)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (changed != true) {
      return;
    }

    final nextPassword = passwordController.text.trim();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updatePassword(nextPassword);
      }

      await widget.databaseService.saveUserPassword(nextPassword);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.code == 'requires-recent-login'
          ? 'Please sign in again before changing your password.'
          : ((error.message?.trim().isNotEmpty ?? false)
              ? error.message!.trim()
              : 'Momentum could not update the password right now.');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Momentum could not update the password right now.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password updated')));
  }

  String _formattedDate(DateTime? value, {String fallback = 'Not added'}) {
    if (value == null) {
      return fallback;
    }
    return DateFormat('d MMM yyyy').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final name = _resolvedName;
    final email =
        widget.userEmail.isEmpty ? 'No email added yet' : widget.userEmail;
    final mediaPadding = MediaQuery.paddingOf(context);
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: palette.background,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: palette.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: palette.background,
        body: ColoredBox(
          color: palette.background,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              mediaPadding.top + 8,
              18,
              mediaPadding.bottom + 24,
            ),
            children: [
              AccountHeader(
                title: 'Account',
                leadingIcon: Icons.chevron_left_rounded,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              ProfileAccountCard(
                initial: _profileInitial,
                name: name,
                secondaryText: email,
                imageBase64: _avatarBase64,
                onAvatarTap: _savingAvatar ? null : _openProfilePhotoViewer,
                showChevron: false,
              ),
              const SizedBox(height: 20),
              const SectionLabel('Personal'),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SettingsGroupCard(
                  children: [
                    PressableSettingsRow(
                      title: 'Name',
                      subtitle: name,
                      onTap: _editDisplayName,
                    ),
                    PressableSettingsRow(
                      title: 'Gender',
                      subtitle: _gender.isEmpty ? 'Not added' : _gender,
                      showDivider: true,
                      onTap: _pickGender,
                    ),
                    PressableSettingsRow(
                      title: 'Date of Birth',
                      subtitle: _formattedDate(_dob),
                      showDivider: true,
                      onTap: _pickDob,
                    ),
                    _StaticSettingsRow(
                      title: 'Start Date',
                      value: _formattedDate(_startDate, fallback: 'Today'),
                      showDivider: true,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              const SectionLabel('Security'),
              const SizedBox(height: 12),
              SettingsGroupCard(
                children: [
                  PressableSettingsRow(
                    title: 'Change Password',
                    subtitle: 'Reset sign-in password',
                    onTap: _changePassword,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ember,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: widget.onSignOut,
                  child: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticSettingsRow extends StatelessWidget {
  const _StaticSettingsRow({
    required this.title,
    required this.value,
    this.showDivider = false,
  });

  final String title;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                top: BorderSide(
                  color: isDark
                      ? palette.borderSoft.withValues(alpha: 0.5)
                      : palette.borderSoft,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15.8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: _momentumPanelDecoration(context, radius: 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              _settingsLeadingIcon(context, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedWeeklyBarsCard extends StatelessWidget {
  const _AnimatedWeeklyBarsCard({required this.ratios});

  final List<double> ratios;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final days = List.generate(ratios.length, (index) {
      return DateFormat.E().format(
        DateTime.now().subtract(Duration(days: ratios.length - 1 - index)),
      );
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(ratios.length, (index) {
                return Expanded(
                  child: _AnimatedWeeklyBar(
                    index: index,
                    ratio: ratios[index],
                    label: days[index].substring(0, 1),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWeeklyBar extends StatelessWidget {
  const _AnimatedWeeklyBar({
    required this.index,
    required this.ratio,
    required this.label,
  });

  final int index;
  final double ratio;
  final String label;

  @override
  Widget build(BuildContext context) {
    final capped = ratio.clamp(0.0, 1.0);
    final isComplete = capped >= 1;
    final palette = context.momentum;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: capped),
      duration: Duration(milliseconds: 520 + (index * 110)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final height = 24 + (value * 68);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    color: isComplete ? palette.success : palette.accent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: (isComplete ? palette.success : palette.accent)
                            .withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedBadgeReveal extends StatefulWidget {
  const _AnimatedBadgeReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedBadgeReveal> createState() => _AnimatedBadgeRevealState();
}

class _AnimatedBadgeRevealState extends State<_AnimatedBadgeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(curved);

    Future<void>.delayed(Duration(milliseconds: 90 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.provider,
    required this.userName,
    required this.userEmail,
    required this.goalType,
    required this.isDarkTheme,
    required this.onThemeChanged,
    required this.isLargeText,
    required this.onTextScaleChanged,
    required this.onOpenBehaviorLab,
    required this.onOpenHealthSync,
    required this.onOpenPrivacy,
  });

  final HabitProvider provider;
  final String userName;
  final String userEmail;
  final String goalType;
  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;
  final bool isLargeText;
  final ValueChanged<bool> onTextScaleChanged;
  final VoidCallback onOpenBehaviorLab;
  final VoidCallback onOpenHealthSync;
  final VoidCallback onOpenPrivacy;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _darkTheme = false;
  bool _largeText = false;
  bool _shareStreaks = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkTheme = prefs.getBool('profile.darkTheme') ?? widget.isDarkTheme;
      _largeText = prefs.getBool('profile.largeText') ?? widget.isLargeText;
      _shareStreaks = prefs.getBool('profile.shareStreaks') ?? false;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openReportsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(provider: widget.provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final habits = widget.provider.habits;
    final initial = widget.userName.isEmpty
        ? 'M'
        : widget.userName.characters.first.toUpperCase();
    final goalTypeLabel =
        '${widget.goalType[0].toUpperCase()}${widget.goalType.substring(1)}';

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        gradient: context.isMomentumDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.surfaceStrong.withValues(alpha: 0.24),
                  palette.background,
                ],
              )
            : null,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          const AccountHeader(title: 'Profile'),
          const SizedBox(height: 22),
          AnimatedHabitCard(
            index: 0,
            child: ProfileAccountCard(
              initial: initial,
              name: widget.userName,
              secondaryText: widget.userEmail.isEmpty
                  ? '${habits.length} active habits - goal $goalTypeLabel'
                  : widget.userEmail,
            ),
          ),
          const SizedBox(height: 24),
          const AnimatedHabitCard(index: 1, child: SectionLabel('Momentum')),
          const SizedBox(height: 12),
          AnimatedHabitCard(
            index: 2,
            child: SettingsGroupCard(
              children: [
                PressableSettingsRow(
                  title: 'Behavior Lab',
                  subtitle: 'Patterns and goal changes',
                  onTap: widget.onOpenBehaviorLab,
                  leading: _settingsLeadingIcon(
                    context,
                    icon: Icons.route_rounded,
                  ),
                ),
                PressableSettingsRow(
                  title: 'Health Sync',
                  subtitle: 'Google Health and Apple Health',
                  onTap: widget.onOpenHealthSync,
                  showDivider: true,
                  leading: _settingsLeadingIcon(
                    context,
                    icon: Icons.favorite_rounded,
                  ),
                ),
                PressableSettingsRow(
                  title: 'Privacy & Data',
                  subtitle: 'Local storage and export',
                  onTap: widget.onOpenPrivacy,
                  showDivider: true,
                  leading: _settingsLeadingIcon(
                    context,
                    icon: Icons.lock_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AnimatedHabitCard(index: 3, child: SectionLabel('Preferences')),
          const SizedBox(height: 12),
          if (!_loaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            AnimatedHabitCard(
              index: 4,
              child: SettingsGroupCard(
                children: [
                  SettingsToggleRow(
                    title: 'Dark Theme',
                    subtitle: 'Glossy night mode',
                    value: _darkTheme,
                    onChanged: (value) async {
                      setState(() => _darkTheme = value);
                      await _save('profile.darkTheme', value);
                      widget.onThemeChanged(value);
                    },
                  ),
                  SettingsToggleRow(
                    title: 'Larger Text',
                    subtitle: 'Bigger text',
                    value: _largeText,
                    showDivider: true,
                    onChanged: (value) async {
                      setState(() => _largeText = value);
                      await _save('profile.largeText', value);
                      widget.onTextScaleChanged(value);
                    },
                  ),
                  SettingsToggleRow(
                    title: 'Share Streaks',
                    subtitle: 'Share progress',
                    value: _shareStreaks,
                    showDivider: true,
                    onChanged: (value) {
                      setState(() => _shareStreaks = value);
                      _save('profile.shareStreaks', value);
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          AnimatedHabitCard(
            index: 5,
            child: SettingsGroupCard(
              accent: true,
              children: [
                PressableSettingsRow(
                  title: 'Momentum Reports',
                  subtitle: 'Open saved report files',
                  onTap: _openReportsPage,
                  accent: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.onCreateHabit, required this.goalType});

  final Future<void> Function() onCreateHabit;
  final String goalType;

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      icon: Icons.track_changes_rounded,
      title: 'No habits yet',
      body:
          'Your setup is ready for a ${goalType == 'custom' ? 'custom habit' : goalType} routine. Create or refine the habit to start tracking today.',
      ctaLabel: 'Start your first habit',
      onTap: onCreateHabit,
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final _HabitCategoryOption category;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  top: BorderSide(
                    color: palette.borderSoft.withValues(alpha: 0.7),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? palette.successSoft : palette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category.icon,
                color: selected ? palette.success : palette.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.label,
                style: TextStyle(
                  color: selected ? palette.success : palette.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? palette.success : palette.textSoft,
              size: selected ? 24 : 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsOverviewHeroCard extends StatelessWidget {
  const _StatsOverviewHeroCard({
    required this.completionPct,
    required this.bestStreak,
    required this.activeHabits,
    required this.unlockedBadges,
    required this.automaticityScore,
    required this.mostConsistent,
  });

  final int completionPct;
  final int bestStreak;
  final int activeHabits;
  final int unlockedBadges;
  final int automaticityScore;
  final Habit? mostConsistent;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.value(16, min: 14, max: 18)),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: responsive.font(19, min: 17, max: 20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      mostConsistent == null
                          ? 'No habits yet'
                          : 'Most consistent: ${mostConsistent!.name}',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: responsive.font(12.5, min: 11.5, max: 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedProgressRing(
                progress: (completionPct / 100).clamp(0.0, 1.0),
                size: responsive.value(82, min: 76, max: 88),
                strokeWidth: responsive.value(9, min: 8, max: 10),
                label: 'WEEK',
                color: palette.accent,
                trackColor: palette.ringTrack,
                innerColor: context.isMomentumDark
                    ? palette.surfaceStrong
                    : palette.surface,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: 'Active', value: '$activeHabits'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(label: 'Streak', value: '$bestStreak d'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Automaticity',
                  value: '$automaticityScore',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(label: 'Badges', value: '$unlockedBadges'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsStepSyncCard extends StatelessWidget {
  const _StatsStepSyncCard({
    required this.history,
    required this.sourceLabel,
    required this.connected,
    required this.onOpenHealthSync,
  });

  final Map<DateTime, int> history;
  final String sourceLabel;
  final bool connected;
  final VoidCallback onOpenHealthSync;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final responsive = context.responsive;
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);
    final ordered = history.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final recent30 =
        ordered.length > 30 ? ordered.sublist(ordered.length - 30) : ordered;
    final monthEntries = ordered
        .where(
          (entry) => entry.key.year == now.year && entry.key.month == now.month,
        )
        .toList();
    final todaySteps = history[normalizedToday] ?? 0;
    final monthTotal = monthEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final monthlyAverage = recent30.isEmpty
        ? 0
        : (recent30.fold<int>(0, (sum, entry) => sum + entry.value) /
                recent30.length)
            .round();
    final bestDay = monthEntries.isEmpty
        ? null
        : monthEntries.reduce((best, candidate) {
            return candidate.value > best.value ? candidate : best;
          });

    return Container(
      padding: EdgeInsets.all(responsive.value(16, min: 14, max: 18)),
      decoration: _momentumPanelDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metricWidth = constraints.maxWidth < 340
              ? (constraints.maxWidth - 10) / 2
              : (constraints.maxWidth - 20) / 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connected ? sourceLabel : 'Health sync',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: responsive.font(18, min: 16.5, max: 19),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connected
                              ? 'Last 30 days of steps'
                              : 'Connect to import steps',
                          style: TextStyle(
                            color: palette.textSoft,
                            fontSize: responsive.font(12, min: 11, max: 12.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenHealthSync,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.accent,
                      backgroundColor: context.isMomentumDark
                          ? palette.accentSoft
                          : AppColors.emberDim,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Manage',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Today',
                      value: NumberFormat.decimalPattern().format(todaySteps),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: '30-day avg',
                      value: NumberFormat.decimalPattern().format(
                        monthlyAverage,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth < 340
                        ? constraints.maxWidth
                        : metricWidth,
                    child: _MetricTile(
                      label: 'Month',
                      value: NumberFormat.decimalPattern().format(monthTotal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StatsStepBarRow(entries: recent30),
              if (bestDay != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Best day: ${DateFormat('d MMM').format(bestDay.key)} - ${NumberFormat.decimalPattern().format(bestDay.value)} steps',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: responsive.font(11.5, min: 11, max: 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatsStepBarRow extends StatelessWidget {
  const _StatsStepBarRow({required this.entries});

  final List<MapEntry<DateTime, int>> entries;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final bars = List<MapEntry<DateTime, int>>.from(entries);
    while (bars.length < 30) {
      final seedDate = bars.isEmpty
          ? DateTime.now().subtract(Duration(days: 29 - bars.length))
          : bars.first.key.subtract(const Duration(days: 1));
      bars.insert(
        0,
        MapEntry(DateTime(seedDate.year, seedDate.month, seedDate.day), 0),
      );
    }
    final maxValue = bars.fold<int>(
      0,
      (maxSoFar, item) => item.value > maxSoFar ? item.value : maxSoFar,
    );

    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (index) {
          final item = bars[index];
          final ratio = maxValue == 0 ? 0.0 : item.value / maxValue;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == bars.length - 1 ? 0 : 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: ratio),
                        duration: Duration(milliseconds: 380 + (index * 55)),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedRatio, _) {
                          final height = 10 + (animatedRatio * 48);
                          return Container(
                            decoration: BoxDecoration(
                              color: item.value > 0
                                  ? palette.accent
                                  : palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            height: height,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.d().format(item.key),
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HabitAnalyticsCard extends StatelessWidget {
  const _HabitAnalyticsCard({required this.habit, required this.provider});

  final Habit habit;
  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final palette = context.momentum;
        final accent = resolvedHabitAccentColor(habit);
        final progress = provider.progressForToday(habit);
        final target = habit.targetValue;
        final ratio = provider.progressRatioForToday(habit).clamp(0.0, 1.0);
        final weeklyRatios = provider.last7RatiosForHabit(habit);
        final completions = provider.completionDaysLast7(habit);
        final weeklyTotal = weeklyRatios.fold<double>(
          0,
          (sum, item) => sum + item,
        );
        final weeklyPercent =
            ((weeklyTotal / weeklyRatios.length) * 100).round();
        final formattedProgress = progress.toStringAsFixed(
          progress.truncateToDouble() == progress ? 0 : 1,
        );
        final compact = constraints.maxWidth < 175;
        final padding = compact ? 12.0 : 14.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: _momentumPanelDecoration(
            context,
            color: context.isMomentumDark
                ? Color.lerp(palette.surface, accent, 0.14)
                : Color.lerp(Colors.white, accent, 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 34 : 38,
                    height: compact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: context.isMomentumDark ? 0.2 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      resolvedHabitIcon(habit),
                      color: accent,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 9,
                      vertical: compact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.isMomentumDark
                          ? palette.surfaceStrong.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(ratio * 100).round()}%',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: compact ? 10.5 : 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 5 : 6),
              Text(
                habit.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: compact ? 14.5 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                habit.frequency,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: compact ? 10.5 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                formattedProgress,
                style: TextStyle(
                  color: palette.text,
                  fontSize: compact ? 23 : 25,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of $target ${habit.unit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: compact ? 11 : 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: compact ? 7 : 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: context.isMomentumDark
                      ? palette.surfaceStrong
                      : accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              SizedBox(height: compact ? 7 : 8),
              _MiniHabitTrend(ratios: weeklyRatios, accent: accent),
              SizedBox(height: compact ? 4 : 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$completions done',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: compact ? 10.5 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$weeklyPercent%',
                    style: TextStyle(
                      color: palette.textSoft,
                      fontSize: compact ? 10.5 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniHabitTrend extends StatelessWidget {
  const _MiniHabitTrend({required this.ratios, required this.accent});

  final List<double> ratios;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final displayRatios = ratios.length >= 7
        ? ratios.sublist(ratios.length - 7)
        : List<double>.from(ratios);
    while (displayRatios.length < 7) {
      displayRatios.insert(0, 0);
    }

    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(displayRatios.length, (index) {
            final value = displayRatios[index].clamp(0.0, 1.0);
            final height = 6 + (value * 18);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == displayRatios.length - 1 ? 0 : 6,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: height),
                  duration: Duration(milliseconds: 380 + (index * 55)),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedHeight, _) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: animatedHeight,
                        decoration: BoxDecoration(
                          color: value >= 1 ? palette.success : accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PatternSummaryCard extends StatelessWidget {
  const _PatternSummaryCard({
    required this.summary,
    required this.bestWindow,
    required this.bestCueHabit,
  });

  final String summary;
  final String bestWindow;
  final Habit? bestCueHabit;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S PATTERN SUMMARY',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Best window',
                  value:
                      bestWindow == 'No pattern yet' ? 'Learning' : bestWindow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Lead habit',
                  value: bestCueHabit?.name ?? 'No cue yet',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CueWindowCard extends StatelessWidget {
  const _CueWindowCard({
    required this.bestCueHabit,
    required this.mostConsistent,
    required this.bestWindow,
  });

  final Habit? bestCueHabit;
  final Habit? mostConsistent;
  final String bestWindow;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final cueText = bestCueHabit?.cue.trim().isNotEmpty == true
        ? bestCueHabit!.cue.trim()
        : 'No cue set yet';
    final cueOwner = bestCueHabit?.name ?? 'Add a cue';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEST CUE & WINDOW',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InsightFocusTile(
                  icon: Icons.link_rounded,
                  title: cueOwner,
                  value: cueText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightFocusTile(
                  icon: Icons.schedule_rounded,
                  title: 'Best time window',
                  value: bestWindow == 'No pattern yet'
                      ? 'Still learning'
                      : bestWindow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mostConsistent == null
                ? 'Momentum will highlight the strongest cue once you log a few completions.'
                : '${mostConsistent!.name} is currently your most consistent habit, so its cue setup is the best place to learn from.',
            style: TextStyle(
              color: palette.textSoft,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyTrendCard extends StatelessWidget {
  const _ConsistencyTrendCard({
    required this.points,
    required this.strongestHabit,
  });

  final List<double> points;
  final Habit? strongestHabit;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final latest = points.isEmpty ? 0 : points.last;
    final previous = points.length > 7 ? points[points.length - 8] : 0;
    final delta = latest - previous;
    final trendLabel = delta > 0.08
        ? 'Improving'
        : delta < -0.08
            ? 'Cooling off'
            : 'Holding steady';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSISTENCY TREND',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$trendLabel over the last 30 days',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: delta >= 0
                      ? (context.isMomentumDark
                          ? palette.successSoft
                          : AppColors.mossDim)
                      : (context.isMomentumDark
                          ? palette.accentSoft
                          : AppColors.emberDim),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(latest * 100).round()}%',
                  style: TextStyle(
                    color: delta >= 0 ? palette.success : palette.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 29,
                minY: 0,
                maxY: 1,
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: palette.accent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == 29,
                      getDotPainter: (_, __, ___, ____) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: palette.accent,
                          strokeColor: palette.accent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.accent.withValues(alpha: 0.18),
                          palette.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strongestHabit == null
                ? 'Add habits and log progress to unlock your consistency trend.'
                : '${strongestHabit!.name} is leading this trend right now.',
            style: TextStyle(
              color: palette.textSoft,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomaticityOverviewCard extends StatelessWidget {
  const _AutomaticityOverviewCard({
    required this.provider,
    required this.strongestHabit,
  });

  final HabitProvider provider;
  final Habit? strongestHabit;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final score = provider.overallAutomaticityScore();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUTOMATICITY SCORE',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedProgressRing(
                progress: (score / 100).clamp(0.0, 1.0),
                size: 106,
                strokeWidth: 12,
                label: 'FLOW',
                color: palette.accent,
                trackColor: palette.ringTrack,
                innerColor: context.isMomentumDark
                    ? palette.surfaceStrong
                    : palette.surface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score.round()} / 100',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strongestHabit == null
                          ? 'Momentum measures how repeatable your routines are becoming.'
                          : '${strongestHabit!.name} is currently doing the most to build automaticity.',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdaptiveGoalHistoryOverviewCard extends StatelessWidget {
  const _AdaptiveGoalHistoryOverviewCard({
    required this.entries,
    required this.provider,
  });

  final List<AdaptiveGoalEntry> entries;
  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADAPTIVE GOAL HISTORY',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'No adaptive suggestions yet. Momentum will list user-approved goal proposals here.',
              style: TextStyle(
                color: palette.textSoft,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            )
          else
            ...entries.take(4).map((entry) {
              final habit = provider.habitById(entry.habitId);
              final dateLabel = DateFormat('d MMM').format(entry.createdAt);
              final statusColor = switch (entry.status) {
                'accepted' => palette.success,
                'rejected' => palette.accent,
                _ => palette.textSoft,
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: _momentumPanelDecoration(
                  context,
                  radius: 16,
                  color: context.isMomentumDark
                      ? palette.surfaceMuted
                      : palette.background,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit?.name ?? 'Archived habit',
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.oldTarget} -> ${entry.suggestedTarget} - $dateLabel',
                            style: TextStyle(
                              color: palette.textSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        entry.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
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

class _InsightFocusTile extends StatelessWidget {
  const _InsightFocusTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _momentumPanelDecoration(
        context,
        radius: 18,
        color:
            context.isMomentumDark ? palette.surfaceMuted : palette.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.isMomentumDark
                  ? palette.accentSoft
                  : AppColors.emberDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: palette.accent, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.text,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviorInsightsCard extends StatelessWidget {
  const _BehaviorInsightsCard({
    required this.insights,
    required this.researchSummary,
  });

  final List<String> insights;
  final String researchSummary;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _momentumPanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEHAVIOR INSIGHTS',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: context.isMomentumDark
                          ? palette.successSoft
                          : AppColors.mossDim,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: palette.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
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
          const SizedBox(height: 4),
          Text(
            researchSummary,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _momentumPanelDecoration(
        context,
        radius: 16,
        color:
            context.isMomentumDark ? palette.surfaceMuted : palette.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  final IconData icon;
  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 390;
    final palette = context.momentum;
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? (context.isMomentumDark ? palette.surface : palette.surface)
            : (context.isMomentumDark
                ? palette.surfaceMuted.withValues(alpha: 0.72)
                : palette.background.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
          color:
              unlocked ? palette.border : palette.border.withValues(alpha: 0.7),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 12 : 14,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? (context.isMomentumDark
                      ? palette.goldSoft
                      : AppColors.goldDim)
                  : (context.isMomentumDark
                      ? palette.surfaceStrong
                      : AppColors.paperDim.withValues(alpha: 0.72)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked
                  ? palette.gold
                  : palette.textSoft.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: unlocked
                  ? palette.text
                  : palette.textSoft.withValues(alpha: 0.68),
              fontSize: compact ? 10.5 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}

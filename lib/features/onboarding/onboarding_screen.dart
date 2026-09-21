import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/responsive.dart';

class OnboardingAnswers {
  const OnboardingAnswers({
    required this.goalType,
    required this.customHabitName,
    required this.motivation,
    required this.routineLevel,
    required this.preferredWindow,
    required this.cue,
    required this.targetValue,
    required this.targetUnit,
    required this.trackingPreference,
    required this.remindersEnabled,
  });

  final String goalType;
  final String customHabitName;
  final String motivation;
  final String routineLevel;
  final String preferredWindow;
  final String cue;
  final int targetValue;
  final String targetUnit;
  final String trackingPreference;
  final bool remindersEnabled;

  Map<String, dynamic> toMap() {
    return {
      'goalType': goalType,
      'customHabitName': customHabitName,
      'motivation': motivation,
      'routineLevel': routineLevel,
      'preferredWindow': preferredWindow,
      'cue': cue,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'trackingPreference': trackingPreference,
      'remindersEnabled': remindersEnabled,
    };
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onCompleted});

  final Future<void> Function(OnboardingAnswers answers) onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _customHabitNameController =
      TextEditingController();
  final TextEditingController _cueController = TextEditingController();

  final List<String> _goalTypes = const [
    'steps',
    'workout',
    'water',
    'sleep',
    'custom',
  ];
  final List<String> _motivations = const [
    'Better health',
    'More energy',
    'A better routine',
    'Fitness goals',
    'Less stress',
  ];
  final List<String> _routineLevels = const [
    'Just getting started',
    'Somewhat active',
    'Mostly consistent',
    'Very consistent',
  ];
  final List<String> _habitWindows = const [
    'Morning',
    'Afternoon',
    'Evening',
    'Before bed',
    'Flexible',
  ];
  final List<String> _trackingOptions = const [
    'Manual logging',
    'Manual now, health sync later',
    'Health sync when ready',
  ];

  int _page = 0;
  bool _isSaving = false;
  String _selectedGoalType = 'steps';
  String _selectedMotivation = 'Better health';
  String _selectedRoutineLevel = 'Just getting started';
  String _selectedHabitWindow = 'Morning';
  String _selectedTracking = 'Manual logging';
  bool _remindersEnabled = true;
  int _selectedTargetValue = 5000;
  String _selectedTargetUnit = 'steps';

  @override
  void initState() {
    super.initState();
    _cueController.text = _defaultCueForWindow(_selectedHabitWindow);
    _applyTargetDefaults();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customHabitNameController.dispose();
    _cueController.dispose();
    super.dispose();
  }

  List<_TargetOption> get _targetOptions {
    switch (_selectedGoalType) {
      case 'workout':
        return const [
          _TargetOption(10, 'min'),
          _TargetOption(20, 'min'),
          _TargetOption(30, 'min'),
          _TargetOption(45, 'min'),
        ];
      case 'water':
        return const [
          _TargetOption(4, 'glasses'),
          _TargetOption(6, 'glasses'),
          _TargetOption(8, 'glasses'),
          _TargetOption(10, 'glasses'),
        ];
      case 'sleep':
        return const [
          _TargetOption(6, 'hours'),
          _TargetOption(7, 'hours'),
          _TargetOption(8, 'hours'),
          _TargetOption(9, 'hours'),
        ];
      case 'custom':
        return const [
          _TargetOption(1, 'times'),
          _TargetOption(2, 'times'),
          _TargetOption(3, 'times'),
          _TargetOption(5, 'times'),
        ];
      case 'steps':
      default:
        return const [
          _TargetOption(3000, 'steps'),
          _TargetOption(5000, 'steps'),
          _TargetOption(7000, 'steps'),
          _TargetOption(10000, 'steps'),
        ];
    }
  }

  Future<void> _advancePage() async {
    if (_page >= 4) {
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _selectAndAdvance(VoidCallback updater) async {
    setState(updater);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) {
      return;
    }
    await _advancePage();
  }

  Future<void> _finish() async {
    if (!_canContinue) {
      return;
    }

    setState(() => _isSaving = true);
    await widget.onCompleted(
      OnboardingAnswers(
        goalType: _selectedGoalType,
        customHabitName: _customHabitNameController.text.trim(),
        motivation: _selectedMotivation,
        routineLevel: _selectedRoutineLevel,
        preferredWindow: _selectedHabitWindow,
        cue: _cueController.text.trim(),
        targetValue: _selectedTargetValue,
        targetUnit: _selectedTargetUnit,
        trackingPreference: _selectedTracking,
        remindersEnabled: _remindersEnabled,
      ),
    );
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  bool get _canContinue {
    if (_page == 0 && _selectedGoalType == 'custom') {
      return _customHabitNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  bool get _showBottomButton {
    return _page == 4 || (_page == 0 && _selectedGoalType == 'custom');
  }

  void _applyTargetDefaults() {
    final first = _targetOptions.first;
    _selectedTargetValue = first.value;
    _selectedTargetUnit = first.unit;
  }

  String _defaultCueForWindow(String window) {
    switch (window) {
      case 'Morning':
        return 'After breakfast';
      case 'Afternoon':
        return 'After lunch';
      case 'Evening':
        return 'After work';
      case 'Before bed':
        return 'Before going to bed';
      case 'Flexible':
      default:
        return 'When I notice a free moment';
    }
  }

  String get _primaryButtonLabel {
    if (_page == 0 && _selectedGoalType == 'custom') {
      return 'Save custom habit';
    }
    return 'Enter app';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final overlayStyle = SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: AppColors.paper,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: AnimatedPadding(
            duration: AppDurations.stateChange,
            curve: AppEasing.standard,
            padding: EdgeInsets.only(
              bottom:
                  responsive.keyboardInset > 0 ? responsive.keyboardInset : 0,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.pagePadding,
                responsive.value(16, min: 12, max: 20),
                responsive.pagePadding,
                responsive.value(20, min: 16, max: 24),
              ),
              child: Column(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final active = index <= _page;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: responsive.value(5, min: 4, max: 6),
                          margin: EdgeInsets.only(
                            right: index == 4
                                ? 0
                                : responsive.value(8, min: 6, max: 10),
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppColors.moss : AppColors.paperDim,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: responsive.value(10, min: 8, max: 12)),
                  Row(
                    children: [
                      Text(
                        'Question ${_page + 1} of 5',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: responsive.font(12, min: 11.5, max: 12.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_page > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) => setState(() => _page = value),
                      children: [
                        _QuestionLayout(
                          title: 'What would you like to build first?',
                          subtitle:
                              'Tap one option and Momentum will move you straight to the next step.',
                          footerHint: _selectedGoalType == 'custom'
                              ? 'Add a name for your custom habit to continue.'
                              : 'Tap a box to continue',
                          child: Column(
                            children: [
                              ..._goalTypes.map((goalType) {
                                final selected = goalType == _selectedGoalType;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ChoiceTile(
                                    icon: _goalTypeIcon(goalType),
                                    label: _goalTypeLabel(goalType),
                                    description: _goalTypeDescription(goalType),
                                    selected: selected,
                                    onTap: () async {
                                      if (goalType == 'custom') {
                                        setState(() {
                                          _selectedGoalType = goalType;
                                          _applyTargetDefaults();
                                        });
                                        return;
                                      }
                                      await _selectAndAdvance(() {
                                        _selectedGoalType = goalType;
                                        _applyTargetDefaults();
                                      });
                                    },
                                  ),
                                );
                              }),
                              if (_selectedGoalType == 'custom') ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _customHabitNameController,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Custom habit name',
                                    hintText: 'Example: Stretch break',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _QuestionLayout(
                          title: 'Why does this matter right now?',
                          subtitle:
                              'Choose the reason that feels closest to your real goal.',
                          footerHint: 'Tap a box to continue',
                          child: Column(
                            children: _motivations.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _OptionCard(
                                  title: item,
                                  description: _motivationDescription(item),
                                  selected: item == _selectedMotivation,
                                  onTap: () async {
                                    await _selectAndAdvance(() {
                                      _selectedMotivation = item;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        _QuestionLayout(
                          title: 'How would you describe your routine?',
                          subtitle:
                              'Momentum will use this to keep the first habit realistic.',
                          footerHint: 'Tap a box to continue',
                          child: Column(
                            children: _routineLevels.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _OptionCard(
                                  title: item,
                                  description: _routineDescription(item),
                                  selected: item == _selectedRoutineLevel,
                                  onTap: () async {
                                    await _selectAndAdvance(() {
                                      _selectedRoutineLevel = item;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        _QuestionLayout(
                          title: 'When would this fit best?',
                          subtitle:
                              'Pick one time window and Momentum will prepare a cue automatically.',
                          footerHint: 'Tap a box to continue',
                          child: Column(
                            children: _habitWindows.map((window) {
                              final cue = _defaultCueForWindow(window);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _OptionCard(
                                  title: window,
                                  description: 'Suggested cue: $cue',
                                  selected: window == _selectedHabitWindow,
                                  onTap: () async {
                                    await _selectAndAdvance(() {
                                      _selectedHabitWindow = window;
                                      _cueController.text = cue;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        _QuestionLayout(
                          title: 'Choose your starting setup',
                          subtitle:
                              'Pick a realistic target, how you want to track it, and whether reminders should be ready.',
                          footerHint: 'Select your setup, then enter the app',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SetupSummaryCard(
                                habitLabel: _selectedGoalType == 'custom'
                                    ? (_customHabitNameController.text
                                            .trim()
                                            .isEmpty
                                        ? 'Custom habit'
                                        : _customHabitNameController.text
                                            .trim())
                                    : _goalTypeLabel(_selectedGoalType),
                                cue: _cueController.text.trim(),
                                target:
                                    '$_selectedTargetValue $_selectedTargetUnit',
                                tracking: _selectedTracking,
                                remindersEnabled: _remindersEnabled,
                              ),
                              const SizedBox(height: 16),
                              const _SectionLabel('Starter target'),
                              const SizedBox(height: 8),
                              Column(
                                children: _targetOptions.map((item) {
                                  final selected =
                                      item.value == _selectedTargetValue &&
                                          item.unit == _selectedTargetUnit;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _OptionCard(
                                      title: '${item.value} ${item.unit}',
                                      description: _targetDescription(item),
                                      selected: selected,
                                      onTap: () {
                                        setState(() {
                                          _selectedTargetValue = item.value;
                                          _selectedTargetUnit = item.unit;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                              const _SectionLabel('Tracking preference'),
                              const SizedBox(height: 8),
                              Column(
                                children: _trackingOptions.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _OptionCard(
                                      title: item,
                                      description: _trackingDescription(item),
                                      selected: item == _selectedTracking,
                                      onTap: () {
                                        setState(
                                            () => _selectedTracking = item);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                              const _SectionLabel('Reminders'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniChoiceCard(
                                      label: 'Enabled',
                                      description: 'Green prompt ready',
                                      selected: _remindersEnabled,
                                      onTap: () {
                                        setState(
                                            () => _remindersEnabled = true);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MiniChoiceCard(
                                      label: 'Not now',
                                      description: 'Keep it manual',
                                      selected: !_remindersEnabled,
                                      onTap: () {
                                        setState(
                                            () => _remindersEnabled = false);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.value(16, min: 14, max: 18)),
                  if (_showBottomButton)
                    SizedBox(
                      width: double.infinity,
                      height: responsive.minButtonHeight,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.inkText,
                          foregroundColor: AppColors.paper,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.radius(18),
                            ),
                          ),
                        ),
                        onPressed: _isSaving || !_canContinue
                            ? null
                            : _page == 4
                                ? _finish
                                : _advancePage,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.paper,
                                ),
                              )
                            : Text(_primaryButtonLabel),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.value(14, min: 12, max: 16),
                      ),
                      child: Text(
                        'Tap an answer box to continue',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: responsive.font(12, min: 11.5, max: 12.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _goalTypeIcon(String value) {
    switch (value) {
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'custom':
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _goalTypeLabel(String value) {
    switch (value) {
      case 'steps':
        return 'Steps';
      case 'workout':
        return 'Workout';
      case 'water':
        return 'Water';
      case 'sleep':
        return 'Sleep';
      case 'custom':
      default:
        return 'Custom';
    }
  }

  String _goalTypeDescription(String value) {
    switch (value) {
      case 'steps':
        return 'Build a walking routine with a daily target.';
      case 'workout':
        return 'Track short sessions that fit your day.';
      case 'water':
        return 'Stay consistent with hydration prompts.';
      case 'sleep':
        return 'Set a realistic sleep routine goal.';
      case 'custom':
      default:
        return 'Name your own habit and shape it your way.';
    }
  }

  String _motivationDescription(String value) {
    switch (value) {
      case 'Better health':
        return 'A simple habit that supports your long-term wellbeing.';
      case 'More energy':
        return 'Create a routine that helps you feel more active.';
      case 'A better routine':
        return 'Use structure and cues to make the day smoother.';
      case 'Fitness goals':
        return 'Build consistency that supports training progress.';
      case 'Less stress':
      default:
        return 'Choose a habit that feels calm, manageable, and grounding.';
    }
  }

  String _routineDescription(String value) {
    switch (value) {
      case 'Just getting started':
        return 'Keep the first goal small and easy to repeat.';
      case 'Somewhat active':
        return 'A moderate target should feel realistic and steady.';
      case 'Mostly consistent':
        return 'Momentum can start you with a stronger target.';
      case 'Very consistent':
      default:
        return 'You are ready for a more ambitious starting point.';
    }
  }

  String _targetDescription(_TargetOption item) {
    return 'Starter goal for your ${_goalTypeLabel(_selectedGoalType).toLowerCase()} routine.';
  }

  String _trackingDescription(String value) {
    switch (value) {
      case 'Manual now, health sync later':
        return 'Start simple today and connect step data later if needed.';
      case 'Health sync when ready':
        return 'Keep the UI ready for Health Connect or Apple Health later.';
      case 'Manual logging':
      default:
        return 'Use quick manual progress updates inside the app.';
    }
  }
}

class _QuestionLayout extends StatelessWidget {
  const _QuestionLayout({
    required this.title,
    required this.subtitle,
    required this.footerHint,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String footerHint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return ListView(
      padding: EdgeInsets.only(bottom: responsive.value(20, min: 16, max: 24)),
      physics: const BouncingScrollPhysics(),
      children: [
        SizedBox(height: responsive.value(10, min: 8, max: 12)),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: responsive.font(27, min: 24, max: 29),
                color: AppColors.inkText,
              ),
        ),
        SizedBox(height: responsive.value(10, min: 8, max: 12)),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.slate,
                height: 1.55,
                fontSize: responsive.font(15, min: 14, max: 16),
              ),
        ),
        SizedBox(height: responsive.value(16, min: 14, max: 18)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.value(12, min: 10, max: 14),
            vertical: responsive.value(9, min: 8, max: 10),
          ),
          decoration: BoxDecoration(
            color: AppColors.mossDim,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            footerHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.moss,
              fontSize: responsive.font(11.5, min: 11, max: 12),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: responsive.value(18, min: 16, max: 20)),
        Container(
          padding: responsive.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(responsive.radius(22)),
            border: Border.all(color: AppColors.line),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.radius(18)),
      child: Ink(
        padding: responsive.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.mossDim : AppColors.paper,
          borderRadius: BorderRadius.circular(responsive.radius(18)),
          border: Border.all(
            color: selected ? AppColors.moss : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: responsive.value(44, min: 40, max: 48),
              height: responsive.value(44, min: 40, max: 48),
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.emberDim,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.moss : AppColors.ember,
                size: responsive.value(22, min: 20, max: 24),
              ),
            ),
            SizedBox(width: responsive.value(14, min: 12, max: 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColors.moss : AppColors.inkText,
                      fontSize: responsive.font(15, min: 14, max: 16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: responsive.value(6, min: 4, max: 8)),
                  Text(
                    description,
                    style: TextStyle(
                      color: selected ? AppColors.moss : AppColors.slate,
                      fontSize: responsive.font(11.5, min: 11, max: 12),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.value(12, min: 10, max: 14)),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.moss : AppColors.slate,
              size: responsive.value(22, min: 20, max: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.radius(18)),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.value(16, min: 14, max: 18),
          vertical: responsive.value(14, min: 12, max: 16),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.mossDim : AppColors.paper,
          borderRadius: BorderRadius.circular(responsive.radius(18)),
          border: Border.all(
            color: selected ? AppColors.moss : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
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
                      color: selected ? AppColors.moss : AppColors.inkText,
                      fontSize: responsive.font(14, min: 13.5, max: 15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: responsive.value(4, min: 4, max: 6)),
                  Text(
                    description,
                    style: TextStyle(
                      color: selected ? AppColors.moss : AppColors.slate,
                      fontSize: responsive.font(11.5, min: 11, max: 12),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.value(12, min: 10, max: 14)),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.moss : AppColors.slate,
              size: responsive.value(22, min: 20, max: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChoiceCard extends StatelessWidget {
  const _MiniChoiceCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.radius(16)),
      child: Ink(
        padding: responsive.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.mossDim : AppColors.paper,
          borderRadius: BorderRadius.circular(responsive.radius(16)),
          border: Border.all(
            color: selected ? AppColors.moss : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.moss : AppColors.inkText,
                fontSize: responsive.font(14, min: 13.5, max: 15),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: responsive.value(6, min: 4, max: 8)),
            Text(
              description,
              style: TextStyle(
                color: selected ? AppColors.moss : AppColors.slate,
                fontSize: responsive.font(11.5, min: 11, max: 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.slate,
        fontSize: responsive.font(11, min: 10.5, max: 11.5),
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _SetupSummaryCard extends StatelessWidget {
  const _SetupSummaryCard({
    required this.habitLabel,
    required this.cue,
    required this.target,
    required this.tracking,
    required this.remindersEnabled,
  });

  final String habitLabel;
  final String cue;
  final String target;
  final String tracking;
  final bool remindersEnabled;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      padding: responsive.all(14),
      decoration: BoxDecoration(
        color: AppColors.mossDim,
        borderRadius: BorderRadius.circular(responsive.radius(18)),
        border: Border.all(color: const Color(0xFFBFD2C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Momentum will start with',
            style: TextStyle(
              color: AppColors.moss,
              fontSize: responsive.font(11.5, min: 11, max: 12),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: responsive.value(10, min: 8, max: 12)),
          Text(
            habitLabel,
            style: TextStyle(
              color: AppColors.inkText,
              fontSize: responsive.font(17, min: 16, max: 18),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: responsive.value(12, min: 10, max: 14)),
          Wrap(
            spacing: responsive.value(8, min: 8, max: 10),
            runSpacing: responsive.value(8, min: 8, max: 10),
            children: [
              _SummaryPill(icon: Icons.track_changes_rounded, label: target),
              _SummaryPill(icon: Icons.link_rounded, label: cue),
              _SummaryPill(
                icon: Icons.edit_note_rounded,
                label: tracking,
              ),
              _SummaryPill(
                icon: remindersEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                label: remindersEnabled ? 'Reminders ready' : 'No reminders',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(10, min: 9, max: 12),
        vertical: responsive.value(9, min: 8, max: 10),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: responsive.value(16, min: 15, max: 18),
              color: AppColors.moss),
          SizedBox(width: responsive.value(6, min: 6, max: 8)),
          Text(
            label,
            style: TextStyle(
              color: AppColors.inkText,
              fontSize: responsive.font(11.5, min: 11, max: 12),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetOption {
  const _TargetOption(this.value, this.unit);

  final int value;
  final String unit;
}

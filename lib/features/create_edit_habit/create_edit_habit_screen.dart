import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/habits/habit_customization.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';
import '../../models/habit.dart';
import '../../state/habit_provider.dart';

class CreateEditHabitScreen extends StatefulWidget {
  const CreateEditHabitScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<CreateEditHabitScreen> createState() => _CreateEditHabitScreenState();
}

class _CreateEditHabitScreenState extends State<CreateEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _frequencyOptions = const ['Daily', 'Weekdays', 'Custom'];
  final _cueOptions = const [
    'When I wake up',
    'After breakfast',
    'After lunch',
    'Before bed',
    'When I notice a free moment',
    'Custom cue',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _unitController;
  late final TextEditingController _cueController;
  late String _selectedFrequency;
  late String _selectedCue;
  late String _selectedCategoryId;
  late int _selectedColorValue;
  late String _selectedIconKey;
  late bool _customColorChoice;
  late bool _customIconChoice;
  late bool _manualLoggingEnabled;
  TimeOfDay? _reminderTime;
  late String _reminderMode;

  HabitCategoryPreset get _selectedCategoryPreset {
    return habitCategoryPresetById(_selectedCategoryId);
  }

  Color get _selectedAccent {
    return Color(_selectedColorValue);
  }

  @override
  void initState() {
    super.initState();

    final existingHabit = widget.habit;
    final initialCategoryId = existingHabit == null
        ? 'steps'
        : resolvedHabitCategoryId(existingHabit);
    final initialPreset = habitCategoryPresetById(initialCategoryId);

    _nameController = TextEditingController(
      text: existingHabit?.name ?? initialPreset.suggestedName,
    );
    _targetController = TextEditingController(
      text: existingHabit?.targetValue.toString() ??
          initialPreset.defaultTarget.toString(),
    );
    _unitController = TextEditingController(
      text: existingHabit?.unit ?? initialPreset.defaultUnit,
    );
    _cueController = TextEditingController(
      text: existingHabit?.cue ?? initialPreset.defaultCue,
    );
    _selectedFrequency = existingHabit?.frequency ?? 'Daily';
    _selectedCue = _cueOptions.contains(existingHabit?.cue)
        ? existingHabit!.cue
        : (_cueOptions.contains(_cueController.text)
            ? _cueController.text
            : 'Custom cue');
    _selectedCategoryId = initialCategoryId;
    _selectedColorValue =
        existingHabit?.colorValue ?? initialPreset.defaultColorValue;
    _selectedIconKey = existingHabit?.iconKey ?? initialPreset.defaultIconKey;
    _customColorChoice = existingHabit?.colorValue != null &&
        existingHabit!.colorValue != initialPreset.defaultColorValue;
    _customIconChoice = existingHabit?.iconKey != null &&
        existingHabit!.iconKey != initialPreset.defaultIconKey;
    _manualLoggingEnabled = existingHabit?.manualLoggingEnabled ?? false;
    _reminderTime = existingHabit?.reminderTime;
    _reminderMode = existingHabit?.reminderMode ?? 'standard';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _cueController.dispose();
    super.dispose();
  }

  void _selectCategory(String categoryId) {
    final previousPreset = habitCategoryPresetById(_selectedCategoryId);
    final nextPreset = habitCategoryPresetById(categoryId);

    setState(() {
      _selectedCategoryId = categoryId;

      if (!_customColorChoice) {
        _selectedColorValue = nextPreset.defaultColorValue;
      }
      if (!_customIconChoice) {
        _selectedIconKey = nextPreset.defaultIconKey;
      }

      if (_nameController.text.trim().isEmpty ||
          _nameController.text.trim() == previousPreset.suggestedName) {
        _nameController.text = nextPreset.suggestedName;
      }
      if (_unitController.text.trim().isEmpty ||
          _unitController.text.trim() == previousPreset.defaultUnit) {
        _unitController.text = nextPreset.defaultUnit;
      }
      if (_targetController.text.trim().isEmpty ||
          _targetController.text.trim() ==
              previousPreset.defaultTarget.toString()) {
        _targetController.text = nextPreset.defaultTarget.toString();
      }
      if (_cueController.text.trim().isEmpty ||
          _cueController.text.trim() == previousPreset.defaultCue) {
        _cueController.text = nextPreset.defaultCue;
        _selectedCue = _cueOptions.contains(nextPreset.defaultCue)
            ? nextPreset.defaultCue
            : 'Custom cue';
      }
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _selectedAccent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() => _reminderTime = selected);
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<HabitProvider>();
    final habit = Habit(
      id: widget.habit?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      targetValue: int.parse(_targetController.text.trim()),
      unit: _unitController.text.trim(),
      cue: _cueController.text.trim(),
      manualLoggingEnabled:
          _selectedCategoryId == 'steps' ? _manualLoggingEnabled : false,
      categoryId: _selectedCategoryId,
      colorValue: _selectedColorValue,
      iconKey: _selectedIconKey,
      reminderTime: _reminderTime,
      reminderMode: _reminderMode,
      frequency: _selectedFrequency,
      currentStreak: widget.habit?.currentStreak ?? 0,
      bestStreak: widget.habit?.bestStreak ?? 0,
      createdAt: widget.habit?.createdAt ?? DateTime.now(),
      lastCompletedDate: widget.habit?.lastCompletedDate,
    );

    if (widget.habit == null) {
      await provider.addHabit(habit);
    } else {
      await provider.updateHabit(habit);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteHabit() async {
    final habit = widget.habit;
    if (habit == null) {
      return;
    }

    await context.read<HabitProvider>().deleteHabit(habit.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final previewBackground = isDark
        ? Color.lerp(Colors.black, _selectedAccent, 0.28)!
        : _selectedAccent;

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
        appBar: AppBar(
          systemOverlayStyle: overlayStyle,
          title: Text(widget.habit == null ? 'Create habit' : 'Edit habit'),
        ),
        bottomNavigationBar: SafeArea(
          minimum: EdgeInsets.fromLTRB(
            responsive.pagePadding,
            responsive.value(10, min: 8, max: 12),
            responsive.pagePadding,
            responsive.bottomSafeGap,
          ),
          child: SizedBox(
            height: responsive.minButtonHeight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _selectedAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.radius(18)),
                ),
              ),
              onPressed: _saveHabit,
              child: Text(
                widget.habit == null ? 'Save habit' : 'Save changes',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                responsive.pagePadding,
                responsive.value(8, min: 8, max: 12),
                responsive.pagePadding,
                responsive.value(116, min: 104, max: 132),
              ),
              children: [
                Text(
                  'Set up a clean routine.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textSoft,
                      ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: previewBackground,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedAccent.withValues(
                            alpha: isDark ? 0.18 : 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: isDark ? 0.12 : 0.9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          habitIconPresetByKey(_selectedIconKey).icon,
                          color: isDark ? Colors.white : _selectedAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.trim().isEmpty
                                  ? _selectedCategoryPreset.suggestedName
                                  : _nameController.text.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_targetController.text.trim().isEmpty ? _selectedCategoryPreset.defaultTarget : _targetController.text.trim()} ${_unitController.text.trim().isEmpty ? _selectedCategoryPreset.defaultUnit : _unitController.text.trim()} • ${_selectedCategoryPreset.label}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Pick a category'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final cardWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: 12,
                      children: habitCategoryPresets.map((preset) {
                        return SizedBox(
                          width: cardWidth,
                          child: _CategoryCard(
                            preset: preset,
                            selected: preset.id == _selectedCategoryId,
                            accent: _selectedAccent,
                            onTap: () => _selectCategory(preset.id),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Habit details'),
                const SizedBox(height: 10),
                _EditorPanel(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Habit name',
                          hintText: 'e.g. Evening walk',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Add a habit name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetController,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Target',
                                hintText: '6000',
                              ),
                              validator: (value) {
                                final parsed = int.tryParse(value ?? '');
                                if (parsed == null || parsed <= 0) {
                                  return 'Use a number.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                hintText: 'steps',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Add a unit.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCategoryId == 'steps') ...[
                        const SizedBox(height: 14),
                        SwitchListTile.adaptive(
                          value: _manualLoggingEnabled,
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: _selectedAccent,
                          activeTrackColor:
                              _selectedAccent.withValues(alpha: 0.35),
                          title: const Text(
                            'Allow manual step logging',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Keep this off if steps should only come from Google Health or Apple Fitness.',
                          ),
                          onChanged: (value) {
                            setState(() => _manualLoggingEnabled = value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Choose an icon'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: habitIconPresets.map((preset) {
                    return _IconChoiceTile(
                      icon: preset.icon,
                      label: preset.label,
                      selected: preset.key == _selectedIconKey,
                      accent: _selectedAccent,
                      onTap: () {
                        setState(() {
                          _customIconChoice = true;
                          _selectedIconKey = preset.key;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Choose a color'),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: habitAccentOptions.map((value) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _ColorChoiceDot(
                          color: Color(value),
                          selected: value == _selectedColorValue,
                          onTap: () {
                            setState(() {
                              _customColorChoice = true;
                              _selectedColorValue = value;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Frequency'),
                const SizedBox(height: 10),
                _AdaptiveChoiceWrap(
                  options: _frequencyOptions,
                  columns: 3,
                  accent: _selectedAccent,
                  selectedValue: _selectedFrequency,
                  onSelected: (option) {
                    setState(() => _selectedFrequency = option);
                  },
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Cue and context'),
                const SizedBox(height: 10),
                _AdaptiveChoiceWrap(
                  options: _cueOptions,
                  columns: 2,
                  accent: _selectedAccent,
                  selectedValue: _selectedCue,
                  expandPredicate: (option) =>
                      option.length > 18 || option == 'Custom cue',
                  onSelected: (option) {
                    setState(() {
                      _selectedCue = option;
                      if (option != 'Custom cue') {
                        _cueController.text = option;
                      } else if (_cueOptions.contains(_cueController.text)) {
                        _cueController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                _EditorPanel(
                  child: TextFormField(
                    controller: _cueController,
                    decoration: const InputDecoration(
                      labelText: 'Cue',
                      hintText: 'e.g. after dinner',
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionLabel(text: 'Reminder'),
                const SizedBox(height: 10),
                _EditorPanel(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(22),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _selectedAccent.withValues(
                                alpha: isDark ? 0.2 : 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: _selectedAccent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _reminderTime == null
                                    ? 'Choose a reminder time'
                                    : 'Reminder at ${_reminderTime!.format(context)}',
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_reminderTime != null)
                          IconButton(
                            onPressed: () =>
                                setState(() => _reminderTime = null),
                            icon: Icon(Icons.close_rounded,
                                color: palette.textSoft),
                          )
                        else
                          Icon(Icons.chevron_right_rounded,
                              color: palette.textSoft),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _AdaptiveChoiceWrap(
                  options: const ['Standard', 'Persistent', 'Vibrate'],
                  columns: 3,
                  accent: _selectedAccent,
                  selectedValue: switch (_reminderMode) {
                    'persistent' => 'Persistent',
                    'vibrate' => 'Vibrate',
                    _ => 'Standard',
                  },
                  onSelected: (option) {
                    setState(() {
                      _reminderMode = switch (option) {
                        'Persistent' => 'persistent',
                        'Vibrate' => 'vibrate',
                        _ => 'standard',
                      };
                    });
                  },
                ),
                if (widget.habit != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: _deleteHabit,
                      child: Text(
                        'Delete habit',
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: palette.textSoft,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.preset,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final HabitCategoryPreset preset;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                : palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? accent : palette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: isDark ? 0.24 : 0.18)
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  preset.icon,
                  color: selected ? accent : palette.textSoft,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                preset.label,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: compact ? 48 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.24 : 0.14)
                : palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : palette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? accent : palette.text,
                fontSize: compact ? 12 : 12.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveChoiceWrap extends StatelessWidget {
  const _AdaptiveChoiceWrap({
    required this.options,
    required this.columns,
    required this.accent,
    required this.selectedValue,
    required this.onSelected,
    this.expandPredicate,
  });

  final List<String> options;
  final int columns;
  final Color accent;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final bool Function(String option)? expandPredicate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.map((option) {
            final expanded = expandPredicate?.call(option) ?? false;
            return SizedBox(
              width: expanded ? constraints.maxWidth : itemWidth,
              child: _ChoiceChipButton(
                label: option,
                selected: option == selectedValue,
                accent: accent,
                compact: columns >= 3,
                onTap: () => onSelected(option),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _IconChoiceTile extends StatelessWidget {
  const _IconChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 74,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.24 : 0.14)
                : palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : palette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? accent : palette.textSoft,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? accent : palette.textSoft,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChoiceDot extends StatelessWidget {
  const _ColorChoiceDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: selected ? 52 : 44,
        height: selected ? 52 : 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? palette.text : Colors.transparent,
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

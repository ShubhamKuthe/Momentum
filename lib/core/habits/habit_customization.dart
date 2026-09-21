import 'package:flutter/material.dart';

import '../../models/habit.dart';

@immutable
class HabitCategoryPreset {
  const HabitCategoryPreset({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.suggestedName,
    required this.defaultUnit,
    required this.defaultTarget,
    required this.defaultCue,
    required this.defaultIconKey,
    required this.defaultColorValue,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String suggestedName;
  final String defaultUnit;
  final int defaultTarget;
  final String defaultCue;
  final String defaultIconKey;
  final int defaultColorValue;
}

@immutable
class HabitIconPreset {
  const HabitIconPreset({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

const List<HabitCategoryPreset> habitCategoryPresets = [
  HabitCategoryPreset(
    id: 'steps',
    label: 'Steps',
    subtitle: 'Walking, running, and move goals',
    icon: Icons.directions_walk_rounded,
    suggestedName: 'Daily Steps',
    defaultUnit: 'steps',
    defaultTarget: 6000,
    defaultCue: 'After lunch',
    defaultIconKey: 'walk',
    defaultColorValue: 0xFFFF6B82,
  ),
  HabitCategoryPreset(
    id: 'workout',
    label: 'Workout',
    subtitle: 'Short sessions that fit your day',
    icon: Icons.fitness_center_rounded,
    suggestedName: 'Workout Session',
    defaultUnit: 'min',
    defaultTarget: 20,
    defaultCue: 'When I notice a free moment',
    defaultIconKey: 'workout',
    defaultColorValue: 0xFF8E61F5,
  ),
  HabitCategoryPreset(
    id: 'water',
    label: 'Water',
    subtitle: 'Hydration and intake goals',
    icon: Icons.water_drop_rounded,
    suggestedName: 'Water Intake',
    defaultUnit: 'glasses',
    defaultTarget: 8,
    defaultCue: 'After breakfast',
    defaultIconKey: 'water',
    defaultColorValue: 0xFF4C95FF,
  ),
  HabitCategoryPreset(
    id: 'sleep',
    label: 'Sleep',
    subtitle: 'Rest, recovery, and evening habits',
    icon: Icons.bedtime_rounded,
    suggestedName: 'Sleep Goal',
    defaultUnit: 'hours',
    defaultTarget: 8,
    defaultCue: 'Before bed',
    defaultIconKey: 'sleep',
    defaultColorValue: 0xFFFFA053,
  ),
  HabitCategoryPreset(
    id: 'mindfulness',
    label: 'Mindfulness',
    subtitle: 'Breathing, journaling, and calm routines',
    icon: Icons.spa_rounded,
    suggestedName: 'Mindful Minutes',
    defaultUnit: 'min',
    defaultTarget: 10,
    defaultCue: 'When I wake up',
    defaultIconKey: 'mindfulness',
    defaultColorValue: 0xFF4FAE86,
  ),
  HabitCategoryPreset(
    id: 'custom',
    label: 'Custom',
    subtitle: 'Create your own routine',
    icon: Icons.auto_awesome_rounded,
    suggestedName: 'My Habit',
    defaultUnit: 'times',
    defaultTarget: 1,
    defaultCue: 'Custom cue',
    defaultIconKey: 'spark',
    defaultColorValue: 0xFFFF7A59,
  ),
];

const List<HabitIconPreset> habitIconPresets = [
  HabitIconPreset(
    key: 'walk',
    icon: Icons.directions_walk_rounded,
    label: 'Walk',
  ),
  HabitIconPreset(
    key: 'workout',
    icon: Icons.fitness_center_rounded,
    label: 'Workout',
  ),
  HabitIconPreset(
    key: 'water',
    icon: Icons.water_drop_rounded,
    label: 'Water',
  ),
  HabitIconPreset(
    key: 'sleep',
    icon: Icons.bedtime_rounded,
    label: 'Sleep',
  ),
  HabitIconPreset(
    key: 'mindfulness',
    icon: Icons.spa_rounded,
    label: 'Mindful',
  ),
  HabitIconPreset(
    key: 'heart',
    icon: Icons.favorite_rounded,
    label: 'Heart',
  ),
  HabitIconPreset(
    key: 'run',
    icon: Icons.directions_run_rounded,
    label: 'Run',
  ),
  HabitIconPreset(
    key: 'bike',
    icon: Icons.pedal_bike_rounded,
    label: 'Cycle',
  ),
  HabitIconPreset(
    key: 'timer',
    icon: Icons.timer_rounded,
    label: 'Timer',
  ),
  HabitIconPreset(
    key: 'spark',
    icon: Icons.auto_awesome_rounded,
    label: 'Custom',
  ),
];

const List<int> habitAccentOptions = [
  0xFFFF6B82,
  0xFFFF7A59,
  0xFFFFA053,
  0xFFF2C94C,
  0xFF4FAE86,
  0xFF4C95FF,
  0xFF8E61F5,
  0xFFB45CFF,
];

HabitCategoryPreset habitCategoryPresetById(String? id) {
  return habitCategoryPresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => habitCategoryPresets.last,
  );
}

HabitIconPreset habitIconPresetByKey(String? key) {
  return habitIconPresets.firstWhere(
    (preset) => preset.key == key,
    orElse: () => habitIconPresets.last,
  );
}

String inferLegacyHabitCategoryId(Habit habit) {
  final name = habit.name.toLowerCase();
  final unit = habit.unit.toLowerCase();
  final cue = habit.cue.toLowerCase();
  final combined = '$name $unit $cue';

  if (combined.contains('step') || combined.contains('walk')) {
    return 'steps';
  }
  if (combined.contains('workout') ||
      combined.contains('exercise') ||
      combined.contains('gym') ||
      combined.contains('session') ||
      combined.contains('run') ||
      combined.contains('cycle')) {
    return 'workout';
  }
  if (combined.contains('water') ||
      combined.contains('drink') ||
      combined.contains('hydration') ||
      unit.contains('glass') ||
      unit.contains('ml') ||
      unit.contains('litre')) {
    return 'water';
  }
  if (combined.contains('sleep') ||
      combined.contains('bed') ||
      combined.contains('rest') ||
      unit.contains('hour')) {
    return 'sleep';
  }
  if (combined.contains('mindful') ||
      combined.contains('meditat') ||
      combined.contains('breath') ||
      combined.contains('journal')) {
    return 'mindfulness';
  }
  return 'custom';
}

String resolvedHabitCategoryId(Habit habit) {
  return habit.categoryId ?? inferLegacyHabitCategoryId(habit);
}

HabitCategoryPreset resolvedHabitCategory(Habit habit) {
  return habitCategoryPresetById(resolvedHabitCategoryId(habit));
}

String defaultHabitIconKeyForCategory(String categoryId) {
  return habitCategoryPresetById(categoryId).defaultIconKey;
}

int defaultHabitColorValueForCategory(String categoryId) {
  return habitCategoryPresetById(categoryId).defaultColorValue;
}

String resolvedHabitIconKey(Habit habit) {
  return habit.iconKey ?? defaultHabitIconKeyForCategory(resolvedHabitCategoryId(habit));
}

IconData resolvedHabitIcon(Habit habit) {
  return habitIconPresetByKey(resolvedHabitIconKey(habit)).icon;
}

int resolvedHabitColorValue(Habit habit) {
  return habit.colorValue ?? defaultHabitColorValueForCategory(resolvedHabitCategoryId(habit));
}

Color resolvedHabitAccentColor(Habit habit) {
  return Color(resolvedHabitColorValue(habit));
}

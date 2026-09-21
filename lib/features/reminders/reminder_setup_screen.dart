import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/habit.dart';
import '../../services/database_service.dart';
import '../../services/reminder_service.dart';
import '../../state/habit_provider.dart';

class ReminderSetupScreen extends StatefulWidget {
  const ReminderSetupScreen({
    super.key,
    required this.habit,
    required this.provider,
  });

  final Habit habit;
  final HabitProvider provider;

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  static const _screenBackground = Color(0xFF1F1F22);
  static const _cardBackground = Color(0xFF2C2C2F);
  static const _cardDivider = Color(0xFF3A3A3E);
  static const _mutedText = Color(0xFF9B9BA1);
  static const _accentGreen = Color(0xFF32D74B);

  final DatabaseService _databaseService = DatabaseService();
  final ReminderService _reminderService = ReminderService.instance;

  String _permissionState = 'not_requested';
  TimeOfDay? _time;
  String _mode = 'standard';
  bool _loading = true;
  bool _saving = false;

  bool get _remindersEnabled => _time != null;

  String get _permissionLabel => switch (_permissionState) {
        'granted' => 'Granted',
        'denied' => 'Denied',
        _ => 'Not requested',
      };

  String get _cueLabel =>
      widget.habit.cue.isEmpty ? 'No cue yet' : widget.habit.cue;

  @override
  void initState() {
    super.initState();
    _time = widget.habit.reminderTime;
    _mode = widget.habit.reminderMode;
    _load();
  }

  Future<void> _load() async {
    var state = await _databaseService.getReminderPermissionState();
    final systemEnabled = await _reminderService.areNotificationsEnabled();
    if (systemEnabled == true) {
      state = 'granted';
    } else if (systemEnabled == false && state == 'granted') {
      state = 'denied';
      await _databaseService.setReminderPermissionState(state);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionState = state;
      _loading = false;
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentGreen,
              surface: _screenBackground,
            ),
            scaffoldBackgroundColor: _screenBackground,
            dialogTheme: const DialogThemeData(
              backgroundColor: _screenBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      setState(() => _time = selected);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.provider.updateHabit(
      widget.habit.copyWith(
        reminderTime: _time,
        reminderMode: _mode,
        clearReminder: _time == null,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  Future<void> _setPermissionState(String value) async {
    String resolvedState = value;

    if (value == 'granted') {
      final granted = await _reminderService.requestPermission();
      resolvedState = granted ? 'granted' : 'denied';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Notification permission granted'
                  : 'Permission was denied on this device',
            ),
          ),
        );
      }
    }

    await _databaseService.setReminderPermissionState(resolvedState);
    if (mounted) {
      setState(() => _permissionState = resolvedState);
    }
  }

  void _toggleReminders(bool value) {
    setState(() {
      _time = value ? (_time ?? const TimeOfDay(hour: 8, minute: 0)) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle = SystemUiOverlayStyle.light.copyWith(
      statusBarColor: _screenBackground,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: _screenBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _screenBackground,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _accentGreen),
              )
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
                    children: [
                      _ReminderHeader(
                        title: 'Reminders',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 18),
                      _DarkGroupCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Reminder for $_cueLabel',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _remindersEnabled,
                                    onChanged: _toggleReminders,
                                    activeTrackColor: _accentGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _NotificationActionRow(
                                title: 'Time',
                                trailing: _time == null
                                    ? 'Off'
                                    : _time!.format(context),
                                onTap: _pickTime,
                              ),
                              const _GroupDivider(),
                              _NotificationActionRow(
                                title: 'Mode',
                                trailing: switch (_mode) {
                                  'persistent' => 'Persistent',
                                  'vibrate' => 'Vibrate',
                                  _ => 'Standard',
                                },
                                onTap: null,
                              ),
                              const SizedBox(height: 14),
                              _ModeSelector(
                                value: _mode,
                                onChanged: (value) =>
                                    setState(() => _mode = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DarkGroupCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NotificationActionRow(
                                title: 'Permission',
                                trailing: _permissionLabel,
                                onTap: null,
                              ),
                              const SizedBox(height: 14),
                              _PermissionSelector(
                                value: _permissionState,
                                onChanged: _setPermissionState,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DarkGroupCard(
                        child: _NotificationActionRow(
                          title: 'Test Reminder',
                          trailingIcon: Icons.campaign_rounded,
                          trailingColor: _accentGreen,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final enabled = await _reminderService
                                .areNotificationsEnabled();
                            if (enabled == false) {
                              final granted =
                                  await _reminderService.requestPermission();
                              if (!granted) {
                                if (!mounted) {
                                  return;
                                }
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Allow notifications first, then try Test Reminder again',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await _databaseService
                                  .setReminderPermissionState('granted');
                              if (mounted) {
                                setState(() => _permissionState = 'granted');
                              }
                            }
                            final shown =
                                await _reminderService.showTestReminder(
                              widget.habit.copyWith(
                                reminderTime: _time,
                                reminderMode: _mode,
                                clearReminder: _time == null,
                              ),
                            );
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  shown
                                      ? 'Test reminder sent. Check the notification shade.'
                                      : 'Notifications are blocked on this device.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3A6B50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ReminderHeader extends StatelessWidget {
  const _ReminderHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkGroupCard extends StatelessWidget {
  const _DarkGroupCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ReminderSetupScreenState._cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _NotificationActionRow extends StatelessWidget {
  const _NotificationActionRow({
    required this.title,
    this.trailing,
    this.onTap,
    this.trailingIcon,
    this.trailingColor,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final trailingText = trailing;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(
                  color: _ReminderSetupScreenState._mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (trailingIcon != null) ...[
              Icon(
                trailingIcon,
                color: trailingColor ?? _ReminderSetupScreenState._mutedText,
                size: 22,
              ),
            ] else if (onTap != null) ...[
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ReminderSetupScreenState._mutedText,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionSelector extends StatelessWidget {
  const _PermissionSelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PermissionButton(
              label: 'Not requested',
              selected: value == 'not_requested',
              onTap: () => onChanged('not_requested'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _PermissionButton(
              label: 'Granted',
              selected: value == 'granted',
              onTap: () => onChanged('granted'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _PermissionButton(
              label: 'Denied',
              selected: value == 'denied',
              onTap: () => onChanged('denied'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'Standard',
            selected: value == 'standard',
            onTap: () => onChanged('standard'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeButton(
            label: 'Persistent',
            selected: value == 'persistent',
            onTap: () => onChanged('persistent'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModeButton(
            label: 'Vibrate',
            selected: value == 'vibrate',
            onTap: () => onChanged('vibrate'),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? _ReminderSetupScreenState._accentGreen
              : _ReminderSetupScreenState._cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _ReminderSetupScreenState._accentGreen
                : _ReminderSetupScreenState._cardDivider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionButton extends StatelessWidget {
  const _PermissionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF1F1F22)
                  : _ReminderSetupScreenState._mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: _ReminderSetupScreenState._cardDivider,
    );
  }
}

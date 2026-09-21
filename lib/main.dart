import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/habits/habit_customization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'models/habit.dart';
import 'services/database_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/health_sync_service.dart';
import 'services/reminder_service.dart';
import 'state/habit_provider.dart';
import 'firebase_options.dart';

const _forceReminderSmokeTest = bool.fromEnvironment(
  'FORCE_REMINDER_SMOKE_TEST',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  if (_supportsConfiguredFirebasePlatform) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await ReminderService.instance.initialize();
  await HealthSyncService.instance.initialize();
  runApp(const MomentumApp());
  unawaited(_maybeRunReminderSmokeTest());
}

Future<void> _maybeRunReminderSmokeTest() async {
  if (!_forceReminderSmokeTest || kIsWeb) {
    return;
  }

  final notificationsEnabled =
      await ReminderService.instance.areNotificationsEnabled();
  if (notificationsEnabled == false) {
    debugPrint(
      'Momentum reminder smoke test skipped because notification permission is not granted.',
    );
    return;
  }

  final habit = Habit(
    id: 'debug-reminder-smoke-test',
    name: 'Debug reminder',
    targetValue: 1,
    unit: 'task',
    cue: 'Smoke test',
    reminderMode: 'standard',
    reminderTime: const TimeOfDay(hour: 9, minute: 0),
    createdAt: DateTime.now(),
  );

  await Future<void>.delayed(const Duration(seconds: 3));
  await ReminderService.instance.showTestReminder(habit);
  debugPrint('Momentum reminder smoke test fired.');
}

bool get _supportsConfiguredFirebasePlatform {
  if (kIsWeb) {
    return true;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}

class _MomentumScrollBehavior extends MaterialScrollBehavior {
  const _MomentumScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class MomentumApp extends StatefulWidget {
  const MomentumApp({super.key});

  @override
  State<MomentumApp> createState() => _MomentumAppState();
}

class _MomentumAppState extends State<MomentumApp> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final HabitProvider _habitProvider = HabitProvider();
  bool? _signedIn;
  bool? _onboardingComplete;
  ThemeMode _themeMode = ThemeMode.light;
  bool _largeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAppState();
  }

  Future<void> _loadAppState() async {
    var signedIn = await _databaseService.getSignedIn();
    var complete = await _databaseService.getOnboardingComplete();
    final prefs = await SharedPreferences.getInstance();
    final isDarkTheme = prefs.getBool('profile.darkTheme') ?? false;
    final isLargeText = prefs.getBool('profile.largeText') ?? false;

    if (_supportsConfiguredFirebasePlatform) {
      final currentUser = await _authService.getRestoredSessionUser();
      if (currentUser != null) {
        await _databaseService.saveUserIdentity(
          name: currentUser.name,
          email: currentUser.email,
        );
        signedIn = true;
        complete = await _databaseService.getOnboardingComplete();
        await _databaseService.setSignedIn(true);
        await _habitProvider.loadHabits();
      } else {
        signedIn = false;
        await _databaseService.setSignedIn(false);
      }
    }

    if (mounted) {
      setState(() {
        _signedIn = signedIn;
        _onboardingComplete = complete;
        _themeMode = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
        _largeTextEnabled = isLargeText;
      });
    }
  }

  Future<void> _handleThemeChanged(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile.darkTheme', enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _handleLargeTextChanged(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile.largeText', enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _largeTextEnabled = enabled;
    });
  }

  Future<void> _completeSignedInSession({
    required String name,
    required String email,
    required String password,
  }) async {
    await _databaseService.saveUserIdentity(
      name: name,
      email: email,
      password: password,
    );
    final alreadyComplete = await _databaseService.getOnboardingComplete();
    await _habitProvider.loadHabits();
    await _databaseService.setSignedIn(true);
    if (!alreadyComplete) {
      await _databaseService.setOnboardingComplete(false);
    }
    if (mounted) {
      setState(() {
        _signedIn = true;
        _onboardingComplete = alreadyComplete;
      });
    }
  }

  Future<void> _handleEmailAuth({
    required String name,
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    try {
      MomentumAuthUser user;

      if (_supportsConfiguredFirebasePlatform) {
        user = createAccount
            ? await _authService.createAccount(
                name: name,
                email: email,
                password: password,
              )
            : await _authService.signInWithEmail(
                email: email,
                password: password,
              );
      } else {
        user = MomentumAuthUser(
          name: name,
          email: email,
          uid: email.trim().toLowerCase(),
          isNewUser: createAccount,
        );
      }

      if (createAccount) {
        await _databaseService.clearUserDataForEmail(user.email);
      }

      await _completeSignedInSession(
        name: user.name,
        email: user.email,
        password: password,
      );
    } catch (error) {
      throw Exception(momentumAuthErrorMessage(error));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_supportsConfiguredFirebasePlatform) {
      throw Exception(
        'Google sign-in is ready on web, Android, and iPhone builds.',
      );
    }

    try {
      final user = await _authService.signInWithGoogle();
      if (user.isNewUser) {
        await _databaseService.clearUserDataForEmail(user.email);
      }
      await _completeSignedInSession(
        name: user.name,
        email: user.email,
        password: '',
      );
    } catch (error) {
      throw Exception(momentumAuthErrorMessage(error));
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (!_supportsConfiguredFirebasePlatform) {
      throw Exception(
        'Apple sign-in is ready on web and iPhone builds once the Apple provider is configured.',
      );
    }

    try {
      final user = await _authService.signInWithApple();
      if (user.isNewUser) {
        await _databaseService.clearUserDataForEmail(user.email);
      }
      await _completeSignedInSession(
        name: user.name,
        email: user.email,
        password: '',
      );
    } catch (error) {
      throw Exception(momentumAuthErrorMessage(error));
    }
  }

  Future<void> _handleForgotPassword(String email) async {
    if (!_supportsConfiguredFirebasePlatform) {
      throw Exception(
        'Password reset is available on web, Android, and iPhone builds.',
      );
    }

    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (error) {
      throw Exception(momentumAuthErrorMessage(error));
    }
  }

  Future<void> _handleSignOut() async {
    if (_supportsConfiguredFirebasePlatform) {
      await _authService.signOut();
    }
    await _databaseService.setSignedIn(false);
    if (!mounted) {
      return;
    }
    setState(() {
      _signedIn = false;
    });
  }

  Future<void> _finishOnboarding(OnboardingAnswers answers) async {
    await _databaseService.setOnboardingGoalType(answers.goalType);
    await _databaseService.setOnboardingAnswers(answers.toMap());
    await _maybeCreateStarterHabit(answers);
    await _databaseService.setOnboardingComplete(true);
    await _habitProvider.loadHabits();
    if (mounted) {
      setState(() => _onboardingComplete = true);
    }
  }

  Future<void> _maybeCreateStarterHabit(OnboardingAnswers answers) async {
    final habits = await _databaseService.getHabits();
    if (habits.isNotEmpty) {
      return;
    }

    final reminderTime = answers.remindersEnabled
        ? _reminderTimeForWindow(answers.preferredWindow)
        : null;
    final categoryId = _starterCategoryForGoalType(answers.goalType);

    final habit = Habit(
      id: 'starter-${DateTime.now().millisecondsSinceEpoch}',
      name: _habitNameForAnswers(answers),
      targetValue: answers.targetValue,
      unit: answers.targetUnit,
      cue: answers.cue,
      categoryId: categoryId,
      colorValue: defaultHabitColorValueForCategory(categoryId),
      iconKey: defaultHabitIconKeyForCategory(categoryId),
      reminderTime: reminderTime,
      frequency: 'Daily',
      createdAt: DateTime.now(),
    );
    await _databaseService.insertHabit(habit);
  }

  String _habitNameForAnswers(OnboardingAnswers answers) {
    switch (answers.goalType) {
      case 'steps':
        return 'Daily Steps';
      case 'workout':
        return 'Workout Session';
      case 'water':
        return 'Water Intake';
      case 'sleep':
        return 'Sleep Goal';
      case 'custom':
        return answers.customHabitName.isEmpty
            ? 'Custom Habit'
            : answers.customHabitName;
      default:
        return 'My Habit';
    }
  }

  String _starterCategoryForGoalType(String goalType) {
    switch (goalType) {
      case 'steps':
      case 'workout':
      case 'water':
      case 'sleep':
        return goalType;
      default:
        return 'custom';
    }
  }

  TimeOfDay? _reminderTimeForWindow(String window) {
    switch (window) {
      case 'Morning':
        return const TimeOfDay(hour: 8, minute: 0);
      case 'Afternoon':
        return const TimeOfDay(hour: 13, minute: 0);
      case 'Evening':
        return const TimeOfDay(hour: 19, minute: 0);
      case 'Before bed':
        return const TimeOfDay(hour: 21, minute: 30);
      case 'Flexible':
      default:
        return null;
    }
  }

  Widget _buildAppShell(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    final systemScale = mediaQuery.textScaler.scale(1);
    final effectiveScale =
        _largeTextEnabled ? math.min(systemScale * 1.12, 1.45) : systemScale;

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(effectiveScale),
      ),
      child: _PreviewShell(child: child ?? const SizedBox.shrink()),
    );
  }

  Widget _buildHomeScreen() {
    if (_signedIn == null || _onboardingComplete == null) {
      return const _AppLoadingScreen();
    }

    if (!_signedIn!) {
      return SignInScreen(
        onEmailAuth: _handleEmailAuth,
        onForgotPassword: _handleForgotPassword,
        onGoogleSignIn: _handleGoogleSignIn,
        onAppleSignIn: _handleAppleSignIn,
      );
    }

    if (_onboardingComplete!) {
      return DashboardScreen(
        isDarkTheme: _themeMode == ThemeMode.dark,
        onThemeChanged: _handleThemeChanged,
        isLargeText: _largeTextEnabled,
        onTextScaleChanged: _handleLargeTextChanged,
        onSignOut: _handleSignOut,
      );
    }

    return OnboardingScreen(onCompleted: _finishOnboarding);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _habitProvider,
      child: MaterialApp(
        title: 'Momentum',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _MomentumScrollBehavior(),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        themeAnimationCurve: Curves.easeOutCubic,
        themeAnimationDuration: const Duration(milliseconds: 280),
        builder: _buildAppShell,
        home: _buildHomeScreen(),
      ),
    );
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.momentum.background,
      body: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final palette = context.momentum;
    final responsive = context.responsive;
    final isLargePreview = mediaQuery.size.width >= 700;
    final previewTopInset = math.max(
      mediaQuery.padding.top,
      kIsWeb ? 54.0 : 48.0,
    );

    if (!isLargePreview) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.isMomentumDark
            ? const Color(0xFF0A0D13)
            : const Color(0xFF14171F),
      ),
      child: Center(
        child: Builder(
          builder: (context) {
            const deviceAspectRatio = 844 / 390;
            final maxFrameWidth = math.min(480.0, mediaQuery.size.width - 72);
            final maxFrameHeight = mediaQuery.size.height - 36;
            var frameWidth = math.max(320.0, maxFrameWidth);
            var frameHeight = frameWidth * deviceAspectRatio;

            if (frameHeight > maxFrameHeight) {
              frameHeight = maxFrameHeight;
              frameWidth = frameHeight / deviceAspectRatio;
            }

            final outerRadius = responsive.radius(44);
            final innerRadius = responsive.radius(34);
            final framePadding = responsive.value(14, min: 12, max: 18);

            return Container(
              width: frameWidth,
              height: frameHeight,
              padding: EdgeInsets.all(framePadding),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(outerRadius),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.42),
                    blurRadius: responsive.value(46, min: 32, max: 52),
                    offset: Offset(0, responsive.value(24, min: 18, max: 28)),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Stack(
                  children: [
                    MediaQuery(
                      data: mediaQuery.copyWith(
                        padding:
                            mediaQuery.padding.copyWith(top: previewTopInset),
                        size: Size(frameWidth - (framePadding * 2),
                            frameHeight - (framePadding * 2)),
                      ),
                      child: child,
                    ),
                    const Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _Notch(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

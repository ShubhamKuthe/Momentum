# Momentum

Momentum is a Flutter habit-building fitness app developed for the MSc COMP702 project. It helps users create health and lifestyle habits, track daily progress, build streaks, receive reminders, and review adaptive goal suggestions based on recent activity.

## Features

- Email, Google, and Apple sign-in flows through Firebase Authentication.
- Guided onboarding that creates a starter habit from the user's goal.
- Habit creation and editing with targets, categories, cue context, icons, colors, and reminders.
- Dashboard with streaks, progress rings, habit cards, and account settings.
- Step habit support with Health Connect / Apple HealthKit integration logic.
- Local persistence for habit data, settings, onboarding state, and session state.
- Reminder scheduling with local notifications.
- Adaptive goal history and suggestion screens.
- Privacy/data controls and report export support.
- Light and dark themes, responsive phone preview layout, and large-text accessibility mode.

## Tech Stack

- Flutter and Dart
- Provider for app state
- Firebase Core, Firebase Auth, Cloud Firestore, Google Sign-In, and Apple Sign-In
- Shared Preferences and sqflite for local persistence
- health, sensors_plus, permission_handler, and flutter_local_notifications
- Syncfusion XLS export tooling

## Project Structure

```text
lib/
  core/                  Shared theme, responsive, and habit utility code
  features/              App screens grouped by feature
  models/                Habit, log, report, and health snapshot models
  services/              Persistence, auth, reminders, health sync, and export services
  state/                 Provider-based app state
  widgets/               Reusable Momentum UI components
test/                    Widget and logic tests
assets/images/           App logo and sign-in assets
docs/                    Project documentation and validation notes
android/, ios/, web/, windows/
                         Platform runners
```

## Getting Started

Install Flutter, then run:

```powershell
cd Momentum
flutter pub get
flutter test
flutter run
```

To run a specific platform:

```powershell
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

## Firebase

The project includes FlutterFire-generated client configuration for web, Android, and iOS. Firebase initialization is enabled for web, Android, and iOS; desktop builds can still run the local preview path without configured Firebase desktop options.

Before using production authentication or Firestore data, verify that the Firebase project, app identifiers, and enabled auth providers match the deployment environment.

## Tests

Run the test suite with:

```powershell
flutter test
```

Current tests cover step sync logic, health sync snapshots, and selected step habit card behavior.

## Documentation

- `docs/e2-step-sync-validation.md` documents validation work for automatic step sync.
- `docs/momentum-implemented-summary.pdf` summarizes the implemented project state.

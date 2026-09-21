import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/core/theme/app_theme.dart';
import 'package:momentum/widgets/step_habit_card.dart';

void main() {
  Widget buildTestCard(String title) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 340,
            child: StepHabitCard(
              title: title,
              currentSteps: 0,
              targetSteps: 6000,
              status: 'Manual fallback',
              onTap: () {},
              onManualLog: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders default Daily Steps card without overflow', (tester) async {
    await tester.pumpWidget(buildTestCard('Daily Steps'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Daily Steps'), findsOneWidget);
    expect(find.text('of 6,000 steps'), findsOneWidget);
  });

  testWidgets('renders long habit title without overflow', (tester) async {
    await tester.pumpWidget(buildTestCard('Daily Steps Tracker Extended'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Daily Steps Tracker'), findsOneWidget);
  });
}

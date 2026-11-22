import 'package:claim_whats_yours/shared/widgets/app_empty_state.dart';
import 'package:claim_whats_yours/shared/widgets/app_error.dart';
import 'package:claim_whats_yours/shared/widgets/app_loading.dart';
import 'package:claim_whats_yours/shared/widgets/responsive_content_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppLoading renders message and progress indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoading(message: 'Loading scholarships...')),
      ),
    );

    expect(find.text('Loading scholarships...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppError renders title, message and triggers retry', (
    tester,
  ) async {
    bool retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppError(
            title: 'Network Failure',
            message: 'Unable to reach backend server',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Network Failure'), findsOneWidget);
    expect(find.text('Unable to reach backend server'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
  });

  testWidgets('AppEmptyState renders title and action callback', (
    tester,
  ) async {
    bool actionFired = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'No Scholarships Found',
            message: 'Try adjusting your eligibility criteria filters.',
            actionLabel: 'Reset Filters',
            onAction: () => actionFired = true,
          ),
        ),
      ),
    );

    expect(find.text('No Scholarships Found'), findsOneWidget);
    expect(
      find.text('Try adjusting your eligibility criteria filters.'),
      findsOneWidget,
    );
    expect(find.text('Reset Filters'), findsOneWidget);

    await tester.tap(find.text('Reset Filters'));
    expect(actionFired, isTrue);
  });

  testWidgets('ResponsiveContentContainer constrains child width', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContentContainer(
            maxWidth: 800,
            child: Text('Constrained Content'),
          ),
        ),
      ),
    );

    expect(find.text('Constrained Content'), findsOneWidget);
    expect(find.byType(ConstrainedBox), findsWidgets);
  });
}

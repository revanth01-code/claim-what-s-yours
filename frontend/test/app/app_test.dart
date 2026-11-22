import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claim_whats_yours/app/app.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_notifier.dart';
import 'package:claim_whats_yours/features/auth/presentation/auth_state.dart';

class _MockInitialAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated();
}

void main() {
  testWidgets('Application starts and renders initial screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_MockInitialAuthNotifier.new),
        ],
        child: const ClaimWhatsYoursApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Claim What's Yours"), findsWidgets);
    expect(find.text('Browse Catalogue'), findsOneWidget);
  });
}

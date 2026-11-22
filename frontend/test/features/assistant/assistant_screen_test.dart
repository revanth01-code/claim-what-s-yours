import 'package:claim_whats_yours/features/assistant/presentation/assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AssistantScreen renders hero banner and grounding notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AssistantScreen(),
      ),
    );

    expect(find.text('AI Guidance Assistant'), findsOneWidget);
    expect(find.text('Official-Source Grounded Guidance'), findsOneWidget);
    expect(find.text('Safety & Zero-Hallucination Policy'), findsOneWidget);
    expect(find.text('STRICT GROUNDING'), findsOneWidget);
  });

  testWidgets('AssistantScreen toggles between English, Telugu, and Hindi sample inquiries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AssistantScreen(),
      ),
    );

    // Default is English
    expect(
      find.text('Sample Grounded Inquiries (English)'),
      findsOneWidget,
    );
    expect(
      find.text('What is the family income limit for Postmatric Scholarships?'),
      findsOneWidget,
    );

    // Switch to Telugu
    await tester.ensureVisible(find.text('తెలుగు'));
    await tester.tap(find.text('తెలుగు'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sample Grounded Inquiries (తెలుగు)'),
      findsOneWidget,
    );
    expect(
      find.text('తెలంగాణ ఈపాస్ పోస్ట్-మెట్రిక్ స్కాలర్‌షిప్ ఆదాయ పరిమితి ఎంత?'),
      findsOneWidget,
    );

    // Switch to Hindi
    await tester.ensureVisible(find.text('हिंदी'));
    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sample Grounded Inquiries (हिंदी)'),
      findsOneWidget,
    );
    expect(
      find.text('पीएम यशस्वी योजना के लिए कौन से दस्तावेज आवश्यक हैं?'),
      findsOneWidget,
    );
  });
}

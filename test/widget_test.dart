import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tm_clock/apps/crew/crew_app.dart';
import 'package:tm_clock/apps/portal/portal_app.dart';

/// Runs against the built-in sample repositories (Env.useFakeData defaults to true).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void desktop(WidgetTester t) {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  group('portal', () {
    testWidgets('signs in and shows the dashboard', (tester) async {
      desktop(tester);
      await tester.pumpWidget(const PortalApp());
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);

      // Empty fields are caught before calling the API.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter your email and password.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'owner@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Live crew board'), findsOneWidget);
      expect(find.text('Miguel Ruiz'), findsOneWidget);
    });

    testWidgets('sign in renders in Spanish', (tester) async {
      desktop(tester);
      await tester.pumpWidget(const PortalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ES'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  /// Sample repositories wait 250 ms; let that elapse even when nothing animates.
  Future<void> settle(WidgetTester t) async {
    await t.pump(); // build the new screen so its repository call starts
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
  }

  group('crew app', () {
    testWidgets('phone sign-in → pick company → clock in', (tester) async {
      phone(tester);
      await tester.pumpWidget(const CrewApp());
      await settle(tester);

      await tester.enterText(find.byType(TextField), '+14075550110');
      await tester.tap(find.text('Send code'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('Choose a company'), findsOneWidget);
      await tester.tap(find.text('Rivera Electric'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 5)); // let the "Now working for…" snackbar close
      await tester.pumpAndSettle();

      // Home: supervisor sees five tabs and the clock-in action.
      expect(find.text('Not clocked in'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));

      await tester.tap(find.text('Clock in'));
      await settle(tester);
      expect(find.textContaining('Lake Nona'), findsOneWidget);

      await tester.tap(find.text('Take a photo'));
      await settle(tester);
      await tester.ensureVisible(find.text('Confirm clock in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm clock in'));
      await settle(tester);

      expect(find.textContaining('Clocked in'), findsWidgets);
      expect(find.text('Clock out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

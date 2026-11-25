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

      // Several companies → chooser. Employee-only ones are shown but can't open the portal.
      expect(find.text('Choose a company'), findsOneWidget);
      expect(find.text('Office admin · San Juan, PR · Free'), findsOneWidget);
      expect(find.textContaining('Crew app only'), findsOneWidget);
      await tester.tap(find.text('Coastal Low Voltage'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a company'), findsOneWidget);

      await tester.tap(find.text('Rivera Electric'));
      await tester.pump(const Duration(milliseconds: 400)); // sample repositories wait 250 ms
      await tester.pumpAndSettle();
      expect(find.text("Who's working now"), findsOneWidget);
      expect(find.textContaining('Now working in Rivera Electric · Supervisor'), findsOneWidget);
      expect(find.text('Miguel Ruiz'), findsOneWidget);

      // Switch company from the menu: the list marks the current one, and the page reloads.
      expect(find.text('Supervisor · Free'), findsOneWidget); // switcher button
      await tester.tap(find.text('Supervisor · Free'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR COMPANIES'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      await tester.tap(find.text('Isla Builders'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('YOUR COMPANIES'), findsNothing);
      expect(find.text('Office admin · Free'), findsOneWidget);
      expect(find.textContaining('Now working in Isla Builders · Office admin'), findsOneWidget);
      expect(find.text('No one is on the clock yet.'), findsOneWidget);
      expect(find.text('Miguel Ruiz'), findsNothing); // Isla's own (empty) board, not Rivera's
      expect(tester.takeException(), isNull);
    });

    testWidgets('dashboard: approve, edit punch, search, hide banner', (tester) async {
      desktop(tester);
      await tester.pumpWidget(const PortalApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'owner@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rivera Electric'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      Future<void> tapShown(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
      }

      // Sections from the prototype.
      expect(find.text('Free plan keeps 90 days of data'), findsOneWidget);
      expect(find.text('See plans · Pro \$499 · Business \$999'), findsOneWidget);
      expect(find.text('Clock-in photos to review'), findsOneWidget);
      expect(find.text('4 waiting'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('Clocked in outside job site'), findsOneWidget);
      expect(find.text('Starting soon'), findsOneWidget);
      expect(find.text('12 of 50 employees'), findsOneWidget);

      // Approve Marco → message, queue and menu badge drop to 3.
      await tapShown(find.widgetWithText(FilledButton, 'Approve').first);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Approved · Marco Gómez'), findsOneWidget);
      expect(find.text('3 waiting'), findsOneWidget);
      expect(find.text('3'), findsWidgets);

      // Edit punch: open from the photo, nothing changed → "No changes to save."
      await tapShown(find.text('Jaylen Thomas').first); // photo card comes before the crew board
      await tester.pumpAndSettle();
      expect(find.text('Edit punch'), findsOneWidget);
      await tapShown(find.text('Save changes'));
      await tester.pump();
      expect(find.text('No changes to save.'), findsOneWidget);

      // Change the job site without a reason → asks for one; with a reason → Save & approve.
      await tapShown(find.text('Colonial Dr. warehouse').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kissimmee retail').last);
      await tester.pumpAndSettle();
      await tapShown(find.text('Save changes'));
      await tester.pump();
      expect(find.text('Pick a reason for the change.'), findsOneWidget);
      await tapShown(find.text('Wrong job site'));
      await tester.pump();
      await tapShown(find.text('Save & approve'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Edit punch'), findsNothing);
      expect(find.text('Approved · Jaylen Thomas'), findsOneWidget);
      expect(find.text('2 waiting'), findsOneWidget);

      // Search the crew board.
      await tester.ensureVisible(find.widgetWithText(TextField, 'Search employees'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Search employees'), 'kim');
      await tester.pump();
      expect(find.text('Kim Pham'), findsWidgets);
      expect(find.text('Miguel Ruiz'), findsNothing);

      // Hide the data-limit banner.
      await tapShown(find.byTooltip('Hide'));
      await tester.pump();
      expect(find.text('Free plan keeps 90 days of data'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('photo approvals: retake, reject, approve all on site, approve', (tester) async {
      desktop(tester);
      await tester.pumpWidget(const PortalApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'owner@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rivera Electric'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      Future<void> settle() async {
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
      }

      Future<void> tapShown(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
      }

      // A crew-board row with a photo waiting opens that punch here.
      await tapShown(find.text('Luis Báez').last);
      await settle();
      expect(find.text('SUPERVISOR REVIEW'), findsOneWidget);
      expect(find.text('Electrician · Clock in · 7:05 AM'), findsOneWidget);

      // Menu → Photo approvals: first punch selected.
      await tester.tap(find.text('Photo approvals').first);
      await settle();
      expect(find.text('Approve all on site (3)'), findsOneWidget);
      await tapShown(find.text('Marco Gómez').first);
      await tester.pumpAndSettle();
      expect(find.text('Electrician · Clock in · 7:02 AM'), findsOneWidget);
      expect(find.text('Lake Nona — Bldg C'), findsWidgets);
      expect(find.text('Inside · 40 ft'), findsOneWidget);

      // Ask to retake (with a note) → message, next waiting punch is selected.
      await tester.enterText(find.widgetWithText(TextField, 'e.g. Please retake — face not visible'), 'Face not visible');
      await tapShown(find.text('Ask to retake'));
      await settle();
      expect(find.text('Retake requested · Marco Gómez'), findsOneWidget);
      expect(find.text('Retake asked'), findsWidgets);
      expect(find.text('Apprentice · Clock in · 7:16 AM'), findsOneWidget);

      // Reject Jaylen.
      await tapShown(find.text('Reject'));
      await settle();
      expect(find.text('Rejected · Jaylen Thomas'), findsOneWidget);

      // Approve all on site: only Ana is still waiting inside a job site.
      expect(find.text('Approve all on site (1)'), findsOneWidget);
      await tapShown(find.text('Approve all on site (1)'));
      await settle();
      expect(find.text('Approved 1 on site'), findsOneWidget);
      expect(find.text('Approve all on site (0)'), findsOneWidget);

      // Luis (outside the site) still needs a decision → approve → all caught up.
      await tapShown(find.text('Luis Báez').first);
      await tester.pumpAndSettle();
      await tapShown(find.widgetWithText(FilledButton, 'Approve'));
      await settle();
      expect(find.text('Approved · Luis Báez'), findsOneWidget);
      expect(find.text('All caught up — no photos waiting.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('timecards: table, day map, select, add timecard rules, export, approve', (tester) async {
      desktop(tester);
      await tester.pumpWidget(const PortalApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'owner@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rivera Electric'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      Future<void> settle() async {
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
      }

      Future<void> tapShown(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
      }

      await tester.tap(find.text('Timecards').first);
      await settle();
      expect(find.text('PAY PERIOD · WEEKLY'), findsOneWidget);
      expect(find.text('Regular hours'), findsOneWidget);
      expect(find.text('Flagged punches'), findsOneWidget);
      expect(find.textContaining('Federal (FLSA)'), findsOneWidget);
      expect(find.text('David Soto'), findsOneWidget);

      // Select a person → "Timecard PDFs (1)"
      expect(find.text('Timecard PDFs (0)'), findsOneWidget);
      await tapShown(find.descendant(of: find.byKey(const ValueKey('tc-select-u1')), matching: find.byType(InkWell)));
      await tester.pump();
      expect(find.text('Timecard PDFs (1)'), findsOneWidget);

      // Day popup from a day cell
      await tapShown(find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key! as ValueKey).value}'.startsWith('tc-day-')).first);
      await settle();
      expect(find.text('Punches on the map'), findsOneWidget);
      expect(find.text('Day total'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel').first);
      await settle();
      expect(find.text('Punches on the map'), findsNothing);

      // Add timecard: a reason is required
      await tapShown(find.text('+ Add timecard'));
      await settle();
      expect(find.text('Add timecard'), findsOneWidget);
      await tapShown(find.text('Save timecard'));
      await tester.pump();
      expect(find.text('Pick a reason — it goes in the history.'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel').first);
      await settle();

      // Export CSV
      await tapShown(find.text('Export CSV'));
      await settle();
      expect(find.text('CSV downloaded'), findsOneWidget);

      // Send to TM Ledger
      await tapShown(find.text('Send to TM Ledger'));
      await tester.pump();
      expect(find.textContaining('TM Ledger isn'), findsOneWidget);

      // Approve period (asks first when a timecard still needs a fix)
      await tapShown(find.text('Approve period'));
      await settle();
      if (find.text('Some timecards still need a fix').evaluate().isNotEmpty) {
        await tester.tap(find.text('Approve anyway'));
        await settle();
      }
      expect(find.text('Pay period approved'), findsOneWidget);
      expect(find.text('Approved & locked'), findsOneWidget);
      expect(tester.takeException(), isNull);
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

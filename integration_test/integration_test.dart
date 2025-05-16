void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end test: Add class and verify', (tester) async {
    // Launch app
    await tester.pumpWidget(MyApp());

    // Navigate to schedule screen
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();

    // Add new class
    await tester.tap(find.byTooltip('Add Class'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.bySemanticsLabel('Course Code'), 'CSE431');
    await tester.enterText(
      find.bySemanticsLabel('Course Name'),
      'Mobile Programming',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify class appears
    expect(find.text('CSE431'), findsOneWidget);
    expect(find.text('Mobile Programming'), findsOneWidget);
  });
}

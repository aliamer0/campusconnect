void main() {
  testWidgets('HomeScreen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    expect(find.text('Upcoming Events'), findsOneWidget);
    expect(find.text("Today's Schedule"), findsOneWidget);
    expect(find.byType(EventCarousel), findsOneWidget);
  });
}

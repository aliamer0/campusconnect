void main() {
  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService();
      await dbService.open();
    });

    tearDown(() async {
      await dbService.close();
    });

    test('Insert and retrieve class schedule', () async {
      final schedule = ClassSchedule(
        courseCode: 'CSE431',
        courseName: 'Mobile Programming',
        professor: 'Dr. Haytham',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '10:30',
      );

      final id = await dbService.insertClass(schedule);
      expect(id, greaterThan(0));

      final schedules = await dbService.getAllClasses();
      expect(schedules.length, 1);
      expect(schedules[0].courseCode, 'CSE431');
    });
  });
}

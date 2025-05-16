// database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'campus_connect7.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE classes(
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    professor TEXT,
    room TEXT,
    materials TEXT,
    startTime TEXT,
    endTime TEXT,
    weekdays TEXT,
    createdAt TEXT,
    updatedAt TEXT,
    isSynced INTEGER DEFAULT 0,
    firestoreId TEXT,
    userId TEXT
  )
  ''');

    await db.execute('''
  CREATE TABLE events(
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    startTime TEXT,
    endTime TEXT,
    isCampusEvent INTEGER DEFAULT 0,
    createdAt TEXT,
    updatedAt TEXT,
    isSynced INTEGER DEFAULT 0,
    firestoreId TEXT,
    userId TEXT
  )
  ''');

    await db.execute('''
    CREATE TABLE messages(
      id TEXT PRIMARY KEY,
      groupId TEXT,
      text TEXT,
      senderId TEXT,
      senderName TEXT,
      timestamp TEXT,
      isSynced INTEGER DEFAULT 0
    )
  ''');

    await db.execute('''
  CREATE TABLE study_groups(
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    nextMeeting TEXT,
    members TEXT,
    createdAt TEXT,
    updatedAt TEXT,
    isSynced INTEGER DEFAULT 0,
    firestoreId TEXT,
    creatorId TEXT
  )
  ''');

    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // Class operations
  Future<int> insertClass(Map<String, dynamic> classData) async {
    final db = await database;
    return await db.insert('classes', classData);
  }

  Future<List<Map<String, dynamic>>> getClasses() async {
    final db = await database;
    return await db.query('classes');
  }

  Future<int> updateClass(String id, Map<String, dynamic> classData) async {
    final db = await database;
    return await db.update(
      'classes',
      classData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteClass(String id) async {
    final db = await database;
    return await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  // Event operations
  Future<int> insertEvent(Map<String, dynamic> eventData) async {
    final db = await database;
    return await db.insert('events', eventData);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.query('events');
  }

  Future<int> updateEvent(String id, Map<String, dynamic> eventData) async {
    final db = await database;
    return await db.update(
      'events',
      eventData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEvent(String id) async {
    final db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // Study Group operations
  Future<int> insertStudyGroup(Map<String, dynamic> groupData) async {
    final db = await database;
    return await db.insert('study_groups', groupData);
  }

  Future<List<Map<String, dynamic>>> getStudyGroups() async {
    final db = await database;
    return await db.query('study_groups');
  }

  Future<int> updateStudyGroup(
    String id,
    Map<String, dynamic> groupData,
  ) async {
    final db = await database;
    return await db.update(
      'study_groups',
      groupData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteStudyGroup(String id) async {
    final db = await database;
    return await db.delete('study_groups', where: 'id = ?', whereArgs: [id]);
  }

  // Note operations
  Future<int> insertNote(Map<String, dynamic> noteData) async {
    final db = await database;
    return await db.insert('notes', noteData);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return await db.query('notes');
  }

  Future<int> updateNote(String id, Map<String, dynamic> noteData) async {
    final db = await database;
    return await db.update('notes', noteData, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNote(String id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('classes');
    await db.delete('events');
    await db.delete('study_groups');
    await db.delete('notes');
  }

  // Add to DatabaseService class

  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getCampusEvents() async {
    final db = await database;
    final events = await db.query(
      'events',
      where: 'isCampusEvent = ?',
      whereArgs: [1],
    );

    // Convert back to bool for the application
    return events
        .map(
          (event) => {...event, 'isCampusEvent': event['isCampusEvent'] == 1},
        )
        .toList();
  }
}

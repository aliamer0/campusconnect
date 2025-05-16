// event_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'sync_service.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';

class EventService {
  final DatabaseService _localDb = DatabaseService();
  final FirestoreService _firestore = FirestoreService();
  final SyncService _syncService = SyncService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addEvent(Map<String, dynamic> eventData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();

    // Create a copy for local database (convert bool to int)
    final localEventData = {
      ...eventData,
      'userId': userId,
      'createdAt': now,
      'updatedAt': now,
      'isSynced': 0,
      'isCampusEvent':
          eventData['isCampusEvent'] ? 1 : 0, // Convert to int for SQLite
    };

    // Create a copy for Firestore (keep as bool)
    final firestoreEventData = {
      ...eventData,
      'userId': userId,
      'createdAt': now,
      'updatedAt': now,
    };

    // Save locally first
    await _localDb.insertEvent(localEventData);

    // Schedule notification if it's a future event
    if (eventData['startTime'] != null) {
      try {
        final eventTime = DateTime.parse(eventData['startTime']);
        if (eventTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            title: 'Upcoming Event: ${eventData['title']}',
            body: 'Starts at ${DateFormat('MMM d, h:mm a').format(eventTime)}',
            scheduledTime: eventTime.subtract(const Duration(minutes: 30)),
            payload: 'event_${eventData['id']}',
          );
        }
      } catch (e) {
        print('Error scheduling notification: $e');
      }
    }

    // Sync with Firestore
    await _syncService.syncEvents();
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    await _syncService.syncEvents();
    return await _localDb.getEvents();
  }

  Future<List<Map<String, dynamic>>> getCampusEvents() async {
    final allEvents = await _localDb.getEvents();
    return allEvents.where((event) => event['isCampusEvent'] == true).toList();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> eventData) async {
    eventData['updatedAt'] = DateTime.now().toIso8601String();
    eventData['isSynced'] = 0;
    await _localDb.updateEvent(id, eventData);
    await _syncService.syncEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _localDb.deleteEvent(id);
    await _syncService.syncEvents();
  }
}

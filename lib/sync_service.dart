// sync_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'firestore_service.dart';

class SyncService {
  final DatabaseService _localDb = DatabaseService();
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sync all data between local and remote
  Future<void> syncAllData() async {
    if (_auth.currentUser == null) return;

    await syncClasses();
    await syncEvents();
    await syncStudyGroups();
  }

  // Sync classes
  Future<void> syncClasses() async {
    final localClasses = await _localDb.getClasses();
    final remoteClasses = await _firestore.getClassesStream().first;

    // Upload local changes to Firestore
    for (var localClass in localClasses) {
      if (localClass['isSynced'] != true) {
        if (localClass['firestoreId'] == null) {
          // New class - add to Firestore
          final docRef = await _firestore.addClass(localClass);
          await _localDb.updateClass(localClass['id'], {
            ...localClass,
            'firestoreId': docRef.id,
            'isSynced': true,
          });
        } else {
          // Existing class - update in Firestore
          await _firestore.updateClass(localClass['firestoreId'], localClass);
          await _localDb.updateClass(localClass['id'], {
            ...localClass,
            'isSynced': true,
          });
        }
      }
    }

    // Download remote changes to local
    for (var remoteClass in remoteClasses.docs) {
      final data = remoteClass.data() as Map<String, dynamic>;
      final existing = localClasses.firstWhere(
        (element) => element['firestoreId'] == remoteClass.id,
        orElse: () => {},
      );

      if (existing.isEmpty) {
        // New remote class - add to local
        await _localDb.insertClass({
          ...data,
          'firestoreId': remoteClass.id,
          'isSynced': true,
        });
      } else if (data['updatedAt'] > existing['updatedAt']) {
        // Remote is newer - update local
        await _localDb.updateClass(existing['id'], {
          ...data,
          'firestoreId': remoteClass.id,
          'isSynced': true,
        });
      }
    }
  }

  // Sync events
  Future<void> syncEvents() async {
    final localEvents = await _localDb.getEvents();
    final remoteEvents = await _firestore.getEventsStream().first;

    // Upload local changes to Firestore
    for (var localEvent in localEvents) {
      if (localEvent['isSynced'] != true) {
        if (localEvent['firestoreId'] == null) {
          // New event - add to Firestore
          final docRef = await _firestore.addEvent(localEvent);
          await _localDb.updateEvent(localEvent['id'], {
            ...localEvent,
            'firestoreId': docRef.id,
            'isSynced': true,
          });
        } else {
          // Existing event - update in Firestore
          await _firestore.updateEvent(localEvent['firestoreId'], localEvent);
          await _localDb.updateEvent(localEvent['id'], {
            ...localEvent,
            'isSynced': true,
          });
        }
      }
    }

    // Download remote changes to local
    for (var remoteEvent in remoteEvents.docs) {
      final data = remoteEvent.data() as Map<String, dynamic>;
      final existing = localEvents.firstWhere(
        (element) => element['firestoreId'] == remoteEvent.id,
        orElse: () => {},
      );

      if (existing.isEmpty) {
        // New remote event - add to local
        await _localDb.insertEvent({
          ...data,
          'firestoreId': remoteEvent.id,
          'isSynced': true,
        });
      } else if (data['updatedAt'] > existing['updatedAt']) {
        // Remote is newer - update local
        await _localDb.updateEvent(existing['id'], {
          ...data,
          'firestoreId': remoteEvent.id,
          'isSynced': true,
        });
      }
    }
  }

  // Sync study groups
  Future<void> syncStudyGroups() async {
    final localGroups = await _localDb.getStudyGroups();
    final remoteGroups = await _firestore.getStudyGroupsStream().first;

    // Upload local changes to Firestore
    for (var localGroup in localGroups) {
      if (localGroup['isSynced'] != true) {
        if (localGroup['firestoreId'] == null) {
          // New group - add to Firestore
          final docRef = await _firestore.createStudyGroup(localGroup);
          await _localDb.updateStudyGroup(localGroup['id'], {
            ...localGroup,
            'firestoreId': docRef.id,
            'isSynced': true,
          });
        } else {
          // Existing group - update in Firestore
          await _firestore.updateStudyGroup(
            localGroup['firestoreId'],
            localGroup,
          );
          await _localDb.updateStudyGroup(localGroup['id'], {
            ...localGroup,
            'isSynced': true,
          });
        }
      }
    }

    // Download remote changes to local
    for (var remoteGroup in remoteGroups.docs) {
      final data = remoteGroup.data() as Map<String, dynamic>;
      final existing = localGroups.firstWhere(
        (element) => element['firestoreId'] == remoteGroup.id,
        orElse: () => {},
      );

      if (existing.isEmpty) {
        // New remote group - add to local
        await _localDb.insertStudyGroup({
          ...data,
          'firestoreId': remoteGroup.id,
          'isSynced': true,
        });
      } else if (data['updatedAt'] > existing['updatedAt']) {
        // Remote is newer - update local
        await _localDb.updateStudyGroup(existing['id'], {
          ...data,
          'firestoreId': remoteGroup.id,
          'isSynced': true,
        });
      }
    }
  }
}

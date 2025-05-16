import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'dart:convert';

class SyncService {
  final DatabaseService _localDb = DatabaseService();
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> syncAllData() async {
    if (_auth.currentUser == null) return;

    try {
      await syncClasses();
      await syncEvents();
      await syncStudyGroups();
    } catch (e) {
      print('Error syncing all data: $e');
      rethrow;
    }
  }

  Future<void> syncClasses() async {
    try {
      final localClasses = await _localDb.getClasses();
      final remoteClasses = await _firestore.getClassesStream().first;

      // Upload local changes to Firestore
      for (var localClass in localClasses) {
        if (localClass['isSynced'] != 1) {
          final classData = _prepareClassData(localClass);
          if (localClass['firestoreId'] == null) {
            final docRef = await _firestore.addClass(classData);
            await _localDb.updateClass(localClass['id'], {
              ...classData,
              'firestoreId': docRef.id,
              'isSynced': 1,
            });
          } else {
            await _firestore.updateClass(localClass['firestoreId'], classData);
            await _localDb.updateClass(localClass['id'], {
              ...classData,
              'isSynced': 1,
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
          await _localDb.insertClass({
            ..._prepareClassData(data),
            'firestoreId': remoteClass.id,
            'isSynced': 1,
          });
        } else {
          final localUpdated = existing['updatedAt'] ?? '';
          final remoteUpdated = data['updatedAt'] ?? '';
          if (remoteUpdated.compareTo(localUpdated) > 0) {
            await _localDb.updateClass(existing['id'], {
              ..._prepareClassData(data),
              'firestoreId': remoteClass.id,
              'isSynced': 1,
            });
          }
        }
      }
    } catch (e) {
      print('Error syncing classes: $e');
      rethrow;
    }
  }

  Future<void> syncEvents() async {
    try {
      final localEvents = await _localDb.getEvents();
      final remoteEvents = await _firestore.getEventsStream().first;

      // Upload local changes to Firestore
      for (var localEvent in localEvents) {
        if (localEvent['isSynced'] != 1) {
          final eventData = _prepareEventData(localEvent);
          if (localEvent['firestoreId'] == null) {
            final docRef = await _firestore.addEvent(eventData);
            await _localDb.updateEvent(localEvent['id'], {
              ...eventData,
              'firestoreId': docRef.id,
              'isSynced': 1,
            });
          } else {
            await _firestore.updateEvent(localEvent['firestoreId'], eventData);
            await _localDb.updateEvent(localEvent['id'], {
              ...eventData,
              'isSynced': 1,
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
          await _localDb.insertEvent({
            ..._prepareEventData(data),
            'firestoreId': remoteEvent.id,
            'isSynced': 1,
          });
        } else {
          final localUpdated = existing['updatedAt'] ?? '';
          final remoteUpdated = data['updatedAt'] ?? '';
          if (remoteUpdated.compareTo(localUpdated) > 0) {
            await _localDb.updateEvent(existing['id'], {
              ..._prepareEventData(data),
              'firestoreId': remoteEvent.id,
              'isSynced': 1,
            });
          }
        }
      }
    } catch (e) {
      print('Error syncing events: $e');
      rethrow;
    }
  }

  Future<void> syncStudyGroups() async {
    try {
      final localGroups = await _localDb.getStudyGroups();
      final remoteGroups = await _firestore.getStudyGroupsStream().first;

      // Upload local changes to Firestore
      for (var localGroup in localGroups) {
        if (localGroup['isSynced'] != 1) {
          final groupData = _prepareGroupData(localGroup);
          if (localGroup['firestoreId'] == null) {
            final docRef = await _firestore.createStudyGroup(groupData);
            await _localDb.updateStudyGroup(localGroup['id'], {
              ...groupData,
              'firestoreId': docRef.id,
              'isSynced': 1,
            });
          } else {
            await _firestore.updateStudyGroup(
              localGroup['firestoreId'],
              groupData,
            );
            await _localDb.updateStudyGroup(localGroup['id'], {
              ...groupData,
              'isSynced': 1,
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
          await _localDb.insertStudyGroup({
            ..._prepareGroupData(data),
            'firestoreId': remoteGroup.id,
            'isSynced': 1,
          });
        } else {
          final localUpdated = existing['updatedAt'] ?? '';
          final remoteUpdated = data['updatedAt'] ?? '';
          if (remoteUpdated.compareTo(localUpdated) > 0) {
            await _localDb.updateStudyGroup(existing['id'], {
              ..._prepareGroupData(data),
              'firestoreId': remoteGroup.id,
              'isSynced': 1,
            });
          }
        }
      }
    } catch (e) {
      print('Error syncing study groups: $e');
      rethrow;
    }
  }

  // Helper methods to ensure data consistency
  Map<String, dynamic> _prepareClassData(Map<String, dynamic> data) {
    return {
      'name': data['name'] ?? '',
      'professor': data['professor'] ?? '',
      'room': data['room'] ?? '',
      'startTime': data['startTime'] ?? '',
      'endTime': data['endTime'] ?? '',
      'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _prepareEventData(Map<String, dynamic> data) {
    // Convert all possible null values to empty strings
    String safeString(dynamic value) => value?.toString() ?? '';

    // Handle isCampusEvent carefully
    bool isCampusEvent;
    if (data['isCampusEvent'] == null) {
      isCampusEvent = false;
    } else if (data['isCampusEvent'] is bool) {
      isCampusEvent = data['isCampusEvent'];
    } else {
      isCampusEvent = data['isCampusEvent'] == 1;
    }

    return {
      'title': safeString(data['title']),
      'description': safeString(data['description']),
      'location': safeString(data['location']),
      'startTime': safeString(data['startTime']),
      'endTime': safeString(data['endTime']),
      'isCampusEvent': isCampusEvent,
      'userId': safeString(data['userId']),
      'createdAt':
          safeString(data['createdAt']) ?? DateTime.now().toIso8601String(),
      'updatedAt':
          safeString(data['updatedAt']) ?? DateTime.now().toIso8601String(),
    };
  }

  // Update _prepareGroupData to handle members
  //
  Map<String, dynamic> _prepareGroupData(Map<String, dynamic> data) {
    // Handle members - ensure it's always a JSON string for SQLite
    dynamic members = data['members'];
    String membersJson;
    if (members is String) {
      membersJson = members; // Already JSON string
    } else if (members is List) {
      membersJson = jsonEncode(members); // Convert list to JSON string
    } else {
      membersJson = '[]'; // Default empty array
    }

    // Handle isSynced - ensure it's always an integer
    int isSynced;
    if (data['isSynced'] is int) {
      isSynced = data['isSynced'];
    } else if (data['isSynced'] is String) {
      isSynced = int.tryParse(data['isSynced']) ?? 0;
    } else {
      isSynced = 0;
    }

    return {
      'name': data['name'] ?? '',
      'description': data['description'] ?? '',
      'members': membersJson, // Store as JSON string
      'nextMeeting': data['nextMeeting'] ?? '',
      'creatorId': data['creatorId'] ?? '',
      'updatedAt': data['updatedAt'] ?? DateTime.now().toIso8601String(),
      'isSynced': isSynced,
    };
  }
}

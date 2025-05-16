// study_group_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'sync_service.dart';
import 'notification_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class StudyGroupService {
  final DatabaseService _localDb = DatabaseService();
  final FirestoreService _firestore = FirestoreService();
  final SyncService _syncService = SyncService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = Uuid();

  // study_group_service.dart - Improved group management
  Future<void> createStudyGroup(Map<String, dynamic> groupData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    final completeGroupData = {
      ...groupData,
      'creatorId': userId,
      'members': jsonEncode([userId]), // Store members as JSON string
      'createdAt': now,
      'updatedAt': now,
      'isSynced': 0, // Explicit integer
      'id': id,
      'name': groupData['name'] ?? '',
      'description': groupData['description'] ?? '',
      'nextMeeting': groupData['nextMeeting'] ?? '',
    };

    await _localDb.insertStudyGroup(completeGroupData);
    await _syncService.syncStudyGroups();
  }

  Future<List<Map<String, dynamic>>> getStudyGroups() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    await _syncService.syncStudyGroups();
    final allGroups = await _localDb.getStudyGroups();

    // Filter groups where user is a member
    return allGroups.where((group) {
      final members = List<String>.from(jsonDecode(group['members'] ?? '[]'));
      return members.contains(userId);
    }).toList();
  }

  Future<void> updateStudyGroup(
    String id,
    Map<String, dynamic> groupData,
  ) async {
    groupData['updatedAt'] = DateTime.now().toIso8601String();
    groupData['isSynced'] = 0;
    await _localDb.updateStudyGroup(id, groupData);
    await _syncService.syncStudyGroups();
  }

  Future<void> joinStudyGroup(String groupId) async {
    final groups = await _localDb.getStudyGroups();
    final group = groups.firstWhere((g) => g['id'] == groupId);

    List<String> members = [];
    if (group['members'] != null) {
      members = List<String>.from(jsonDecode(group['members']));
    }

    if (!members.contains(_auth.currentUser?.uid)) {
      members.add(_auth.currentUser!.uid);
      group['members'] = jsonEncode(members);
      await updateStudyGroup(groupId, group);

      if (group['nextMeeting'] != null) {
        final meetingTime = DateTime.parse(group['nextMeeting']);
        if (meetingTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            title: 'Study Group Meeting: ${group['name']}',
            body: 'Starts at ${group['nextMeeting']}',
            scheduledTime: meetingTime.subtract(const Duration(minutes: 30)),
            payload: 'study_group_reminder',
          );
        }
      }
    }
  }

  Future<void> leaveStudyGroup(String groupId) async {
    final groups = await _localDb.getStudyGroups();
    final group = groups.firstWhere((g) => g['id'] == groupId);

    List<String> members = [];
    if (group['members'] != null) {
      members = List<String>.from(jsonDecode(group['members']));
    }

    if (members.contains(_auth.currentUser?.uid)) {
      members.remove(_auth.currentUser!.uid);
      group['members'] = jsonEncode(members);
      await updateStudyGroup(groupId, group);
    }
  }
}

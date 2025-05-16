// firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Collection
  CollectionReference get _users => _firestore.collection('users');

  // Classes Collection
  CollectionReference get _classes => _firestore.collection('classes');

  // Events Collection
  CollectionReference get _events => _firestore.collection('events');

  // Study Groups Collection
  CollectionReference get _studyGroups => _firestore.collection('study_groups');

  // Announcements Collection
  CollectionReference get _announcements =>
      _firestore.collection('announcements');

  // Create or update user profile
  Future<void> updateUserData(String uid, Map<String, dynamic> userData) async {
    return await _users.doc(uid).set(userData, SetOptions(merge: true));
  }

  // Get user data
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _users.doc(uid).get();
  }

  // Classes operations
  Future<DocumentReference> addClass(Map<String, dynamic> classData) async {
    return await _classes.add(classData);
  }

  Stream<QuerySnapshot> getClassesStream() {
    return _classes
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots();
  }

  Future<void> updateClass(
    String classId,
    Map<String, dynamic> classData,
  ) async {
    return await _classes.doc(classId).update(classData);
  }

  Future<void> deleteClass(String classId) async {
    return await _classes.doc(classId).delete();
  }

  // Events operations
  Future<DocumentReference> addEvent(Map<String, dynamic> eventData) async {
    return await _events.add(eventData);
  }

  Stream<QuerySnapshot> getEventsStream() {
    return _events
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots();
  }

  Stream<QuerySnapshot> getCampusEventsStream() {
    return _events.where('isCampusEvent', isEqualTo: true).snapshots();
  }

  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    return await _events.doc(eventId).update(eventData);
  }

  Future<void> deleteEvent(String eventId) async {
    return await _events.doc(eventId).delete();
  }

  // Study Group operations
  Future<DocumentReference> createStudyGroup(
    Map<String, dynamic> groupData,
  ) async {
    return await _studyGroups.add(groupData);
  }

  Stream<QuerySnapshot> getStudyGroupsStream() {
    return _studyGroups
        .where('members', arrayContains: _auth.currentUser?.uid)
        .snapshots();
  }

  Future<void> updateStudyGroup(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    return await _studyGroups.doc(groupId).update(groupData);
  }

  Future<void> joinStudyGroup(String groupId, String userId) async {
    return await _studyGroups.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveStudyGroup(String groupId, String userId) async {
    return await _studyGroups.doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  // Announcements
  Stream<QuerySnapshot> getAnnouncementsStream() {
    return _announcements.orderBy('timestamp', descending: true).snapshots();
  }
}

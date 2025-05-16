import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'event_service.dart';
import 'study_group_service.dart';
import 'notification_service.dart';
import 'class_schedule_screen.dart';
import 'study_group_screen.dart';
import 'campus_event_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _eventService = EventService();
  final StudyGroupService _studyGroupService = StudyGroupService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  int _currentIndex = 0;
  late Future<List<Map<String, dynamic>>> _upcomingEvents;
  late Future<List<Map<String, dynamic>>> _upcomingClasses;
  late Future<List<Map<String, dynamic>>> _studyGroups;
  late Future<List<Map<String, dynamic>>> _campusEvents;

  @override
  void initState() {
    super.initState();
    _loadData();
    _notificationService.initialize();
  }

  void _loadData() {
    _upcomingEvents = _eventService.getEvents();
    _upcomingClasses = _databaseService.getClasses();
    _studyGroups = _studyGroupService.getStudyGroups();
    _campusEvents = _eventService.getCampusEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusConnect'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Classes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Study Groups',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        ],
      ),
      floatingActionButton:
          _currentIndex == 2
              ? FloatingActionButton(
                onPressed: _createNewStudyGroup,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return ClassScheduleScreen();
      case 2:
        return StudyGroupSectionScreen();
      case 3:
        return CampusEventScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Classes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUpcomingClasses(),
            const SizedBox(height: 24),
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUpcomingEvents(),
            const SizedBox(height: 24),
            const Text(
              'Your Study Groups',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStudyGroups(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _upcomingClasses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming classes'),
            ),
          );
        }

        final classes = snapshot.data!.take(3).toList();
        return Column(
          children:
              classes.map((classData) => _buildClassCard(classData)).toList(),
        );
      },
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.school, size: 36),
        title: Text(classData['name'] ?? 'No class name'),
        subtitle: Text(
          '${classData['professor'] ?? 'Professor'} - ${classData['room'] ?? 'Room'}',
        ),
        trailing: Text(
          _formatClassTime(classData['startTime'], classData['endTime']),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClassScheduleScreen()),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _upcomingEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming events'),
            ),
          );
        }

        final events = snapshot.data!.take(3).toList();
        return Column(
          children: events.map((event) => _buildEventCard(event)).toList(),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.event, size: 36),
        title: Text(event['title'] ?? 'No event title'),
        subtitle: Text(event['location'] ?? 'No location'),
        trailing: Text(_formatDateTime(event['startTime'])),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CampusEventScreen()),
          );
        },
      ),
    );
  }

  Widget _buildStudyGroups() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _studyGroups,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No study groups'),
            ),
          );
        }

        final groups = snapshot.data!.take(3).toList();
        return Column(
          children: groups.map((group) => _buildStudyGroupCard(group)).toList(),
        );
      },
    );
  }

  Widget _buildStudyGroupCard(Map<String, dynamic> group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.group, size: 36),
        title: Text(group['name'] ?? 'No group name'),
        subtitle: Text(group['description'] ?? 'No description'),
        trailing: Text(
          group['nextMeeting'] != null
              ? _formatDateTime(group['nextMeeting'])
              : 'No meeting',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudyGroupSectionScreen()),
          );
        },
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'No date';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatClassTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return '';
    try {
      final start = DateFormat('hh:mm a').format(DateTime.parse(startTime));
      final end = DateFormat('hh:mm a').format(DateTime.parse(endTime));
      return '$start - $end';
    } catch (e) {
      return '';
    }
  }

  void _createNewStudyGroup() {
    showDialog(
      context: context,
      builder: (context) {
        String groupName = '';
        String description = '';
        return AlertDialog(
          title: const Text('Create New Study Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Group Name'),
                onChanged: (value) => groupName = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupName.isNotEmpty) {
                  await _studyGroupService.createStudyGroup({
                    'name': groupName,
                    'description': description,
                    'createdAt': DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
                    'members': [_authService.getCurrentUser()?.uid],
                  });
                  setState(() {
                    _loadData();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

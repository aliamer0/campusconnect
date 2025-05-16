import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';
import 'add_class_screen.dart';

class ClassScheduleScreen extends StatefulWidget {
  const ClassScheduleScreen({super.key});

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  late Future<List<Map<String, dynamic>>> _classes;
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classes = _databaseService.getClasses();
    });
    _syncService.syncClasses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Schedule'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadClasses),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _classes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No classes found'));
          }

          final classes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index];
              return _buildClassCard(classData);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClassScreen()),
          );
          _loadClasses();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  classData['name'] ?? 'No class name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteClass(classData['id']?.toString()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildClassDetailRow(
              Icons.person,
              classData['professor'] ?? 'Professor not specified',
            ),
            _buildClassDetailRow(
              Icons.room,
              classData['room'] ?? 'Room not specified',
            ),
            _buildClassDetailRow(Icons.schedule, _formatClassTime(classData)),
            if (classData['materials'] != null &&
                (classData['materials'] as String).isNotEmpty)
              _buildClassDetailRow(
                Icons.book,
                classData['materials'] as String,
              ),
            const SizedBox(height: 8),
            Text(
              'Days: ${_formatWeekdays(classData['weekdays'])}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatClassTime(Map<String, dynamic> classData) {
    try {
      final startTime = DateTime.parse(classData['startTime']);
      final endTime = DateTime.parse(classData['endTime']);
      return '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
    } catch (e) {
      return 'Time not specified';
    }
  }

  String _formatWeekdays(String? weekdays) {
    if (weekdays == null || weekdays.isEmpty) return 'Not specified';
    return weekdays.split(',').join(', ');
  }

  Future<void> _deleteClass(String? id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete class: missing ID')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Class'),
            content: const Text('Are you sure you want to delete this class?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteClass(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class deleted successfully')),
          );
          _loadClasses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete class: $e')));
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'study_group_service.dart';
import 'database_service.dart';
import 'sync_service.dart';

class AddStudyGroupScreen extends StatefulWidget {
  const AddStudyGroupScreen({super.key});

  @override
  State<AddStudyGroupScreen> createState() => _AddStudyGroupScreenState();
}

class _AddStudyGroupScreenState extends State<AddStudyGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final StudyGroupService _studyGroupService = StudyGroupService();
  final SyncService _syncService = SyncService();

  DateTime? _nextMeetingDate;
  TimeOfDay? _nextMeetingTime;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _nextMeetingDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _nextMeetingTime = pickedTime;
      });
    }
  }

  String _formatDateTime() {
    if (_nextMeetingDate == null || _nextMeetingTime == null) {
      return 'Not scheduled';
    }
    final dt = DateTime(
      _nextMeetingDate!.year,
      _nextMeetingDate!.month,
      _nextMeetingDate!.day,
      _nextMeetingTime!.hour,
      _nextMeetingTime!.minute,
    );
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Future<void> _createStudyGroup() async {
    if (_formKey.currentState!.validate()) {
      final groupData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'members': [], // Will be added when creator joins
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': false,
      };

      if (_nextMeetingDate != null && _nextMeetingTime != null) {
        groupData['nextMeeting'] =
            DateTime(
              _nextMeetingDate!.year,
              _nextMeetingDate!.month,
              _nextMeetingDate!.day,
              _nextMeetingTime!.hour,
              _nextMeetingTime!.minute,
            ).toIso8601String();
      }

      try {
        await _studyGroupService.createStudyGroup(groupData);
        await _syncService.syncStudyGroups();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Study Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Next Meeting (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _nextMeetingDate == null
                            ? 'Select date'
                            : DateFormat('MMM d, y').format(_nextMeetingDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _nextMeetingTime == null
                            ? 'Select time'
                            : _nextMeetingTime!.format(context),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              if (_nextMeetingDate != null && _nextMeetingTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Scheduled: ${_formatDateTime()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _createStudyGroup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

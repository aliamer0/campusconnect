import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'sync_service.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professorController = TextEditingController();
  final _roomController = TextEditingController();
  final _materialsController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<bool> _weekdays = List.filled(7, false);
  final List<String> _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _professorController.dispose();
    _roomController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not selected';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String _getSelectedWeekdays() {
    final selectedDays = <String>[];
    for (int i = 0; i < _weekdays.length; i++) {
      if (_weekdays[i]) {
        selectedDays.add(_weekdayNames[i]);
      }
    }
    return selectedDays.join(',');
  }

  Future<void> _saveClass() async {
    if (_formKey.currentState!.validate() &&
        _startTime != null &&
        _endTime != null) {
      final now = DateTime.now();
      final startDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      final classData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Add unique ID
        'name': _nameController.text,
        'professor': _professorController.text,
        'room': _roomController.text,
        'materials': _materialsController.text,
        'startTime': startDateTime.toIso8601String(),
        'endTime': endDateTime.toIso8601String(),
        'weekdays': _getSelectedWeekdays(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isSynced': false,
      };

      try {
        await _databaseService.insertClass(classData);
        await _syncService.syncClasses();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save class: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Class')),
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
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter class name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _professorController,
                decoration: const InputDecoration(
                  labelText: 'Professor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(
                  labelText: 'Materials/Books',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Start Time: ${_formatTime(_startTime)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('End Time: ${_formatTime(_endTime)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Class Days:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: List.generate(7, (index) {
                  return FilterChip(
                    label: Text(_weekdayNames[index]),
                    selected: _weekdays[index],
                    onSelected: (selected) {
                      setState(() {
                        _weekdays[index] = selected;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveClass,
                  child: const Text('Save Class'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

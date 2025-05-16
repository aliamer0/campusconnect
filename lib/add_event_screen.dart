import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_service.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final EventService _eventService = EventService();
  var _auth = FirebaseAuth.instance;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isCampusEvent = true;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'Not selected';
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return DateFormat('MMM d, y h:mm a').format(dt);
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _startTime != null &&
        _endDate != null &&
        _endTime != null) {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      final eventData = {
        'title': _titleController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'startTime': startDateTime.toIso8601String(),
        'endTime': endDateTime.toIso8601String(),
        'isCampusEvent': _isCampusEvent,
        'userId': _auth.currentUser?.uid ?? '', // Never null
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      try {
        await _eventService.addEvent(eventData);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save event: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
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
              SwitchListTile(
                title: const Text('Campus Event'),
                value: _isCampusEvent,
                onChanged: (value) {
                  setState(() {
                    _isCampusEvent = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Start Date & Time:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _startDate == null
                            ? 'Select date'
                            : DateFormat('MMM d, y').format(_startDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _startTime == null
                            ? 'Select time'
                            : _startTime!.format(context),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('End Date & Time:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _endDate == null
                            ? 'Select date'
                            : DateFormat('MMM d, y').format(_endDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _endTime == null
                            ? 'Select time'
                            : _endTime!.format(context),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Save Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'sync_service.dart';
import 'event_service.dart';
import 'add_event_screen.dart';

class CampusEventScreen extends StatefulWidget {
  const CampusEventScreen({super.key});

  @override
  State<CampusEventScreen> createState() => _CampusEventScreenState();
}

class _CampusEventScreenState extends State<CampusEventScreen> {
  late Future<List<Map<String, dynamic>>> _events;
  final EventService _eventService = EventService();
  final SyncService _syncService = SyncService();
  bool _showCampusOnly = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _events =
          _showCampusOnly
              ? _eventService.getCampusEvents()
              : _eventService.getEvents();
    });
    _syncService.syncEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
          Switch(
            value: _showCampusOnly,
            onChanged: (value) {
              setState(() {
                _showCampusOnly = value;
                _loadEvents();
              });
            },
            activeColor: Colors.white,
            inactiveThumbColor: Colors.grey[300],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                _showCampusOnly ? 'Campus' : 'All',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _events,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _showCampusOnly
                        ? 'No campus events scheduled'
                        : 'No events scheduled',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
          _loadEvents();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isCampusEvent = event['isCampusEvent'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCampusEvent ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      event['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCampusEvent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Campus',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildEventDetailRow(
                Icons.location_on,
                event['location'] ?? 'Location not specified',
              ),
              _buildEventDetailRow(
                Icons.calendar_today,
                _formatEventDate(event['startTime']),
              ),
              _buildEventDetailRow(Icons.access_time, _formatEventTime(event)),
              if (event['description'] != null &&
                  event['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    event['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatEventDate(String? dateTime) {
    if (dateTime == null) return 'Date not specified';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('EEE, MMM d, y').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatEventTime(Map<String, dynamic> event) {
    try {
      final start = DateTime.parse(event['startTime']);
      final end = DateTime.parse(event['endTime']);
      return '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';
    } catch (e) {
      return 'Time not specified';
    }
  }

  Future<void> _showEventDetails(Map<String, dynamic> event) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                event['title'] ?? 'No title',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Location:',
                event['location'] ?? 'Not specified',
              ),
              _buildDetailRow('Date:', _formatEventDate(event['startTime'])),
              _buildDetailRow('Time:', _formatEventTime(event)),
              if (event['isCampusEvent'] == true)
                _buildDetailRow('Type:', 'Campus Event'),
              const SizedBox(height: 16),
              if (event['description'] != null &&
                  event['description'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(event['description']),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class StudyGroupChatScreen extends StatefulWidget {
  final String groupId;

  const StudyGroupChatScreen({super.key, required this.groupId});

  @override
  State<StudyGroupChatScreen> createState() => _StudyGroupChatScreenState();
}

class _StudyGroupChatScreenState extends State<StudyGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();

  late CollectionReference _messagesCollection;
  late DocumentReference _groupReference;
  Map<String, dynamic>? _groupData;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _messagesCollection = FirebaseFirestore.instance
        .collection('study_groups')
        .doc(widget.groupId)
        .collection('messages');

    _groupReference = FirebaseFirestore.instance
        .collection('study_groups')
        .doc(widget.groupId);

    _loadGroupData();
    _loadLocalMessages();
  }

  Future<void> _loadGroupData() async {
    final groupSnapshot = await _groupReference.get();
    if (groupSnapshot.exists) {
      setState(() {
        _groupData = groupSnapshot.data() as Map<String, dynamic>;
        _members = List<Map<String, dynamic>>.from(
          _groupData?['members'] ?? [],
        );
      });
    }
  }

  Future<void> _loadLocalMessages() async {
    // Implement local message loading if needed
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = _authService.getCurrentUser();
    if (user == null) return;

    final message = {
      'text': _messageController.text,
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'isSynced': true,
    };

    try {
      // Add to Firestore
      await _messagesCollection.add(message);

      // Update last activity in group
      await _groupReference.update({
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Send notifications to other members
      await _sendNotifications(
        message['text']?.toString() ?? '',
        message['senderName']?.toString() ?? 'Anonymous',
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      // If online fails, save to local database
      await _databaseService.insertMessage({
        ...message,
        'groupId': widget.groupId,
        'timestamp': DateTime.now().toIso8601String(),
        'isSynced': false,
      });
    }
  }

  Future<void> _sendNotifications(String message, String senderName) async {
    if (_members.isEmpty) return;

    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return;

    for (final member in _members) {
      if (member['userId'] != currentUserId) {
        await _notificationService.scheduleNotification(
          title: 'New message in ${_groupData?['name']}',
          body: '$senderName: $message',
          scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
          payload: 'group_chat_${widget.groupId}',
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _scheduleMeeting() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final meetingTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      await _groupReference.update({
        'nextMeeting': meetingTime.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify members
      for (final member in _members) {
        await _notificationService.scheduleNotification(
          title: 'New meeting scheduled for ${_groupData?['name']}',
          body: DateFormat('MMM d, h:mm a').format(meetingTime),
          scheduledTime: meetingTime.subtract(const Duration(hours: 1)),
          payload: 'group_meeting_${widget.groupId}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule meeting: $e')),
        );
      }
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _authService.getCurrentUser()?.uid;
    final timestamp =
        data['timestamp'] is Timestamp
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.parse(data['timestamp']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                data['senderName'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['text']),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_groupData?['name'] ?? 'Study Group'),
            if (_groupData?['nextMeeting'] != null)
              Text(
                'Next: ${DateFormat('MMM d, h:mm a').format(DateTime.parse(_groupData?['nextMeeting']))}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: _scheduleMeeting,
            tooltip: 'Schedule Meeting',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _messagesCollection
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

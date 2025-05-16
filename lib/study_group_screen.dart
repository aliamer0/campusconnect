import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'study_group_service.dart';
import 'sync_service.dart';
import 'add_study_group_screen.dart';
import 'study_group_chat_screen.dart';
import 'dart:convert';

class StudyGroupSectionScreen extends StatefulWidget {
  const StudyGroupSectionScreen({super.key});

  @override
  State<StudyGroupSectionScreen> createState() =>
      _StudyGroupSectionScreenState();
}

class _StudyGroupSectionScreenState extends State<StudyGroupSectionScreen> {
  final StudyGroupService _studyGroupService = StudyGroupService();
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();

  late Future<List<Map<String, dynamic>>> _studyGroups;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStudyGroups();
  }

  void _loadStudyGroups() {
    setState(() {
      _studyGroups = _studyGroupService.getStudyGroups();
    });
    _syncService.syncStudyGroups();
  }

  List<Map<String, dynamic>> _filterGroups(List<Map<String, dynamic>> groups) {
    var filtered =
        groups.where((group) {
          // Parse members from JSON string
          List<String> members = [];
          try {
            members = List<String>.from(jsonDecode(group['members'] ?? '[]'));
          } catch (e) {
            members = [];
          }

          final matchesSearch =
              group['name'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              group['description'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          if (_selectedFilter == 'My Groups') {
            return matchesSearch &&
                members.contains(_authService.getCurrentUser()?.uid);
          }
          return matchesSearch;
        }).toList();

    // Sort by upcoming meetings
    filtered.sort((a, b) {
      if (a['nextMeeting'] == null) return 1;
      if (b['nextMeeting'] == null) return -1;
      return a['nextMeeting'].compareTo(b['nextMeeting']);
    });

    return filtered;
  }

  Future<void> _joinOrLeaveGroup(Map<String, dynamic> group) async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    // Parse members from JSON string
    List<String> members = [];
    try {
      members = List<String>.from(jsonDecode(group['members'] ?? '[]'));
    } catch (e) {
      members = [];
    }

    final isMember = members.contains(userId);

    try {
      if (isMember) {
        await _studyGroupService.leaveStudyGroup(group['id']);
      } else {
        await _studyGroupService.joinStudyGroup(group['id']);
      }
      _loadStudyGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update group: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudyGroups,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search groups',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['All', 'My Groups'].map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _studyGroups,
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
                        const Icon(Icons.group, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No study groups found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AddStudyGroupScreen(),
                              ),
                            );
                          },
                          child: const Text('Create your first group'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredGroups = _filterGroups(snapshot.data!);
                if (filteredGroups.isEmpty) {
                  return Center(
                    child: Text(
                      'No groups match your search for "$_searchQuery"',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    return _buildStudyGroupCard(group);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddStudyGroupScreen(),
            ),
          );
          _loadStudyGroups();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStudyGroupCard(Map<String, dynamic> group) {
    final userId = _authService.getCurrentUser()?.uid;

    List<String> members = [];
    try {
      members = List<String>.from(jsonDecode(group['members'] ?? '[]'));
    } catch (e) {
      members = [];
    }

    final isMember = userId != null && members.contains(userId);
    final memberCount = members.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isMember) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => StudyGroupChatScreen(groupId: group['id']),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      '$memberCount member${memberCount != 1 ? 's' : ''}',
                    ),
                    backgroundColor: Colors.blue[50],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (group['description'] != null &&
                  group['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(group['description']),
                ),
              if (group['nextMeeting'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Next: ${_formatDateTime(group['nextMeeting'])}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _joinOrLeaveGroup(group),
                    child: Text(
                      isMember ? 'Leave Group' : 'Join Group',
                      style: TextStyle(
                        color: isMember ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  if (isMember)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => StudyGroupChatScreen(
                                    groupId: group['id'],
                                  ),
                            ),
                          );
                        },
                        child: const Text('Open Chat'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'No date';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (e) {
      return 'Invalid date';
    }
  }
}

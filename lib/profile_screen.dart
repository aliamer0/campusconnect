import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'settings_screen.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _currentUser = _authService.getCurrentUser();

    if (_currentUser != null) {
      final userData = await _firestoreService.getUserData(_currentUser!.uid);
      setState(
        () => _userData = (userData.data() as Map<String, dynamic>?) ?? {},
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      child:
                          _currentUser?.photoURL != null
                              ? ClipOval(
                                child: Image.network(
                                  _currentUser!.photoURL!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue[800],
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userData['name'] ??
                          _currentUser?.displayName ??
                          'No name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser?.email ?? 'No email',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileSection('Personal Information', [
                      _buildProfileItem(
                        Icons.school,
                        'University',
                        _userData['university'] ?? 'Not specified',
                      ),
                      _buildProfileItem(
                        Icons.assignment_ind,
                        'Student ID',
                        _userData['studentId'] ?? 'Not specified',
                      ),
                      _buildProfileItem(
                        Icons.phone,
                        'Phone',
                        _userData['phone'] ?? 'Not specified',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildProfileSection('Account Settings', [
                      _buildProfileItem(
                        Icons.notifications,
                        'Notification Preferences',
                        'Manage',
                      ),
                      _buildProfileItem(
                        Icons.schedule,
                        'Calendar Sync',
                        'Configure',
                      ),
                      _buildProfileItem(
                        Icons.security,
                        'Privacy Settings',
                        'Manage',
                      ),
                    ]),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ...items.expand(
                (item) => [item, const Divider(height: 1, thickness: 1)],
              ),
            ]..removeLast(), // Remove last divider
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      trailing: Text(value, style: TextStyle(color: Colors.grey[600])),
      onTap: () {
        // Handle tap for editable fields
        if (label == 'University' ||
            label == 'Student ID' ||
            label == 'Phone') {
          _showEditDialog(label, value);
        }
      },
    );
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit $field'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Enter your $field'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await _updateUserField(field, controller.text);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateUserField(String field, String value) async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.updateUserData(_currentUser!.uid, {field: value});
      await _loadUserData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update $field: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _syncEnabled = true;
  String _syncFrequency = '15 minutes';
  final List<String> _syncOptions = [
    '15 minutes',
    '30 minutes',
    '1 hour',
    'Manual only',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In a real app, you would load these from shared preferences or Firestore
    setState(() {
      _notificationsEnabled = true;
      _darkModeEnabled = false;
      _syncEnabled = true;
    });
  }

  Future<void> _saveSettings() async {
    // Save settings to Firestore or local storage
    try {
      // Example: Save notification preference
      await _notificationService
          .initialize(); // Re-initialize with new settings

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    }
  }

  Future<void> _confirmClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: const Text(
              'This will remove all locally stored data. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _clearCache();
    }
  }

  Future<void> _clearCache() async {
    try {
      final databaseService = DatabaseService();
      await databaseService
          .clearDatabase(); // Implement this method in DatabaseService

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkModeEnabled,
            onChanged: (value) => setState(() => _darkModeEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts for classes and events'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          ListTile(
            title: const Text('Notification Sound'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNotificationSoundOptions(),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Data & Sync'),
          SwitchListTile(
            title: const Text('Enable Auto-Sync'),
            subtitle: const Text('Sync data automatically in background'),
            value: _syncEnabled,
            onChanged: (value) => setState(() => _syncEnabled = value),
          ),
          ListTile(
            title: const Text('Sync Frequency'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(_syncFrequency), const Icon(Icons.chevron_right)],
            ),
            onTap: () => _showSyncFrequencyOptions(),
          ),
          ListTile(
            title: const Text('Manual Sync Now'),
            trailing: const Icon(Icons.sync),
            onTap: () async {
              await _syncService.syncAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data synced successfully')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          ListTile(
            title: const Text('Manage Connected Accounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _manageConnectedAccounts,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Advanced'),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _confirmClearCache,
          ),
          ListTile(
            title: const Text('About CampusConnect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future<void> _showNotificationSoundOptions() async {
    final options = ['Default', 'Chime', 'Bell', 'None'];
    await showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Notification Sound'),
            children:
                options
                    .map(
                      (option) => RadioListTile(
                        title: Text(option),
                        value: option,
                        groupValue:
                            'Default', // You would get this from saved settings
                        onChanged: (value) {
                          // Save the selected option
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  Future<void> _showSyncFrequencyOptions() async {
    await showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Sync Frequency'),
            children:
                _syncOptions
                    .map(
                      (option) => RadioListTile(
                        title: Text(option),
                        value: option,
                        groupValue: _syncFrequency,
                        onChanged: (value) {
                          setState(() => _syncFrequency = value!);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  Future<void> _changePassword() async {
    // Implement password change flow
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: const Text(
              'A password reset link will be sent to your email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final user = _authService.getCurrentUser();
                  if (user != null && user.email != null) {
                    await _authService.sendPasswordResetEmail(user.email!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  Future<void> _manageConnectedAccounts() async {
    // Implement account management
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Connected Accounts'),
            content: const Text('Manage your connected accounts and services.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAboutDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About CampusConnect'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version 1.0.0'),
                SizedBox(height: 8),
                Text('© 2025 CampusConnect Team'),
                SizedBox(height: 16),
                Text(
                  'CampusConnect helps students organize their campus life by tracking classes, assignments, group study sessions, and campus events.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../services/seed_data_service.dart';

/// Screen to manage Firebase seed data
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final SeedDataService _seedService = SeedDataService();
  final List<String> _logs = [];
  bool _isLoading = false;
  String? _currentAction;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().split('.').first}] $message');
    });
  }

  Future<void> _seedAllData() async {
    setState(() {
      _isLoading = true;
      _currentAction = 'Seeding all data...';
      _logs.clear();
    });

    try {
      await _seedService.seedAllData(onProgress: _addLog);
      _showSnackBar('✅ All data seeded successfully!', Colors.green);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackBar('Error seeding data: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _currentAction = null;
      });
    }
  }

  Future<void> _seedProducts() async {
    setState(() {
      _isLoading = true;
      _currentAction = 'Seeding products...';
    });

    try {
      await _seedService.seedProducts(onProgress: _addLog);
      _showSnackBar('✅ Products seeded!', Colors.green);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _currentAction = null;
      });
    }
  }

  Future<void> _seedUsers() async {
    setState(() {
      _isLoading = true;
      _currentAction = 'Seeding users...';
    });

    try {
      await _seedService.seedUsers(onProgress: _addLog);
      _showSnackBar('✅ Users seeded!', Colors.green);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _currentAction = null;
      });
    }
  }

  Future<void> _seedMessages() async {
    setState(() {
      _isLoading = true;
      _currentAction = 'Seeding messages...';
    });

    try {
      await _seedService.seedMessages(onProgress: _addLog);
      _showSnackBar('✅ Messages seeded!', Colors.green);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _currentAction = null;
      });
    }
  }

  Future<void> _seedPosts() async {
    setState(() {
      _isLoading = true;
      _currentAction = 'Seeding posts...';
    });

    try {
      await _seedService.seedPosts(onProgress: _addLog);
      _showSnackBar('✅ Posts seeded!', Colors.green);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _currentAction = null;
      });
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all seeded data from Firebase. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _currentAction = 'Clearing all data...';
      _logs.clear();
    });

    try {
      await _seedService.clearAllData(onProgress: _addLog);
      _showSnackBar('✅ All data cleared!', Colors.orange);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackBar('Error clearing data: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
        _currentAction = null;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Data Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.storage, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seed demo data for Firebase examples',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Seed All button
                  _buildMainActionCard(
                    title: 'Seed All Data',
                    subtitle:
                        'Populate all Firebase collections with demo data',
                    icon: Icons.cloud_upload,
                    color: Colors.green,
                    // onPressed: _isLoading ? null : _seedAllData,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Individual Collections',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Individual seed buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSeedChip(
                        label: 'Products (75)',
                        icon: Icons.shopping_bag,
                        color: Colors.purple,
                        // onPressed: _isLoading ? null : _seedProducts,
                      ),
                      _buildSeedChip(
                        label: 'Users (30)',
                        icon: Icons.people,
                        color: Colors.blue,
                        // onPressed: _isLoading ? null : _seedUsers,
                      ),
                      _buildSeedChip(
                        label: 'Messages (20)',
                        icon: Icons.chat,
                        color: Colors.teal,
                        // onPressed: _isLoading ? null : _seedMessages,
                      ),
                      _buildSeedChip(
                        label: 'Posts (20)',
                        icon: Icons.article,
                        color: Colors.orange,
                        // onPressed: _isLoading ? null : _seedPosts,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Clear data button
                  _buildMainActionCard(
                    title: 'Clear All Data',
                    subtitle: 'Remove all seeded data from Firebase',
                    icon: Icons.delete_forever,
                    color: Colors.red,
                    // onPressed: _isLoading ? null : _clearAllData,
                  ),

                  const SizedBox(height: 24),

                  // Collection Info
                  _buildCollectionInfoCard(),

                  const SizedBox(height: 24),

                  // Logs section
                  if (_logs.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Activity Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _logs.clear()),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color textColor = Colors.white70;
                          if (log.contains('✅')) textColor = Colors.green;
                          if (log.contains('❌')) textColor = Colors.red;

                          return Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(_currentAction ?? 'Processing...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onPressed == null ? Colors.grey : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedChip({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildCollectionInfoCard() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Data Collections',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCollectionRow(
              'products',
              'Firestore',
              'Used by: Pagination, Filters, Offline',
            ),
            _buildCollectionRow('users', 'Firestore', 'Used by: Search'),
            _buildCollectionRow('messages', 'Firestore', 'Used by: Realtime'),
            _buildCollectionRow('posts', 'RTDB', 'Used by: Realtime Database'),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionRow(String name, String type, String usage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: type == 'Firestore'
                  ? Colors.orange.shade100
                  : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                color: type == 'Firestore'
                    ? Colors.orange.shade800
                    : Colors.amber.shade800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              usage,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Data Manager'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This tool helps you populate Firebase with demo data:'),
            SizedBox(height: 12),
            Text('• Products: 75 items across 5 categories'),
            Text('• Users: 30 team members'),
            Text('• Messages: 20 chat messages'),
            Text('• Posts: 20 social media posts'),
            SizedBox(height: 12),
            Text(
              'The data is used by various Firebase example screens '
              'to demonstrate pagination, filtering, search, and real-time updates.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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

import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseViewerScreen extends StatefulWidget {
  @override
  _DatabaseViewerScreenState createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true; // Track loading state

  Future<void> _loadUsers() async {
    try {
      final db = await DatabaseHelper.instance.database; // Use DatabaseHelper to get the database
      final List<Map<String, dynamic>> users = await db.query('users');

      if (mounted) {
        setState(() {
          _users = users;
          _loading = false; // Update loading state
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false; // Stop loading on error
        });
        _showError('Failed to load users: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Viewer'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator()) // Show a loading indicator
          : _users.isEmpty
          ? Center(child: Text('No users found.'))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            title: Text('Email: ${user['email']}'),
            subtitle: Text('Role: ${user['role']}'),
            trailing: Text(
              'NIS: ${user['nis'] ?? 'N/A'}, Name: ${user['student_name'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600]), // Better text styling
            ),
          );
        },
      ),
    );
  }
}

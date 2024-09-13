import 'package:flutter/material.dart';
import '../database_helper.dart';

class ProfileStudentPage extends StatefulWidget {
  final String email;

  ProfileStudentPage({required this.email});

  @override
  _ProfileStudentPageState createState() => _ProfileStudentPageState();
}

class _ProfileStudentPageState extends State<ProfileStudentPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _name = '';
  String _email = '';
  String _nis = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final db = await DatabaseHelper.instance.database;

    try {
      final List<Map<String, dynamic>> user = await db.query(
        'students',
        where: 'email = ?',
        whereArgs: [widget.email],
      );

      if (user.isNotEmpty) {
        setState(() {
          _name = user[0]['student_name'] as String? ?? 'N/A';
          _email = user[0]['email'] as String? ?? 'N/A';
          _nis = user[0]['nis'] as String? ?? 'N/A';
        });
      } else {
        _showError('User not found!');
      }
    } catch (e) {
      _showError('Error loading user data: $e');
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      _showError('Passwords do not match!');
      return;
    }

    final db = await DatabaseHelper.instance.database;

    try {
      final List<Map<String, dynamic>> user = await db.query(
        'students',
        where: 'email = ? AND password = ?',
        whereArgs: [widget.email, currentPassword],
      );

      if (user.isNotEmpty) {
        await db.update(
          'students',
          {'password': newPassword},
          where: 'email = ? AND password = ?',
          whereArgs: [widget.email, currentPassword],
        );
        _showSuccess('Password changed successfully!');

        // Kosongkan text field setelah password berhasil diubah
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showError('Current password is incorrect!');
      }
    } catch (e) {
      _showError('Error changing password: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or any color you prefer
      body: Column(
        children: [
          SizedBox(height: 20), // Adjust this height if you need space at the top
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommonCard(_buildProfileInfo()),
                  SizedBox(height: 20),
                  _buildCommonCard(_buildPasswordChangeSection()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name: $_name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Email: $_email', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text('NIS: $_nis', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildPasswordChangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        TextField(
          controller: _currentPasswordController,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _changePassword,
          child: Text('Change Password'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 14),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCommonCard(Widget childContent) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: childContent,
      ),
    );
  }
}

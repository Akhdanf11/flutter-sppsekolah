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
          _name = user[0]['student_name'] as String? ?? 'Tidak Diketahui';
          _email = user[0]['email'] as String? ?? 'Tidak Diketahui';
          _nis = user[0]['nis'] as String? ?? 'Tidak Diketahui';
        });
      } else {
        _showError('Pengguna tidak ditemukan!');
      }
    } catch (e) {
      _showError('Kesalahan saat memuat data pengguna: $e');
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      _showError('Kata sandi baru tidak cocok!');
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
        _showSuccess('Kata sandi berhasil diubah!');

        // Kosongkan text field setelah password berhasil diubah
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showError('Kata sandi saat ini salah!');
      }
    } catch (e) {
      _showError('Kesalahan saat mengubah kata sandi: $e');
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileCard(),
                    SizedBox(height: 20),
                    _buildPasswordChangeCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama: $_name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Email: $_email', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('NIS: $_nis', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildPasswordChangeCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubah Kata Sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Saat Ini',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Baru',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Kata Sandi Baru',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Ubah Kata Sandi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

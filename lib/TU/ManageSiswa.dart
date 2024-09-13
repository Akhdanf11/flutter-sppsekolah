import 'package:flutter/material.dart';
import '../database_helper.dart';

class ManageStudentsPage extends StatefulWidget {
  final String email; // Add this line

  ManageStudentsPage({required this.email}); // Update constructor to accept email

  @override
  _ManageStudentsPageState createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> students = await db.query('students');
    setState(() {
      _students = students;
    });
  }

  Future<void> _toggleStudentStatus(int studentId, bool isActive) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'students',
      {'is_active': isActive ? 0 : 1},
      where: 'id = ?',
      whereArgs: [studentId],
    );
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Students')),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            title: Text(student['student_name']),
            subtitle: Text('NIS: ${student['nis']}'),
            trailing: Switch(
              value: student['is_active'] == 1,
              onChanged: (value) {
                _toggleStudentStatus(student['id'], student['is_active'] == 1);
              },
            ),
          );
        },
      ),
    );
  }
}

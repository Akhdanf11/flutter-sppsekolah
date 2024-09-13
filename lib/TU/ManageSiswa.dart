import 'package:flutter/material.dart';
import '../database_helper.dart';

class ManageStudentsPage extends StatefulWidget {
  final String email;

  ManageStudentsPage({required this.email});

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
      {'is_active': isActive ? 1 : 0}, // Active (1) or Inactive (0)
      where: 'id = ?',
      whereArgs: [studentId],
    );
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Siswa'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: _students.map((student) {
            return Card(
              margin: EdgeInsets.all(8.0),
              elevation: 4,
              child: ListTile(
                contentPadding: EdgeInsets.all(16.0),
                title: Text(
                  student['student_name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('NIS: ${student['nis']}'),
                trailing: Switch(
                  value: student['is_active'] == 1, // Active (1) or Inactive (0)
                  onChanged: (value) {
                    _toggleStudentStatus(student['id'], value);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

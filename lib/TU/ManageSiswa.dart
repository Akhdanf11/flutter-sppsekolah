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
  String? _selectedClass = 'Semua Kelas'; // Default to 'Semua Kelas'
  List<String> _classes = [
    'Semua Kelas',
    'VII-A', 'VII-B', 'VII-C', 'VII-D', 'VII-E',
    'VIII-A', 'VIII-B', 'VIII-C',
    'IX-A', 'IX-B', 'IX-C',
  ]; // List of classes

  @override
  void initState() {
    super.initState();
    _loadStudents(); // Load all students initially
  }

  Future<void> _loadStudents({String? selectedClass}) async {
    final db = await DatabaseHelper.instance.database;

    // If "Semua Kelas" is selected, load all students
    final List<Map<String, dynamic>> students = selectedClass != null && selectedClass != 'Semua Kelas'
        ? await db.query('students', where: 'kelas = ?', whereArgs: [selectedClass])
        : await db.query('students'); // Load all students if "Semua Kelas" is selected

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
    _loadStudents(selectedClass: _selectedClass); // Reload students based on the selected class
  }

  Future<void> _showUpdateStudentDialog(Map<String, dynamic> student) async {
    String? selectedClass = student['kelas']; // Current class of the student
    List<String> availableClasses = [
      'VII-A', 'VII-B', 'VII-C', 'VII-D', 'VII-E',
      'VIII-A', 'VIII-B', 'VIII-C',
      'IX-A', 'IX-B', 'IX-C',
    ]; // List of available classes

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pembaruan Kelas Siswa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sekarang Kelas: $selectedClass'),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Pilih Kelas Siswa Yang Baru',
                  border: OutlineInputBorder(),
                ),
                value: selectedClass,
                items: availableClasses.map((String className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (newClass) {
                  setState(() {
                    selectedClass = newClass;
                  });
                },
                isExpanded: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Kirim'),
              onPressed: () async {
                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'students',
                  {'kelas': selectedClass},
                  where: 'id = ?',
                  whereArgs: [student['id']],
                );
                Navigator.of(context).pop();
                _loadStudents(selectedClass: _selectedClass);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Siswa'),
      ),
      body: Column(
        children: [
          _buildClassDropdown(),
          Expanded(
            child: _students.isEmpty
                ? Center(child: Text('Tidak ada data siswa.'))
                : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Text(
                      student['student_name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'NIS: ${student['nis']}\nKelas: ${student['kelas']}'),
                    trailing: Switch(
                      value: student['is_active'] == 1, // Active (1) or Inactive (0)
                      onChanged: (value) {
                        _toggleStudentStatus(student['id'], value);
                      },
                    ),
                    onTap: () {
                      _showUpdateStudentDialog(student); // Show the update dialog when tapped
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown for selecting a class
  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          border: OutlineInputBorder(),
        ),
        value: _selectedClass,
        items: _classes.map((String className) {
          return DropdownMenuItem<String>(
            value: className,
            child: Text(className),
          );
        }).toList(),
        onChanged: (newClass) {
          setState(() {
            _selectedClass = newClass;
          });
          _loadStudents(
              selectedClass: _selectedClass == 'Semua Kelas'
                  ? null
                  : _selectedClass); // Load students based on selected class
        },
        isExpanded: true,
      ),
    );
  }
}

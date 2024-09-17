import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import '../database_helper.dart'; // Assume DatabaseHelper for fetching student data

class AllStudentsReportPage extends StatefulWidget {
  @override
  _AllStudentsReportPageState createState() => _AllStudentsReportPageState();
}

class _AllStudentsReportPageState extends State<AllStudentsReportPage> {
  List<Map<String, dynamic>> _students = [];
  String? _selectedClass;
  List<String> _classes = [
    'Semua Kelas',
    'VII-A', 'VII-B', 'VII-C',
    'VIII-A', 'VIII-B', 'VIII-C',
    'IX-A', 'IX-B', 'IX-C',
  ]; // List of classes

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents({String? selectedClass}) async {
    final db = DatabaseHelper.instance;
    final students = selectedClass != null && selectedClass != 'Semua Kelas'
        ? await db.getStudentsByClass(selectedClass)
        : await db.getAllStudents();

    setState(() {
      _students = students;
    });
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Data Siswa', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: ['No', 'NIS', 'NISN', 'Nama', 'Email', 'Jenis Kelamin', 'Kelas'],
                data: _students.map((student) {
                  return [
                    student['id'],
                    student['nis'],
                    student['nisn'],
                    student['student_name'],
                    student['email'],
                    student['jenis_kelamin'],
                    student['kelas']
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/students_report.pdf');
    await file.writeAsBytes(await pdf.save());

    Share.shareFiles([file.path], text: 'Laporan Data Semua Siswa');
  }

  Future<void> _printPdf() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Laporan Data Siswa', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    context: context,
                    headers: ['No', 'NIS', 'NISN', 'Nama', 'Email', 'Jenis Kelamin', 'Kelas'],
                    data: _students.map((student) {
                      return [
                        student['id'],
                        student['nis'],
                        student['nisn'],
                        student['student_name'],
                        student['email'],
                        student['jenis_kelamin'],
                        student['kelas']
                      ];
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
        return pdf.save();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Data Semua Siswa'),
        backgroundColor: Colors.blueAccent,
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
                  elevation: 2,
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(student['student_name']),
                    subtitle: Text(
                      'NIS: ${student['nis']}\nNISN: ${student['nisn']}\nEmail: ${student['email']}\nJenis Kelamin: ${student['jenis_kelamin']}\nKelas: ${student['kelas']}',
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printPdf,
                  icon: Icon(Icons.print),
                  label: Text('Cetak Laporan'),
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateAndSharePdf,
                  icon: Icon(Icons.share),
                  label: Text('Bagikan Laporan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          border: OutlineInputBorder(),
        ),
        value: _selectedClass,
        hint: Text('Semua Kelas'),
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
          _fetchStudents(selectedClass: _selectedClass); // Load students based on selected class
        },
        isExpanded: true,
      ),
    );
  }
}

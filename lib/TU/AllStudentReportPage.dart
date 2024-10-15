import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import '../database_helper.dart';

class AllStudentsReportPage extends StatefulWidget {
  @override
  _AllStudentsReportPageState createState() => _AllStudentsReportPageState();
}

class _AllStudentsReportPageState extends State<AllStudentsReportPage> {
  List<Map<String, dynamic>> _students = [];
  String? _selectedClass = 'Semua Kelas';  // Default value for class filter
  final List<String> _classes = [
    'Semua Kelas',
    'VII-A', 'VII-B', 'VII-C', 'VII-D', 'VII-E',
    'VIII-A', 'VIII-B', 'VIII-C',
    'IX-A', 'IX-B', 'IX-C',
  ];

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
    if (_students.isEmpty) {
      _showNoDataDialog();
      return;
    }

    // Generate the PDF document
    final pdf = await _createPdf();

    // Save the PDF to a temporary file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/all_students_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Create an XFile from the file path
    final xFile = XFile(file.path);

    // Share the PDF file using shareXFiles
    await Share.shareXFiles([xFile], text: 'Laporan Data Seluruh Siswa');
  }

  Future<pw.Document> _createPdf() async {
    final pdf = pw.Document();

    // Ambil semua siswa dari database
    final limitedStudents = _students; // Ambil semua data siswa yang ada

    // Define table headers
    final headers = [
      'No', 'NIS', 'NISN', 'Nama', 'Email', 'Jenis Kelamin', 'Kelas'
    ];

    // Pecah data ke dalam halaman berdasarkan jumlah siswa per halaman
    const pageItemCount = 10; // Jumlah item (siswa) per halaman
    final chunkedStudents = <List<Map<String, dynamic>>>[];

    for (var i = 0; i < limitedStudents.length; i += pageItemCount) {
      chunkedStudents.add(
        limitedStudents.sublist(
          i,
          i + pageItemCount > limitedStudents.length
              ? limitedStudents.length
              : i + pageItemCount,
        ),
      );
    }

    // Buat halaman untuk setiap chunk data siswa
    for (var chunk in chunkedStudents) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Laporan Data Siswa',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FixedColumnWidth(34),
                    1: pw.FixedColumnWidth(63),
                    2: pw.FixedColumnWidth(83),
                    3: pw.FixedColumnWidth(100),
                    4: pw.FixedColumnWidth(100),
                    5: pw.FixedColumnWidth(83),
                    6: pw.FixedColumnWidth(50),
                  },
                  children: [
                    pw.TableRow(
                      children: headers.map((header) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              header,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    ...chunk.asMap().entries.map((entry) {
                      final index = entry.key + 1 + (chunkedStudents.indexOf(chunk) * pageItemCount);
                      final student = entry.value;

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(index.toString()),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(student['nis'] ?? 'N/A'),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(student['nisn'] ?? 'N/A'),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(student['student_name'] ?? 'N/A'),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(student['email'] ?? 'N/A'),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(student['jenis_kelamin'] ?? 'N/A'),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(student['kelas'] ?? 'N/A'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // Return the generated PDF document
    return pdf;
  }

  Future<void> _previewPdf() async {
    if (_students.isEmpty) {
      _showNoDataDialog();
      return;
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();

        // Define table headers
        final headers = [
          'No', 'NIS', 'NISN', 'Nama', 'Email', 'Jenis Kelamin', 'Kelas'
        ];

        // Pecah data ke dalam halaman berdasarkan jumlah siswa per halaman
        const pageItemCount = 10; // Jumlah item (siswa) per halaman
        final chunkedStudents = <List<Map<String, dynamic>>>[];

        for (var i = 0; i < _students.length; i += pageItemCount) {
          chunkedStudents.add(
            _students.sublist(
              i,
              i + pageItemCount > _students.length
                  ? _students.length
                  : i + pageItemCount,
            ),
          );
        }

        // Buat halaman untuk setiap chunk data siswa
        for (var chunk in chunkedStudents) {
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Laporan Data Siswa',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: pw.FixedColumnWidth(38),
                        1: pw.FixedColumnWidth(63),
                        2: pw.FixedColumnWidth(83),
                        3: pw.FixedColumnWidth(100),
                        4: pw.FixedColumnWidth(87),
                        5: pw.FixedColumnWidth(83),
                        6: pw.FixedColumnWidth(52),
                      },
                      children: [
                        pw.TableRow(
                          children: headers.map((header) {
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  header,
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        ...chunk.asMap().entries.map((entry) {
                          final index = entry.key + 1 + (chunkedStudents.indexOf(chunk) * pageItemCount);
                          final student = entry.value;

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(index.toString()),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(student['nis'] ?? 'N/A'),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(student['nisn'] ?? 'N/A'),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(student['student_name'] ?? 'N/A'),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(student['email'] ?? 'N/A'),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(student['jenis_kelamin'] ?? 'N/A'),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8.0),
                                child: pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(student['kelas'] ?? 'N/A'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        }

        // Return the generated PDF document
        return pdf.save();
      },
    );
  }

  Future<void> _printStudentRecap() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        final db = DatabaseHelper.instance;

        // Fetch the recap data
        final recapData = await db.getStudentRecapByClass();

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rekapitulasi Jumlah Siswa',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: [
                      'No',
                      'Kelas',
                      'L',
                      'P',
                      'Jumlah L+P',
                      'Total per Kelas',
                    ],
                    data: recapData.asMap().entries.map((entry) {
                      final index = entry.key + 1; // Start numbering from 1
                      final recap = entry.value;

                      final totalLP = recap['jumlahL'] + recap['jumlahP']; // Total L + P
                      final totalPerKelas = recap['totalKelas'].toString(); // Total for this class/grade

                      return [
                        index.toString(),               // No
                        recap['kelas'],                 // Class/Grade
                        recap['jumlahL'].toString(),    // Number of Males (L)
                        recap['jumlahP'].toString(),    // Number of Females (P)
                        totalLP.toString(),             // Total L + P
                        totalPerKelas,                  // Total for each grade
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

  void _showNoDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Data'),
          content: Text('Tidak ada data siswa untuk ditampilkan.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
                  onPressed: _previewPdf,
                  icon: Icon(Icons.visibility),
                  label: Text('Pratinjau Laporan'),
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printStudentRecap, // Call the print function for student recap
                  icon: Icon(Icons.bar_chart),
                  label: Text('Cetak Rekap Siswa'),
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
      child: Row(
        children: [
          Text(
            'Pilih Kelas:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedClass,
            items: _classes.map((String className) {
              return DropdownMenuItem<String>(
                value: className,
                child: Text(className),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedClass = newValue;
                _fetchStudents(selectedClass: _selectedClass);
              });
            },
          ),
        ],
      ),
    );
  }
}
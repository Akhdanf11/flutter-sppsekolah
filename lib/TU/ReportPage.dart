import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import '../database_helper.dart';
import 'AllStudentReportPage.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _totalStudents = 0;
  int _paidStudents = 0;
  int _unpaidStudents = 0;
  double _totalIncome = 0.0;
  int _totalClasses = 0; // Variable for total classes

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    final db = DatabaseHelper.instance;
    final students = await db.getAllStudents();

    List<Map<String, dynamic>> updatedStudents = [];
    double totalIncome = 0.0;

    for (var student in students) {
      final studentData = await db.getStudentData(student['nis']);
      final updatedStudent = Map<String, dynamic>.from(student); // Create a mutable copy
      updatedStudent['amount_due'] = studentData?['amount_due'] ?? 0.0;
      updatedStudent['total_paid'] = studentData?['total_paid'] ?? 0.0;
      updatedStudent['payment_date'] = studentData?['payment_date'] ?? 'N/A';
      updatedStudent['va_number'] = studentData?['va_number'] ?? 'N/A';
      updatedStudent['payment_month'] = studentData?['payment_month'] ?? 'N/A';
      updatedStudent['status'] = studentData?['status'] ?? 0;

      updatedStudents.add(updatedStudent);

      if (studentData?['spp_paid'] == 1) {
        totalIncome += studentData?['total_paid'] ?? 0.0;
      }
    }

    setState(() {
      _totalStudents = students.length;
      _paidStudents = updatedStudents.where((student) => student['spp_paid'] == 1).length;
      _unpaidStudents = updatedStudents.where((student) => student['spp_paid'] != 1).length;
      _totalIncome = totalIncome;// Update total classes
    });
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Laporan SPP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Jumlah Siswa: $_totalStudents', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Siswa yang Telah Bayar: $_paidStudents', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Siswa yang Belum Bayar: $_unpaidStudents', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Total Pendapatan: ${formatCurrency(_totalIncome)}', style: pw.TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/report.pdf');
    await file.writeAsBytes(await pdf.save());

    Share.shareFiles([file.path], text: 'Laporan SPP');
  }

  Future<void> _printPdf() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan SPP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 20),
                    pw.Text('Jumlah Siswa: $_totalStudents', style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Siswa yang Telah Bayar: $_paidStudents', style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Siswa yang Belum Bayar: $_unpaidStudents', style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Total Pendapatan: ${formatCurrency(_totalIncome)}', style: pw.TextStyle(fontSize: 16)),
                  ],
                ),
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
        title: Text('Data Laporan'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Card for SPP information and buttons
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data SPP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Jumlah Siswa: $_totalStudents',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Siswa yang Telah Bayar: $_paidStudents',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Siswa yang Belum Bayar: $_unpaidStudents',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Total Pendapatan Siswa yang Membayar: ${formatCurrency(_totalIncome)}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _printPdf,
                            icon: Icon(Icons.print),
                            label: Text('Cetak Laporan'),
                          ),
                        ),
                        SizedBox(width: 8),
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
              ),
            ),
            SizedBox(height: 16),
            // Card for class information
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllStudentsReportPage()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lihat Laporan Semua Siswa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Klik untuk melihat laporan lengkap semua siswa.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _totalStudents = 0;
  int _paidStudents = 0;
  int _unpaidStudents = 0;
  double _totalIncome = 0.0;

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
      updatedStudents.add(updatedStudent);

      if (studentData?['spp_paid'] == 1) {
        totalIncome += studentData?['total_paid'] ?? 0.0;
      }
    }

    setState(() {
      _totalStudents = students.length;
      _paidStudents = updatedStudents.where((student) => student['spp_paid'] == 1).length;
      _unpaidStudents = updatedStudents.where((student) => student['spp_paid'] != 1).length;
      _totalIncome = totalIncome;
    });
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan SPP'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi SPP',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Action to perform when the button is pressed
              },
              child: Text('Unduh Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

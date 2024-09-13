import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../siswa/StudentPaymentPage.dart';
import '../siswa/PrintReceiptPage.dart'; // Import the PrintReceiptPage

class ManageSPPPage extends StatefulWidget {
  final String email;

  ManageSPPPage({required this.email});

  @override
  _ManageSPPPageState createState() => _ManageSPPPageState();
}

class _ManageSPPPageState extends State<ManageSPPPage> {
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final db = DatabaseHelper.instance;
    final students = await db.getAllStudents();

    List<Map<String, dynamic>> updatedStudents = [];

    for (var student in students) {
      final studentData = await db.getStudentData(student['nis']);
      final updatedStudent = Map<String, dynamic>.from(student); // Create a mutable copy
      updatedStudent['amount_due'] = studentData?['amount_due'] ?? 0.0;
      updatedStudent['total_paid'] = studentData?['total_paid'] ?? 0.0;
      updatedStudent['payment_date'] = studentData?['payment_date'] ?? 'N/A';
      updatedStudent['va_number'] = studentData?['va_number'] ?? 'N/A';
      updatedStudent['payment_month'] = studentData?['payment_month'] ?? 'N/A';
      updatedStudents.add(updatedStudent);

      // Debug: Print student data to verify
      print('Student Data: $updatedStudent');
    }

    setState(() {
      _students = updatedStudents;
    });
  }

  void _navigateToPaymentPage(String nis) async {
    if (nis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No NIS provided')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPaymentPage(
          nis: nis,
          email: widget.email,
        ),
      ),
    );

    if (result != null && result == true) {
      _fetchStudents(); // Refresh the student list if payment was successful
    }
  }

  void _navigateToPrintReceiptPage(Map<String, dynamic> paymentData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrintReceiptPage(
          paymentData: {
            'student_name': paymentData['student_name'],
            'nis': paymentData['nis'],
            'payment_date': paymentData['payment_date'] != 'N/A' ? paymentData['payment_date'] : '', // Handle 'N/A'
            'va_number': paymentData['va_number'],
            'payment_month': paymentData['payment_month'],
            'payment_amount': paymentData['payment_amount'],
          },
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date; // Return original date if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kelola SPP'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Telah Bayar'),
              Tab(text: 'Belum Bayar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab siswa yang telah membayar
            ListView.builder(
              itemCount: _students.where((student) => student['spp_paid'] == 1).length,
              itemBuilder: (context, index) {
                final paidStudents = _students.where((student) => student['spp_paid'] == 1).toList();
                final student = paidStudents[index];

                return GestureDetector(
                  onTap: () {
                    _navigateToPrintReceiptPage({
                      'student_name': student['student_name'],
                      'nis': student['nis'],
                      'payment_date': student['payment_date'] != 'N/A' ? student['payment_date'] : '', // Handle 'N/A'
                      'va_number': student['va_number'],
                      'payment_month': student['payment_month'],
                      'payment_amount': student['total_paid'],
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(student['student_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NIS: ${student['nis']}'),
                          Text('Jumlah Bayar: ${formatCurrency(student['total_paid'])}'),
                          Text('Tanggal Bayar: ${_formatDate(student['payment_date'])}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Tab siswa yang belum membayar
            ListView.builder(
              itemCount: _students.where((student) => (student['spp_paid'] ?? 0) == 0).length,
              itemBuilder: (context, index) {
                final unpaidStudents = _students.where((student) => (student['spp_paid'] ?? 0) == 0).toList();
                final student = unpaidStudents[index];
                final nis = student['nis'] ?? '';

                return GestureDetector(
                  onTap: () {
                    _navigateToPaymentPage(nis); // Navigate to payment page
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(student['student_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NIS: ${student['nis']}'),
                          Text('Jumlah Terutang: ${formatCurrency(student['amount_due'])}'),
                          Text('Pembayaran Terakhir: ${student['payment_date'] ?? 'Belum Ada Pembayaran'}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format the currency in Rupiah
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }
}

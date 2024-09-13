import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../siswa/StudentPaymentPage.dart';
import '../siswa/PrintRecieptPage.dart'; // Import the PrintReceiptPage

class ManageSPPPage extends StatefulWidget {
  final String email;

  ManageSPPPage({required this.email});

  @override
  _ManageSPPPageState createState() => _ManageSPPPageState();
}

class _ManageSPPPageState extends State<ManageSPPPage> {
  List<Map<String, dynamic>> _students = [];
  double _standardAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final db = DatabaseHelper.instance;
    final students = await db.getAllStudents();
    setState(() {
      _students = students;
    });
  }

  Future<void> _fetchStandardAmount(String nis) async {
    try {
      final amount = await DatabaseHelper.instance.getStandardAmount(nis);
      setState(() {
        _standardAmount = amount ?? 0.0;
      });
    } catch (e) {
      print('Error fetching standard amount: $e');
    }
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
        builder: (context) => PrintReceiptPage(paymentData: paymentData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage SPP'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Paid'),
              Tab(text: 'Unpaid'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Paid students tab
            ListView.builder(
              itemCount: _students.where((student) {
                return student['spp_paid'] == 1;
              }).length,
              itemBuilder: (context, index) {
                final paidStudents = _students.where((student) {
                  return student['spp_paid'] == 1;
                }).toList();

                final student = paidStudents[index];
                final totalPaid = student['total_paid'] != null ? student['total_paid'].toString() : '0.0';
                final paymentDate = student['payment_date'] != null
                    ? DateFormat('dd MMMM yyyy').format(DateTime.parse(student['payment_date']))
                    : 'Not Available';

                return ListTile(
                  title: Text(student['student_name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount Paid: ${formatCurrency(double.parse(totalPaid))}'),
                      Text('Date Paid: $paymentDate'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.print),
                    onPressed: () {
                      _navigateToPrintReceiptPage({
                        'student_name': student['student_name'],
                        'nis': student['nis'],
                        'payment_date': student['payment_date'],
                        'va_number': student['va_number'],
                        'payment_month': student['payment_month'],
                        'payment_amount': student['total_paid'],
                      });
                    },
                  ),
                );
              },
            ),

            // Unpaid students tab
            ListView.builder(
              itemCount: _students.where((student) {
                return (student['spp_paid'] ?? 0) == 0;
              }).length,
              itemBuilder: (context, index) {
                final unpaidStudents = _students.where((student) {
                  return (student['spp_paid'] ?? 0) == 0;
                }).toList();

                final student = unpaidStudents[index];
                final nis = student['nis'] ?? '';

                return ListTile(
                  title: Text(student['student_name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount Due: ${formatCurrency(_standardAmount)}'),
                      Text('Last Payment: ${student['payment_date'] ?? 'Never Paid'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.payment),
                    onPressed: () async {
                      if (nis.isNotEmpty) {
                        await _fetchStandardAmount(nis); // Fetch the amount based on the student's NIS
                        _navigateToPaymentPage(nis); // Navigate to payment page
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: No NIS provided')),
                        );
                      }
                    },
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

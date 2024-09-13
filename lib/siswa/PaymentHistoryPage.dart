import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'PrintRecieptPage.dart';

class PaymentHistoryPage extends StatelessWidget {
  final String nis;

  PaymentHistoryPage({required this.nis});

  Future<List<Map<String, dynamic>>> _getPaymentHistory() async {
    try {
      return await DatabaseHelper.instance.getPaymentHistoryByNis(nis);
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // Function to format amounts as Indonesian Rupiah
  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    return formatCurrency.format(amount);
  }

  // Function to format dates
  String _formatDate(String date) {
    final formatDate = DateFormat('dd MMMM yyyy'); // Ensure this matches the PrintReceiptPage format
    return formatDate.format(DateTime.parse(date));
  }

  // Function to check if the payment is for the current month
  bool _isCurrentMonth(String date) {
    final paymentDate = DateTime.parse(date);
    final now = DateTime.now();
    return paymentDate.year == now.year && paymentDate.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No payment history found.'));
          } else {
            final payments = snapshot.data!;
            return ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return ListTile(
                  title: Text('Amount: ${_formatCurrency(payment['payment_amount'])}'),
                  subtitle: Text(
                    'Date: ${_formatDate(payment['payment_date'])}' +
                        (_isCurrentMonth(payment['payment_date']) ? ' (Current Month)' : ''),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrintReceiptPage(paymentData: payment),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

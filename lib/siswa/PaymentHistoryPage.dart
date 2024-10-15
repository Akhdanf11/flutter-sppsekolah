import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'PrintReceiptPage.dart';

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
    final formatDate = DateFormat('dd MMMM yyyy');
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
        title: Text('Riwayat Pembayaran'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getPaymentHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Riwayat pembayaran tidak ditemukan.'));
            } else {
              final payments = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: payments.map((payment) {
                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Text(
                          'Jumlah: ${_formatCurrency(payment['payment_amount'])}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tanggal: ${_formatDate(payment['payment_date'])}' +
                              (_isCurrentMonth(payment['payment_date']) ? ' (Bulan Ini)' : ''),
                          style: TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrintReceiptPage(paymentData: payment),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

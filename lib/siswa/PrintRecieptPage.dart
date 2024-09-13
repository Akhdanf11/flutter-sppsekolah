import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class PrintReceiptPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;

  PrintReceiptPage({required this.paymentData});

  String formatDate(String dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    return DateFormat('dd MMMM yyyy HH:mm:ss').format(dateTime);
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 24)),
                  pw.SizedBox(height: 20),
                  pw.Text('Student Name: ${paymentData['student_name'] ?? 'N/A'}'),
                  pw.Text('NIS: ${paymentData['nis'] ?? 'N/A'}'),
                  pw.Text('Payment Date: ${formatDate(paymentData['payment_date'] ?? 'N/A')}'),
                  pw.Text('VA Number: ${paymentData['va_number'] ?? 'N/A'}'),
                  pw.Text('Paid for Month: ${paymentData['payment_month'] ?? 'N/A'}'),
                  pw.Text('Amount Paid: ${formatCurrency(paymentData['payment_amount'] ?? 0)}'),
                ],
              ),
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/receipt.pdf');
      await file.writeAsBytes(await pdf.save());

      Share.shareFiles([file.path], text: 'Payment Receipt');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing receipt: $e')));
    }
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Receipt'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Name: ${paymentData['student_name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'NIS: ${paymentData['nis'] ?? 'N/A'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'VA Number: ${paymentData['va_number'] ?? 'N/A'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Payment Date: ${formatDate(paymentData['payment_date'] ?? 'N/A')}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Paid for Month: ${paymentData['payment_month'] ?? 'N/A'}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Amount Paid: ${formatCurrency(paymentData['payment_amount'] ?? 0)}',
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async {
                        final pdf = pw.Document();
                        pdf.addPage(
                          pw.Page(
                            pageFormat: format,
                            build: (pw.Context context) {
                              return pw.Center(
                                child: pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 24)),
                                    pw.SizedBox(height: 20),
                                    pw.Text('Student Name: ${paymentData['student_name'] ?? 'N/A'}'),
                                    pw.Text('NIS: ${paymentData['nis'] ?? 'N/A'}'),
                                    pw.Text('Payment Date: ${formatDate(paymentData['payment_date'] ?? 'N/A')}'),
                                    pw.Text('VA Number: ${paymentData['va_number'] ?? 'N/A'}'),
                                    pw.Text('Paid for Month: ${paymentData['payment_month'] ?? 'N/A'}'),
                                    pw.Text('Amount Paid: ${formatCurrency(paymentData['payment_amount'] ?? 0)}'),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                        return pdf.save();
                      },
                    );
                  },
                  icon: Icon(Icons.print),
                  label: Text('Print Receipt'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _shareReceipt(context);
                  },
                  icon: Icon(Icons.share),
                  label: Text('Share Receipt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


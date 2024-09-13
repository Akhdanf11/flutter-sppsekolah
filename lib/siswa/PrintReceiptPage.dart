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
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(dateStr);
    } catch (e) {
      return 'Tanggal tidak tersedia';
    }
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
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Struk Pembayaran', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Nama Siswa: ${paymentData['student_name'] ?? 'N/A'}'),
                  pw.Text('NIS: ${paymentData['nis'] ?? 'N/A'}'),
                  pw.Text('Tanggal Pembayaran: ${formatDate(paymentData['payment_date'] ?? 'N/A')}'),
                  pw.Text('Nomor VA: ${paymentData['va_number'] ?? 'N/A'}'),
                  pw.Text('Pembayaran Bulan: ${paymentData['payment_month'] ?? 'N/A'}'),
                  pw.Text('Jumlah Dibayar: ${formatCurrency(paymentData['payment_amount'] ?? 0)}'),
                ],
              ),
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/receipt.pdf');
      await file.writeAsBytes(await pdf.save());

      Share.shareFiles([file.path], text: 'Struk Pembayaran');
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
    // Parse and format the date safely
    DateTime? paymentDate;
    try {
      paymentDate = DateTime.parse(paymentData['payment_date'] ?? '');
    } catch (e) {
      paymentDate = null;
    }
    String formattedDate = paymentDate != null ? DateFormat.yMMMd().format(paymentDate) : 'Tanggal tidak tersedia';

    return Scaffold(
      appBar: AppBar(
        title: Text('Struk Pembayaran'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 8,
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Siswa: ${paymentData['student_name'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'NIS: ${paymentData['nis'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Nomor VA: ${paymentData['va_number'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tanggal Pembayaran: $formattedDate',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Pembayaran Bulan: ${paymentData['payment_month'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Jumlah Dibayar: ${formatCurrency(paymentData['payment_amount'] ?? 0)}',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Struk Pembayaran', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                                    pw.SizedBox(height: 20),
                                    pw.Text('Nama Siswa: ${paymentData['student_name'] ?? 'N/A'}'),
                                    pw.Text('NIS: ${paymentData['nis'] ?? 'N/A'}'),
                                    pw.Text('Tanggal Pembayaran: ${formatDate(paymentData['payment_date'] ?? 'N/A')}'),
                                    pw.Text('Nomor VA: ${paymentData['va_number'] ?? 'N/A'}'),
                                    pw.Text('Pembayaran Bulan: ${paymentData['payment_month'] ?? 'N/A'}'),
                                    pw.Text('Jumlah Dibayar: ${formatCurrency(paymentData['payment_amount'] ?? 0)}'),
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
                  label: Text('Cetak Struk'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _shareReceipt(context);
                  },
                  icon: Icon(Icons.share),
                  label: Text('Bagikan Struk'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

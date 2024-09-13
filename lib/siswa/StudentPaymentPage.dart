import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class StudentPaymentPage extends StatefulWidget {
  final String nis;
  final String email;

  StudentPaymentPage({
    required this.nis,
    required this.email,
  });

  @override
  _StudentPaymentPageState createState() => _StudentPaymentPageState();
}

class _StudentPaymentPageState extends State<StudentPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double _standardAmount = 0.0;
  String _vaNumber = '';
  String _studentName = '';
  String _nis = '';
  String _amountError = ''; // To hold error message

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final studentData = await DatabaseHelper.instance.getStudentData(widget.nis);
      if (studentData != null) {
        setState(() {
          _standardAmount = studentData['amount_due'] ?? 0.0;
          _vaNumber = studentData['va_number'] ?? '';
          _studentName = studentData['student_name'] ?? 'N/A';
          _nis = widget.nis;
        });
      }
    } catch (e) {
      print('Error fetching student data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching student data: $e')),
      );
    }
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount != _standardAmount) {
      setState(() {
        _amountError = 'Jumlah harus sama persis dengan jumlah yang harus dibayar.';
      });
      return;
    } else {
      setState(() {
        _amountError = '';
      });
    }

    try {
      // Check for existing payment in the same month
      final existingPayment = await DatabaseHelper.instance.getPaymentByMonth(widget.nis, _selectedDate.month, _selectedDate.year);
      if (existingPayment.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran untuk bulan ini sudah tercatat.')),
        );
        return;
      }

      // Generate VA number logic (ensure this matches your actual generation logic)
      final vaNumber = _vaNumber;

      // Update payment details
      await DatabaseHelper.instance.updatePaymentDetailsByNis(
        widget.nis,
        amount,
        vaNumber,
        _selectedDate.month,
        _selectedDate.year,
      );

      // Update SPP Paid status
      await DatabaseHelper.instance.updateSppPaidStatus(widget.nis);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran berhasil dicatat.')),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      print('Error recording payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran Siswa'),
      ),
    body: SingleChildScrollView(
      child: Padding(
      padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              SizedBox(height: 20.0),
              _buildPaymentForm(),
            ],
          ),
      ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Siswa: $_studentName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            Text('NIS: $_nis', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8.0),
            Text('Nomor VA: $_vaNumber', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8.0),
            Text('Jumlah yang Harus Dibayar: ${formatCurrency(_standardAmount)}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Formulir Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.0),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Jumlah Pembayaran',
                errorText: _amountError.isNotEmpty ? _amountError : null,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (double.tryParse(value) != _standardAmount) {
                  setState(() {
                    _amountError = 'Jumlah harus sesuai.';
                  });
                } else {
                  setState(() {
                    _amountError = '';
                  });
                }
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _recordPayment,
              child: Text('Kirim Pembayaran'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }
}

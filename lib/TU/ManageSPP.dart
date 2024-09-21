import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../siswa/StudentPaymentPage.dart';
import '../siswa/PrintReceiptPage.dart';

class ManageSPPPage extends StatefulWidget {
  final String email;

  ManageSPPPage({required this.email});

  @override
  _ManageSPPPageState createState() => _ManageSPPPageState();
}

class _ManageSPPPageState extends State<ManageSPPPage> {
  List<Map<String, dynamic>> _students = [];
  String? _selectedClass;
  List<String> _classes = [
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

    List<Map<String, dynamic>> students = (selectedClass != null && selectedClass != 'Semua Kelas')
        ? await db.getStudentsByClass(selectedClass)
        : await db.getAllStudents();

    List<Map<String, dynamic>> updatedStudents = [];

    for (var student in students) {
      final studentData = await db.getStudentData(student['nis']);
      final updatedStudent = Map<String, dynamic>.from(student);
      updatedStudent['amount_due'] = studentData?['amount_due'] ?? 0.0;
      updatedStudent['total_paid'] = studentData?['total_paid'] ?? 0.0;
      updatedStudent['payment_date'] = studentData?['payment_date'] ?? 'N/A';
      updatedStudent['va_number'] = studentData?['va_number'] ?? 'N/A';
      updatedStudent['payment_month'] = studentData?['payment_month'] ?? 'N/A';
      updatedStudents.add(updatedStudent);
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
      _fetchStudents(selectedClass: _selectedClass);
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
            'payment_date': paymentData['payment_date'] != 'N/A' ? paymentData['payment_date'] : '',
            'va_number': paymentData['va_number'],
            'payment_month': paymentData['payment_month'],
            'payment_amount': paymentData['payment_amount'],
          },
        ),
      ),
    );
  }

  void _showUpdateSPPDialog(Map<String, dynamic> student) {
    final TextEditingController _sppController = TextEditingController(text: student['amount_due'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Nominal SPP'),
          content: TextField(
            controller: _sppController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Nominal SPP'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                double? newAmount = double.tryParse(_sppController.text);
                if (newAmount != null) {
                  await DatabaseHelper.instance.updateSppAmount(student['nis'], newAmount);
                  Navigator.of(context).pop();
                  _fetchStudents(selectedClass: _selectedClass);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silakan masukkan nominal yang valid.')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showGlobalUpdateDialog() {
    final TextEditingController _sppController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Nominal SPP untuk Semua Siswa'),
          content: TextField(
            controller: _sppController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Nominal SPP Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                double? newAmount = double.tryParse(_sppController.text);
                if (newAmount != null) {
                  await DatabaseHelper.instance.updateAllSppAmounts(newAmount);
                  Navigator.of(context).pop();
                  _fetchStudents(selectedClass: _selectedClass);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nominal SPP berhasil diperbarui untuk semua siswa.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silakan masukkan nominal yang valid.')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kelola SPP'),
          actions: [
            IconButton(
              icon: Icon(Icons.attach_money_rounded),
              onPressed: _showGlobalUpdateDialog, // Show global update dialog
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Telah Bayar'),
              Tab(text: 'Belum Bayar'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildClassDropdown(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildStudentList(filterPaid: true),
                  _buildStudentList(filterPaid: false),
                ],
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

  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          border: OutlineInputBorder(),
        ),
        value: _selectedClass ?? 'Semua Kelas',
        items: _classes.map((String className) {
          return DropdownMenuItem<String>(
            value: className,
            child: Text(className),
          );
        }).toList(),
        onChanged: (newClass) {
          setState(() {
            _selectedClass = newClass;
          });
          _fetchStudents(selectedClass: _selectedClass);
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildStudentList({required bool filterPaid}) {
    final filteredStudents = _students.where((student) => student['spp_paid'] == (filterPaid ? 1 : 0)).toList();

    if (filteredStudents.isEmpty) {
      return Center(child: Text('Tidak ada data siswa.'));
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];

        return GestureDetector(
          onTap: () {
            if (filterPaid) {
              _navigateToPrintReceiptPage({
                'student_name': student['student_name'],
                'nis': student['nis'],
                'payment_date': student['payment_date'] != 'N/A' ? student['payment_date'] : '',
                'va_number': student['va_number'],
                'payment_month': student['payment_month'],
                'payment_amount': student['total_paid'],
              });
            } else {
              _navigateToPaymentPage(student['nis']);
            }
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
                  if (filterPaid)
                    ...[
                      Text('Jumlah Bayar: ${formatCurrency(student['total_paid'])}'),
                      Text('Tanggal Bayar: ${_formatDate(student['payment_date'])}'),
                    ]
                  else
                    ...[
                      Text('Jumlah Terutang: ${formatCurrency(student['amount_due'])}'),
                      Text('Pembayaran Terakhir: ${student['payment_date'] ?? 'Belum Ada Pembayaran'}'),
                    ],
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _showUpdateSPPDialog(student);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

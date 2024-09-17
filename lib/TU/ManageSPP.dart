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
  String? _selectedClass;
  List<String> _classes = [
    'Semua Kelas',
    'VII-A', 'VII-B', 'VII-C',
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

    // Query based on selected class if any, or all classes if 'Semua Kelas' is selected
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
        body: Column(
          children: [
            _buildClassDropdown(), // Dropdown for class selection
            Expanded(
              child: TabBarView(
                children: [
                  // Tab siswa yang telah membayar
                  _buildStudentList(
                    filterPaid: true,
                  ),
                  // Tab siswa yang belum membayar
                  _buildStudentList(
                    filterPaid: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format currency in Rupiah
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  // Dropdown for selecting a class
  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          border: OutlineInputBorder(),
        ),
        value: _selectedClass ?? 'Semua Kelas', // Default value set to 'Semua Kelas'
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

  // Widget to display the list of students
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
            ),
          ),
        );
      },
    );
  }
}

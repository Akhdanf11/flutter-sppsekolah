import 'package:flutter/material.dart';
import '../LoginPage.dart';
import 'ProfileStudentPage.dart';
import 'StudentPaymentPage.dart';
import 'PaymentHistoryPage.dart';

class StudentMainPage extends StatefulWidget {
  final String email;
  final String studentName;
  final String nis;

  StudentMainPage({
    required this.email,
    required this.studentName,
    required this.nis,
  });

  @override
  _StudentMainPageState createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  int _selectedIndex = 0;

  List<Widget> _buildPages() {
    return [
      // Halaman Utama dengan tombol untuk "Riwayat Pembayaran" dan "Bayar SPP"
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Selamat ${_greetingMessage()}, ${widget.studentName}!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text('NIS: ${widget.nis}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              // DashboardCard untuk Riwayat Pembayaran
              DashboardCard(
                icon: Icons.history,
                title: 'Riwayat Pembayaran',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentHistoryPage(nis: widget.nis),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              // DashboardCard untuk Bayar SPP
              DashboardCard(
                icon: Icons.monetization_on,
                title: 'Bayar SPP',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentPaymentPage(
                        nis: widget.nis,
                        email: widget.email,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // Halaman Profil
      ProfileStudentPage(email: widget.email),
    ];
  }

  String _greetingMessage() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Pagi';
    } else if (hour < 17) {
      return 'Siang';
    } else {
      return 'Malam';
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Memicu dialog logout ketika "Logout" dipilih
      _showLogoutDialog();
    } else {
      // Memperbarui indeks yang dipilih untuk Halaman Utama dan Profil
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Keluar'),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _logout();
              },
              child: Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, // Hapus semua route sebelumnya
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Siswa'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _buildPages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Tangani ketukan item BottomNavigationBar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Keluar',
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  const DashboardCard({
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontSize: 18)),
        onTap: onPressed,
      ),
    );
  }
}

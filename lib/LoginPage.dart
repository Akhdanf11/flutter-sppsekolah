import 'package:flutter/material.dart';
import 'database_helper.dart'; // Pastikan import ini sesuai dengan struktur proyek Anda

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'Siswa'; // Peran default
  bool _isPasswordVisible = false; // Toggle visibilitas password

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (_selectedRole == 'Siswa') {
      // Login siswa
      final student = await DatabaseHelper.instance.loginStudent(email, password);
      if (student != null) {
        if (student['is_active'] == 0) {
          // Menangani siswa yang tidak aktif
          _showError('Akun Anda tidak aktif. Silakan hubungi Tata Usaha.');
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/student_main_page',
                (route) => false, // Hapus semua route sebelumnya
            arguments: {
              'nis': student['nis'],
              'email': student['email'],
              'student_name': student['student_name'], // Kirim student_name
              'student_id': student['id'], // Kirim student_id
            },
          );
        }
      } else {
        _showError('Login gagal. Periksa kredensial Anda atau pendaftaran.');
      }
    } else if (_selectedRole == 'Tata Usaha') {
      // Login staff
      final staff = await DatabaseHelper.instance.loginStaff(email, password);
      if (staff != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tumain_page', // Nama route yang diperbarui
              (route) => false, // Hapus semua route sebelumnya
          arguments: staff['email'] ?? '', // Pastikan tipe argumen benar
        );
      } else {
        _showError('Login Anda gagal. Periksa kredensial Anda atau pendaftaran.');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Masuk'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Masuk',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: [
                  DropdownMenuItem(
                    child: Text('Siswa'),
                    value: 'Siswa',
                  ),
                  DropdownMenuItem(
                    child: Text('Tata Usaha'),
                    value: 'Tata Usaha',
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Peran',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Masuk'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent, // Warna teks tombol
                  padding: EdgeInsets.symmetric(vertical: 16), // Tinggi tombol
                  textStyle: TextStyle(fontSize: 18), // Ukuran teks tombol
                  minimumSize: Size(double.infinity, 50), // Lebar tombol
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  "Belum punya akun? Daftar",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

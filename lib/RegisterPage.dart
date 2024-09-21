import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _nisnController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nipController = TextEditingController(); // For Staff NIP

  String _selectedRole = 'Siswa'; // Default role
  String _selectedGender = 'Laki-Laki'; // Default gender
  String _selectedClass = 'VII-A'; // Default class
  bool _isPasswordVisible = false; // Password visibility toggle

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final role = _selectedRole;
    final nis = _nisController.text.trim();
    final nisn = _nisnController.text.trim();
    final name = _nameController.text.trim();
    final nip = _nipController.text.trim(); // Corrected NIP for staff
    final gender = _selectedGender;
    final classSection = _selectedClass;

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showError('Silakan lengkapi semua kolom yang diperlukan!');
      return;
    }

    if (role == 'Siswa') {
      if (nis.isEmpty || nisn.isEmpty) {
        _showError('NIS dan NISN harus diisi untuk siswa!');
        return;
      }
      if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(nis) || !RegExp(r'^[0-9]+$').hasMatch(nisn)) {
        _showError('NIS harus berisi angka dengan format yang benar, dan NISN harus berisi angka saja!');
        return;
      }
    }

    if (role == 'Tata Usaha') {
      if (nip.isEmpty) {
        _showError('NIP harus diisi untuk Tata Usaha!');
        return;
      }
    }

    try {
      bool emailExists = await DatabaseHelper.instance.isEmailTaken(email);
      if (emailExists) {
        _showError('Email sudah terdaftar!');
        return;
      }

      // Registration process
      if (role == 'Siswa') {
        await DatabaseHelper.instance.registerStudent(
          email,
          password,
          nis,
          nisn,
          name,
          gender,
          classSection,
        );
      } else if (role == 'Tata Usaha') {
        await DatabaseHelper.instance.registerStaff(
          email,
          password,
          name,  // Ensure this is the correct 'name' for Tata Usaha
          nip,   // Corrected to store NIP instead of phoneNumber
        );
      }

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showError('Terjadi kesalahan saat registrasi: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi'),
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
                'Registrasi',
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
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                  DropdownMenuItem(child: Text('Siswa'), value: 'Siswa'),
                  DropdownMenuItem(child: Text('Tata Usaha'), value: 'Tata Usaha'),
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
              SizedBox(height: 16),

              if (_selectedRole == 'Siswa') ...[
                TextField(
                  controller: _nisController,
                  decoration: InputDecoration(
                    labelText: 'NIS',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nisnController,
                  decoration: InputDecoration(
                    labelText: 'NISN',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: [
                    DropdownMenuItem(child: Text('Laki-Laki'), value: 'Laki-Laki'),
                    DropdownMenuItem(child: Text('Perempuan'), value: 'Perempuan'),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  items: [
                    DropdownMenuItem(child: Text('VII-A'), value: 'VII-A'),
                    DropdownMenuItem(child: Text('VII-B'), value: 'VII-B'),
                    DropdownMenuItem(child: Text('VII-C'), value: 'VII-C'),
                    DropdownMenuItem(child: Text('VII-C'), value: 'VII-D'),
                    DropdownMenuItem(child: Text('VII-C'), value: 'VII-E'),
                    DropdownMenuItem(child: Text('VIII-A'), value: 'VIII-A'),
                    DropdownMenuItem(child: Text('VIII-B'), value: 'VIII-B'),
                    DropdownMenuItem(child: Text('VIII-C'), value: 'VIII-C'),
                    DropdownMenuItem(child: Text('IX-A'), value: 'IX-A'),
                    DropdownMenuItem(child: Text('IX-B'), value: 'IX-B'),
                    DropdownMenuItem(child: Text('IX-C'), value: 'IX-C'),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else if (_selectedRole == 'Tata Usaha') ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nipController, // NIP input for staff
                  decoration: InputDecoration(
                    labelText: 'NIP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _register,
                child: Text('Daftar'),
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
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  'Sudah punya akun? Masuk',
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

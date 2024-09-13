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
  final TextEditingController _nisOrNipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _selectedRole = 'Siswa'; // Default role
  bool _isPasswordVisible = false; // Password visibility toggle

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final role = _selectedRole;
    final nisOrNip = _nisOrNipController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || nisOrNip.isEmpty || name.isEmpty) {
      _showError('Please fill in all fields!');
      return;
    }

    // Validate NIS/NIP to ensure it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(nisOrNip)) {
      _showError('NIS/NIP must contain only numbers!');
      return;
    }

    try {
      bool emailExists = await DatabaseHelper.instance.isEmailTaken(email); // Ensure you await
      if (emailExists) { // Handle the case where emailExists could be null
        _showError('Email is already registered!');
        return;
      }

      if (role == 'Siswa') {
        await DatabaseHelper.instance.registerStudent(
          email,
          password,
          nisOrNip,
          name,
        );
      } else if (role == 'Tata Usaha') {
        await DatabaseHelper.instance.registerStaff(
          email,
          password,
          nisOrNip,
          name,
        );
      } else {
        _showError('Invalid role! Use Siswa or Tata Usaha.');
        return;
      }
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showError('Error during registration: $e');
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
        title: Text('Register'),
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
                'Register',
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
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nisOrNipController,
                decoration: InputDecoration(
                  labelText: 'NIS/NIP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

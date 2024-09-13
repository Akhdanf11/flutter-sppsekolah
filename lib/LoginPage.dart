import 'package:flutter/material.dart';
import 'database_helper.dart'; // Ensure this import matches your project structure

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'Siswa'; // Default role
  bool _isPasswordVisible = false; // Password visibility toggle

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (_selectedRole == 'Siswa') {
      // Student login
      var student = await DatabaseHelper.instance.loginStudent(email, password);
      if (student != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/student_main_page',
              (route) => false, // Remove all previous routes
          arguments: {
            'nis': student['nis'],
            'email': student['email'],
            'student_name': student['student_name'], // Send student_name
            'student_id': student['student_id'], // Send student_id
          },
        );
      } else {
        _showError('Login failed. Please check your credentials or register.');
      }
    } else if (_selectedRole == 'Tata Usaha') {
      // Staff login
      var staff = await DatabaseHelper.instance.loginStaff(email, password);
      if (staff != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tumain_page', // Updated route name
              (route) => false, // Remove all previous routes
          arguments: staff['email'] ?? '', // Ensure correct argument type
        );
      } else {
        _showError('Login failed. Please check your credentials or register.');
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
        title: Text('Login'),
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
                'Login',
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blueAccent, // Button text color
                  padding: EdgeInsets.symmetric(vertical: 16), // Button height
                  textStyle: TextStyle(fontSize: 18), // Button text size
                  minimumSize: Size(double.infinity, 50), // Button width
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  "Don't have an account? Register",
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

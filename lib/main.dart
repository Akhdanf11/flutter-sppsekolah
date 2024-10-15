import 'package:flutter/material.dart';
import 'LoginPage.dart';
import 'RegisterPage.dart';
import 'siswa/StudentMainPage.dart';
import 'siswa/ProfileStudentPage.dart';
import 'TU/ManageSiswa.dart';
import 'TU/ManageSPP.dart';
import 'TU/ProfileTUPage.dart';
import 'TU/TUMainPage.dart';
import 'CSVImporter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CSVImporter csvImporter = CSVImporter(); // Inisialisasi CSVImporter
  await csvImporter.loadCSVData(); // Memanggil loadCSVData untuk impor CSV
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterPage());
          case '/student_main_page':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => StudentMainPage(
                email: args['email'] ?? '',
                studentName: args['student_name'] ?? '',
                nis: args['nis'] ?? '',
              ),
            );
          case '/profile_student_page':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ProfileStudentPage(
                email: args['email'] ?? '',
              ),
            );
          case '/manage_siswa':
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (context) => ManageStudentsPage(email: email),
            );
          case '/manage_spp_page':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ManageSPPPage(
                email: args['email'] ?? '',
              ),
            );
          case '/profile_tu':
            final email = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => ProfileTUPage(email: email ?? ''),
            );
          case '/tumain_page':
            final email = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => TUMainPage(email: email ?? ''),
            );
          default:
            return MaterialPageRoute(builder: (context) => LoginPage());
        }
      },
    );
  }
}

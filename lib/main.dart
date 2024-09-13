import 'package:flutter/material.dart';
import 'LoginPage.dart';
import 'RegisterPage.dart';
import 'siswa/StudentMainPage.dart';
import 'siswa/ProfileStudentPage.dart';
import 'TU/ManageSiswa.dart';
import 'TU/ManageSPP.dart';
import 'TU/ProfileTUPage.dart';
import 'TU/TUMainPage.dart';
import 'db_viewer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> deleteLocalDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'app_database.db');
  await deleteDatabase(path); // Call the sqflite's deleteDatabase function
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await deleteLocalDatabase(); // Use the renamed function
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
                nis: args['nis'] ?? '', // Ensure nis is passed
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
                email: args['email'] ?? '', // Ensure email is passed
              ),
            );
          case '/profile_tu':
            final email = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => ProfileTUPage(email: email ?? ''),
            );
          case '/db_viewer':
            return MaterialPageRoute(builder: (context) => DatabaseViewerScreen());
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

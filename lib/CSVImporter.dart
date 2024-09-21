import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'database_helper.dart'; // Ensure you have this file

class CSVImporter {
  // Function to parse CSV string into a list of maps
  List<Map<String, String>> parseCsv(String csvData) {
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvData);
    List<Map<String, String>> students = [];

    // Extract headers from the first row
    List<String> headers = rowsAsListOfValues.first.cast<String>();

    // Extract each row and map it to a student record
    for (var i = 1; i < rowsAsListOfValues.length; i++) { // Start from the second row (skip headers)
      Map<String, String> student = {};
      for (var j = 0; j < headers.length; j++) {
        student[headers[j]] = rowsAsListOfValues[i][j].toString();
      }
      students.add(student);
    }
    return students;
  }

  // Function to load CSV data and register students
  Future<void> loadCSVData() async {
    try {
      // Load CSV data from the assets
      final csvData = await rootBundle.loadString('assets/data/students.csv');

      // Parse the CSV data into a list of maps
      List<Map<String, String>> students = parseCsv(csvData);

      // Debugging: Print the parsed data
      print('Parsed students: $students');

      // Register each student in the database
      for (var student in students) {
        String email = student['email'] ?? 'N/A';
        String password = student['password'] ?? 'N/A';
        String nis = student['nis'] ?? 'N/A';
        String nisn = student['nisn'] ?? 'N/A';
        String studentName = student['student_name'] ?? 'N/A';
        String jenisKelamin = student['jenis_kelamin'] ?? 'N/A';
        String kelas = student['kelas']?.trim() ?? 'N/A';

        print('Importing student: $email, $nis, $nisn, $studentName, $jenisKelamin, $kelas'); // Debug line

        // Register the student in the database
        await DatabaseHelper.instance.registerStudent(
          email,
          password,
          nis,
          nisn,
          studentName,
          jenisKelamin,
          kelas,
        );
      }
    } catch (e) {
      print('Error loading CSV data: $e');
    }
  }
}

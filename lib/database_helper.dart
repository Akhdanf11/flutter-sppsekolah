  import 'package:sqflite/sqflite.dart';
  import 'package:path/path.dart';

  class DatabaseHelper {
    static final DatabaseHelper instance = DatabaseHelper._init();
    static Database? _database;

    DatabaseHelper._init();

    Future<Database> get database async {
      if (_database != null) return _database!;
      _database = await _initDB('app_database.db');
      return _database!;
    }

    Future<Database> _initDB(String filePath) async {
      final dbPath = join(await getDatabasesPath(), filePath);
      return await openDatabase(dbPath, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
    }

    Future<void> _createDB(Database db, int version) async {
      print("Creating tables");

      await db.execute('''
    CREATE TABLE IF NOT EXISTS students (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      email TEXT NOT NULL UNIQUE, 
      password TEXT NOT NULL, 
      nis TEXT NOT NULL UNIQUE, 
      nisn TEXT,  -- New NISN column
      student_name TEXT NOT NULL, 
      jenis_kelamin TEXT,  -- New gender column
      kelas TEXT,  -- New class section column
      va_number TEXT, 
      spp_amount REAL, 
      spp_paid REAL, 
      amount_due REAL,
      is_active INTEGER DEFAULT 1  -- Add active status
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS staff (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      email TEXT NOT NULL UNIQUE, 
      password TEXT NOT NULL, 
      nip TEXT NOT NULL UNIQUE, 
      name TEXT NOT NULL
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      nis TEXT, 
      payment_month INTEGER, 
      payment_year INTEGER, 
      payment_amount REAL, 
      payment_date TEXT, 
      va_number TEXT, 
      FOREIGN KEY(nis) REFERENCES students(nis)
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS standard_amount (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      amount REAL NOT NULL
    )
  ''');

      print("Tables created");
    }

    Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
      print("Upgrading database from version $oldVersion to $newVersion");

      if (oldVersion < 4) {
        // Add new columns to students table in version 4
        await db.execute('ALTER TABLE students ADD COLUMN nisn TEXT');
        await db.execute('ALTER TABLE students ADD COLUMN jenis_kelamin TEXT');
        await db.execute('ALTER TABLE students ADD COLUMN kelas TEXT');
      }
    }

    Future<String> generateVaNumber(String nis) async {
      final db = await database;
      final year = DateTime.now().year.toString();

      final result = await db.rawQuery(
        'SELECT MAX(CAST(SUBSTR(va_number, 1, INSTR(va_number, "-") - 1) AS INTEGER)) AS max_increment '
            'FROM students WHERE va_number LIKE "%-$nis-$year"',
      );

      int increment = 1;
      if (result.isNotEmpty) {
        final maxIncrement = result.first['max_increment'] as int?;
        increment = (maxIncrement ?? 0) + 1;
      }

      final formattedIncrement = increment.toString().padLeft(3, '0');
      return '$formattedIncrement-$nis-$year';
    }

    Future<List<Map<String, dynamic>>> getAllStudents() async {
      final db = await instance.database;
      final result = await db.rawQuery('''
    SELECT students.nis, 
           students.student_name, 
           students.spp_paid, 
           payments.payment_amount AS total_paid, 
           payments.payment_date, 
           students.nisn, 
           students.email, 
           students.jenis_kelamin, 
           students.kelas
    FROM students
    LEFT JOIN payments ON students.nis = payments.nis
  ''');
      return result;
    }


    Future<Map<String, dynamic>?> getStudentById(int id) async {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'students',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    }

    Future<Map<String, dynamic>?> getStudentData(String nis) async {
      final db = await instance.database;
      final result = await db.rawQuery('''
      SELECT s.nis, s.student_name, s.amount_due, COALESCE(SUM(p.payment_amount), 0) AS total_paid, 
             MAX(p.payment_date) AS payment_date, s.va_number, s.spp_amount, s.spp_paid, p.payment_month
      FROM students s
      LEFT JOIN payments p ON s.nis = p.nis
      WHERE s.nis = ?
      GROUP BY s.nis
    ''', [nis]);

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    }



    Future<void> setStudentSPPAmount(int studentId, double amount) async {
      final db = await instance.database;
      try {
        await db.update(
          'students',
          {'spp_amount': amount},
          where: 'id = ?',
          whereArgs: [studentId],
        );
      } catch (e) {
        print('Error setting SPP amount: $e');
      }
    }

    Future<void> printAllStudents() async {
      final students = await getAllStudents();
      print("All students: $students");
    }

    Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
      final db = await database;
      return await db.query(table, where: where, whereArgs: whereArgs);
    }

    Future<void> registerStudent(
        String email,
        String password,
        String nis,
        String nisn,
        String studentName,
        String gender,
        String classSection,
        ) async {
      final db = await database;

      if (db == null) {
        throw Exception('Database not initialized');
      }

      // Generate VA number based on NIS
      final vaNumber = await generateVaNumber(nis);

      // Initial SPP values
      final initialSppAmount = 100000.0;
      final initialAmountDue = initialSppAmount;

      await db.insert(
        'students',
        {
          'email': email,
          'password': password,
          'nis': nis,
          'nisn': nisn, // New column for NISN
          'student_name': studentName,
          'va_number': vaNumber,
          'spp_amount': initialSppAmount,
          'spp_paid': 0.0,
          'amount_due': initialAmountDue,
          'jenis_kelamin': gender, // New column for gender
          'kelas': classSection, // New column for class section
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // Avoid overwriting existing data
      );

      print('Student registered: NIS: $nis, VA: $vaNumber, Amount Due: $initialAmountDue');
    }

    Future<void> registerStaff(String email, String password, String name, String nip) async {
      final db = await database;
      try {
        if (email.isNotEmpty && password.isNotEmpty && nip.isNotEmpty && name.isNotEmpty) {
          await db.insert('staff', {
            'email': email,
            'password': password,
            'name': name,
            'nip': nip,
          });
        } else {
          throw Exception("Invalid input data for staff registration");
        }
      } catch (e) {
        print('Error registering staff: $e');
      }
    }

    Future<Map<String, dynamic>?> getStaffByEmail(String email) async {
      final db = await instance.database;
      try {
        final result = await db.query(
          'staff',
          where: 'email = ?',
          whereArgs: [email],
        );

        if (result.isNotEmpty) {
          return result.first;
        } else {
          print('Staff not found');
          return null;
        }
      } catch (e) {
        print('Error fetching staff by email: $e');
        return null;
      }
    }

    Future<void> updateStaffPassword(String email, String newPassword) async {
      final db = await instance.database;
      try {
        await db.update(
          'staff',
          {'password': newPassword},
          where: 'email = ?',
          whereArgs: [email],
        );
      } catch (e) {
        print('Error updating staff password: $e');
      }
    }

    Future<bool> isEmailTaken(String email) async {
      final db = await _database;
      if (db == null) {
        print('Database is not initialized');
        return false;
      }

      final result = await db.query(
        'students',
        where: 'email = ?',
        whereArgs: [email],
      );
      return result.isNotEmpty;
    }

    Future<List<Map<String, dynamic>>> getStudentsByClass(String studentClass) async {
      final db = await instance.database;

      // Query the students table by class
      final List<Map<String, dynamic>> result = await db.query(
        'students',
        where: 'kelas = ?',
        whereArgs: [studentClass],
      );

      return result;
    }

    Future<Map<String, dynamic>?> loginStudent(String email, String password) async {
      final db = await database;
      if (db == null) {
        print('Database is not initialized');
        return null;
      }

      try {
        final result = await db.query(
          'students',
          where: 'email = ? AND password = ? AND is_active = 1', // Ensure student is active
          whereArgs: [email, password],
        );

        if (result.isNotEmpty) {
          return result.first; // Return the first matching student record
        } else {
          print('Student not found, incorrect password, or account is not active');
          return null;
        }
      } catch (e) {
        print('Error logging in student: $e');
        return null;
      }
    }


    Future<Map<String, dynamic>?> loginStaff(String email, String password) async {
      final db = await database;
      if (db == null) {
        print('Database is not initialized');
        return null;
      }

      try {
        final result = await db.query(
          'staff',
          where: 'email = ? AND password = ?',
          whereArgs: [email, password],
        );

        if (result.isNotEmpty) {
          return result.first;
        } else {
          print('Staff not found or password incorrect');
          return null;
        }
      } catch (e) {
        print('Error logging in staff: $e');
        return null;
      }
    }

    Future<void> updateStudentPaymentDetails(
        String nis,
        double amount,
        String vaNumber,
        int month,
        int year,
        ) async {
      final db = await database;
      final paymentDate = DateTime(year, month).toIso8601String();

      // Check if a record already exists for this nis, month, and year
      final existingPayments = await db.query(
        'payments',
        where: 'nis = ? AND payment_month = ? AND payment_year = ?',
        whereArgs: [nis, month, year],
      );

      if (existingPayments.isNotEmpty) {
        // Update existing record
        await db.update(
          'payments',
          {
            'payment_amount': amount,
            'va_number': vaNumber,
            'payment_date': paymentDate,
          },
          where: 'nis = ? AND payment_month = ? AND payment_year = ?',
          whereArgs: [nis, month, year],
        );
      } else {
        // Insert new record
        await db.insert(
          'payments',
          {
            'nis': nis,
            'payment_month': month,
            'payment_year': year,
            'payment_amount': amount,
            'payment_date': paymentDate,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    Future<void> updatePaymentDetailsByNis(
        String nis,
        double amount,
        String vaNumber,
        int paymentMonth,
        int paymentYear
        ) async {
      final db = await instance.database;

      await db.insert(
        'payments',
        {
          'nis': nis,                       // Student's NIS
          'payment_amount': amount,          // Payment amount
          'payment_month': paymentMonth,     // Payment month
          'payment_year': paymentYear,       // Payment year
          'payment_date': DateTime.now().toIso8601String(), // Current date as payment date
          'va_number': vaNumber,             // Virtual Account number
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // Replace if conflict
      );
    }

    Future<void> updateSppPaidStatus(String nis) async {
      final db = await instance.database;

      // Hitung total pembayaran siswa berdasarkan nis
      final totalPaidResult = await db.rawQuery(
        'SELECT SUM(payment_amount) as totalPaid FROM payments WHERE nis = ?',
        [nis],
      );

      // Pastikan nilai totalPaid di-cast ke tipe double
      final totalPaid = totalPaidResult.isNotEmpty
          ? (double.tryParse(totalPaidResult.first['totalPaid'].toString()) ?? 0.0)
          : 0.0;

      // Ambil jumlah standar yang harus dibayar dari tabel standard_amount
      final standardAmountResult = await db.query('standard_amount', limit: 1);

      // Pastikan nilai standardAmount di-cast ke tipe double
      final standardAmount = standardAmountResult.isNotEmpty
          ? (double.tryParse(standardAmountResult.first['amount'].toString()) ?? 0.0)
          : 0.0;

      // Jika total yang dibayarkan lebih besar atau sama dengan jumlah standar, anggap SPP sudah dibayar
      int sppPaid = totalPaid >= standardAmount ? 1 : 0;

      // Perbarui kolom spp_paid di tabel students berdasarkan NIS
      await db.update(
        'students',
        {
          'spp_paid': sppPaid, // 1 jika sudah dibayar, 0 jika belum
        },
        where: 'nis = ?',
        whereArgs: [nis],
      );
    }


    Future<double?> getStandardAmount(String nis) async {
      final db = await instance.database;
      final result = await db.query(
        'students',
        columns: ['amount_due'],
        where: 'nis = ?',
        whereArgs: [nis],
      );

      if (result.isNotEmpty) {
        return result.first['amount_due'] as double?;
      }
      return null;
    }

    Future<void> updateAmountDue(String nis, double amount) async {
      final db = await instance.database;
      await db.update(
        'students',
        {'amount_due': amount},
        where: 'nis = ?',
        whereArgs: [nis],
      );
    }

    Future<List<Map<String, dynamic>>> getPaymentByMonth(String nis, int month, int year) async {
      final db = await instance.database;
      try {
        final result = await db.query(
          'payments',
          where: 'nis = ? AND payment_month = ? AND payment_year = ?',
          whereArgs: [nis, month, year],
        );
        return result;
      } catch (e) {
        print('Error fetching payment by month: $e');
        return [];
      }
    }


    Future<void> updatePaymentDetails(
        String nis,
        double amount,
        String vaNumber,
        int month,
        int year,
        ) async {
      final db = await database;
      final paymentDate = DateTime(year, month).toIso8601String();

      // Check if a record already exists for this nis, month, and year
      final existingPayments = await db.query(
        'payments',
        where: 'nis = ? AND payment_month = ? AND payment_year = ?',
        whereArgs: [nis, month, year],
      );

      if (existingPayments.isNotEmpty) {
        // Update existing record
        await db.update(
          'payments',
          {
            'payment_amount': amount,
            'va_number': vaNumber,
            'payment_date': paymentDate,
          },
          where: 'nis = ? AND payment_month = ? AND payment_year = ?',
          whereArgs: [nis, month, year],
        );
      } else {
        // Insert new record
        await db.insert(
          'payments',
          {
            'nis': nis,
            'payment_month': month,
            'payment_year': year,
            'payment_amount': amount,
            'va_number': vaNumber,
            'payment_date': paymentDate,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    Future<List<Map<String, dynamic>>> getPaymentHistoryByNis(String nis) async {
      final db = await database;
      try {
        final result = await db.rawQuery(
          '''
        SELECT p.nis, p.payment_amount, p.payment_date, s.va_number, p.payment_month, s.student_name
        FROM payments p
        JOIN students s ON p.nis = s.nis
        WHERE p.nis = ?
        ORDER BY p.payment_date DESC
        ''',
          [nis],
        );
        print('Payment history result: $result');
        return result;
      } catch (e) {
        print('Error fetching payment history by NIS: $e');
        return [];
      }
    }

  }

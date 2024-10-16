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
          spp_amount REAL,  -- Jumlah SPP per siswa
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

      if (oldVersion >= 4 && newVersion == 5) {
        // Drop the standard_amount table in version 5
        await db.execute('DROP TABLE IF EXISTS standard_amount');
      }
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

      final year = DateTime.now().year.toString();

      // Find the max increment for the current year
      final result = await db.rawQuery(
        'SELECT MAX(CAST(SUBSTR(va_number, 1, INSTR(va_number, "-") - 1) AS INTEGER)) as max_increment '
            'FROM students WHERE va_number LIKE "%-$nisn-$year"',
      );

      final vaNumber = '$nisn-$year';

      // Initial SPP values
      final initialSppAmount = 100000.0;
      final initialAmountDue = initialSppAmount;

      await db.insert(
        'students',
        {
          'email': email,
          'password': password,
          'nis': nis,
          'nisn': nisn,
          'student_name': studentName,
          'va_number': vaNumber,
          'spp_amount': initialSppAmount,
          'spp_paid': 0.0,
          'amount_due': initialAmountDue,
          'jenis_kelamin': gender,
          'kelas': classSection,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
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
      final db = await DatabaseHelper.instance.database;

      // Verify class value
      print('Querying students with class: $studentClass');

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
          // Ensure student is active
          where: 'email = ? AND password = ? AND is_active = 1',
          whereArgs: [email, password],
        );

        if (result.isNotEmpty) {
          // Return the first matching student record
          return result.first;
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
          'nis': nis,
          'payment_amount': amount,
          'payment_month': paymentMonth,
          'payment_year': paymentYear,
          'payment_date': DateTime.now().toIso8601String(),
          'va_number': vaNumber,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    Future<void> updateSppPaidStatus(String nis) async {
      final db = await instance.database;

      // Hitung total pembayaran siswa berdasarkan NIS
      final totalPaidResult = await db.rawQuery(
        'SELECT SUM(payment_amount) as totalPaid FROM payments WHERE nis = ?',
        [nis],
      );

      // Pastikan nilai totalPaid di-cast ke tipe double
      final totalPaid = totalPaidResult.isNotEmpty
          ? (double.tryParse(totalPaidResult.first['totalPaid'].toString()) ?? 0.0)
          : 0.0;

      // Ambil jumlah SPP yang harus dibayar dari tabel students berdasarkan NIS
      final studentResult = await db.query(
        'students',
        columns: ['spp_amount'],
        where: 'nis = ?',
        whereArgs: [nis],
        limit: 1,
      );

      // Pastikan nilai spp_amount di-cast ke tipe double
      final sppAmount = studentResult.isNotEmpty
          ? (double.tryParse(studentResult.first['spp_amount'].toString()) ?? 0.0)
          : 0.0;

      // Jika total yang dibayarkan lebih besar atau sama dengan jumlah SPP, anggap SPP sudah dibayar
      int sppPaid = totalPaid >= sppAmount ? 1 : 0;

      // Perbarui kolom spp_paid di tabel students berdasarkan NIS
      await db.update(
        'students',
        {
          // 1 jika sudah dibayar, 0 jika belum
          'spp_paid': sppPaid,
        },
        where: 'nis = ?',
        whereArgs: [nis],
      );
    }


    // Add this method to update a student's SPP amount
    Future<void> updateSppAmount(String nis, double newAmount) async {
      final db = await database;

      // Calculate new amount due
      final result = await db.rawQuery('SELECT spp_paid FROM students WHERE nis = ?', [nis]);

      if (result.isNotEmpty) {
        // Cast the value to double
        double sppPaid = (result.first['spp_paid'] as num?)?.toDouble() ?? 0.0;

        double newAmountDue = newAmount - sppPaid;

        // Update SPP amount and amount_due
        await db.update(
          'students',
          {
            'spp_amount': newAmount,
            'amount_due': newAmountDue,
          },
          where: 'nis = ?',
          whereArgs: [nis],
        );
      }
    }

// This method can be used to fetch the current SPP amount
    Future<Map<String, dynamic>?> getSppAmount(String nis) async {
      final db = await instance.database;
      final result = await db.rawQuery('''
    SELECT spp_amount, spp_paid, amount_due 
    FROM students 
    WHERE nis = ?
  ''', [nis]);

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    }

    Future<void> updateAllSppAmounts(double newAmount) async {
      final db = await database;

      await db.transaction((txn) async {
        await txn.update(
          'students',
          {'amount_due': newAmount},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
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

    Future<List<Map<String, dynamic>>> getStudentRecapByClass() async {
      final db = await database;

      // Query to get the student recap by class
      final result = await db.rawQuery('''
    SELECT 
      kelas, 
      SUM(CASE WHEN jenis_kelamin = 'Laki-Laki' THEN 1 ELSE 0 END) as jumlahL, 
      SUM(CASE WHEN jenis_kelamin = 'Perempuan' THEN 1 ELSE 0 END) as jumlahP 
    FROM students 
    GROUP BY kelas
  ''');

      List<Map<String, dynamic>> modifiableResult = [];

      // Process each class and calculate totals
      for (var row in result) {
        final jumlahL = row['jumlahL'] as int? ?? 0;
        final jumlahP = row['jumlahP'] as int? ?? 0;
        final totalKelas = jumlahL + jumlahP;

        // Add the class-specific row
        modifiableResult.add({
          'kelas': row['kelas'],
          'jumlahL': jumlahL,
          'jumlahP': jumlahP,
          'totalKelas': totalKelas,
        });
      }

      // Calculate overall totals for each grade
      final overallTotals = await db.rawQuery('''
    SELECT 
      SUBSTR(kelas, 1, INSTR(kelas, '-') - 1) AS gradeCategory, 
      SUM(CASE WHEN jenis_kelamin = 'Laki-Laki' THEN 1 ELSE 0 END) as totalL, 
      SUM(CASE WHEN jenis_kelamin = 'Perempuan' THEN 1 ELSE 0 END) as totalP, 
      COUNT(*) as totalPerGrade
    FROM students 
    GROUP BY gradeCategory
  ''');

      // Add rows for overall totals by grade category (e.g., VII Total, VIII Total, IX Total)
      for (var row in overallTotals) {
        final totalL = row['totalL'] as int? ?? 0;
        final totalP = row['totalP'] as int? ?? 0;
        final totalPerGrade = totalL + totalP;

        modifiableResult.add({
          'kelas': '${row['gradeCategory']} Total',
          'jumlahL': totalL,
          'jumlahP': totalP,
          'totalKelas': totalPerGrade,
        });
      }

      // Calculate grand totals (overall totals for all grades combined)
      final grandTotals = await db.rawQuery('''
    SELECT 
      SUM(CASE WHEN jenis_kelamin = 'Laki-Laki' THEN 1 ELSE 0 END) as totalL, 
      SUM(CASE WHEN jenis_kelamin = 'Perempuan' THEN 1 ELSE 0 END) as totalP,
      COUNT(*) as keseluruhan 
    FROM students
  ''');

      if (grandTotals.isNotEmpty) {
        final totalRow = grandTotals.first;
        final totalL = totalRow['totalL'] as int? ?? 0;
        final totalP = totalRow['totalP'] as int? ?? 0;
        final keseluruhan = totalRow['keseluruhan'] as int? ?? 0;

        // Add the final grand total row
        modifiableResult.add({
          'kelas': 'Keseluruhan Total',
          'jumlahL': totalL,
          'jumlahP': totalP,
          'totalKelas': keseluruhan,
        });
      }

      return modifiableResult;
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

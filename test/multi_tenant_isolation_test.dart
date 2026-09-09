import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/database/app_database.dart';
import 'package:life_hub/core/database/finance_dao.dart';
import 'package:life_hub/core/database/habits_dao.dart';
import 'package:life_hub/core/database/tasks_dao.dart';
import 'package:life_hub/core/database/wallets_dao.dart';
import 'package:life_hub/features/finance/models/finance_transaction.dart';
import 'package:life_hub/features/finance/models/wallet.dart';
import 'package:life_hub/features/habits/models/habit.dart';
import 'package:life_hub/features/tasks/models/task_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Multi-Tenant Database Session Isolation Suite', () {
    late Database db;
    late WalletsDao walletsDao;
    late FinanceDao financeDao;
    late TasksDao tasksDao;
    late HabitsDao habitsDao;

    setUp(() async {
      db = await AppDatabase.initInMemoryDatabase();
      walletsDao = WalletsDao();
      financeDao = FinanceDao();
      tasksDao = TasksDao();
      habitsDao = HabitsDao();
    });

    tearDown(() async {
      await db.close();
    });

    test('User A data is strictly invisible to User B across all local tables', () async {
      const userA = 'usr_naufal_123';
      const userB = 'usr_gordon_456';
      final now = DateTime.now();

      // 1. User A creates a wallet with Rp 900.000 balance
      final walletA = Wallet(
        id: 'wallet_alpha_01',
        userId: userA,
        name: 'Rekening Utama Naufal',
        iconCodePoint: 57534,
        colorHex: '#0284C7',
        balanceCents: 900000,
        isDefault: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      await walletsDao.insertWallet(walletA.toMap());

      // User A creates a transaction
      final txA = FinanceTransaction(
        id: 'tx_alpha_01',
        userId: userA,
        walletId: walletA.id,
        title: 'Gaji Bulanan',
        amountCents: 900000,
        type: TransactionType.income,
        category: 'Salary',
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );
      await financeDao.insertTransaction(txA.toMap());

      // User A creates a task
      final taskA = TaskItem(
        id: 'task_alpha_01',
        userId: userA,
        title: 'Review Project Architecture',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        category: 'Work',
        createdAt: now,
        updatedAt: now,
      );
      await tasksDao.insertTask(taskA.toMap());

      // User A creates a habit
      final habitA = Habit(
        id: 'habit_alpha_01',
        userId: userA,
        title: 'Morning Jogging',
        frequency: HabitFrequency.daily,
        category: HabitCategory.health,
        createdAt: now,
        updatedAt: now,
      );
      await habitsDao.insertHabit(habitA.toMap());

      // 2. Query as User B -> Must be completely empty
      final walletsB = await walletsDao.getAllWallets(userB);
      expect(walletsB, isEmpty, reason: 'User B must not see User A wallets');

      final defaultWalletB = await walletsDao.getDefaultWallet(userB);
      expect(defaultWalletB, isNull, reason: 'User B must not see User A default wallet');

      final txnsB = await financeDao.getAllTransactions(userB);
      expect(txnsB, isEmpty, reason: 'User B must not see User A transactions');

      final incomeB = await financeDao.getTotalIncomeCents(userId: userB);
      expect(incomeB, equals(0), reason: 'User B income must be 0');

      final tasksB = await tasksDao.getAllTasks(userB);
      expect(tasksB, isEmpty, reason: 'User B must not see User A tasks');

      final habitsB = await habitsDao.getActiveHabits(userB);
      expect(habitsB, isEmpty, reason: 'User B must not see User A habits');

      // 3. User B creates their own wallet and data
      final walletB = Wallet(
        id: 'wallet_beta_01',
        userId: userB,
        name: 'Rekening Gordon',
        iconCodePoint: 57534,
        colorHex: '#10B981',
        balanceCents: 150000,
        isDefault: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      await walletsDao.insertWallet(walletB.toMap());

      // Check User A still sees only User A
      final walletsA = await walletsDao.getAllWallets(userA);
      expect(walletsA.length, equals(1));
      expect(walletsA.first['id'], equals('wallet_alpha_01'));

      // Check User B sees only User B
      final walletsBUpdated = await walletsDao.getAllWallets(userB);
      expect(walletsBUpdated.length, equals(1));
      expect(walletsBUpdated.first['id'], equals('wallet_beta_01'));
      expect(walletsBUpdated.first['balance_cents'], equals(150000));
    });
  });

  group('Auth Error Message Parsing Suite', () {
    String parseAuthError(dynamic error) {
      if (error is AuthException) {
        final msg = error.message.toLowerCase();
        if (msg.contains('invalid login credentials') ||
            msg.contains('invalid credentials') ||
            msg.contains('user not found') ||
            msg.contains('wrong password') ||
            msg.contains('invalid password')) {
          return 'Email belum terdaftar atau kata sandi salah. Silakan periksa kembali atau buat akun baru.';
        }
        if (msg.contains('already registered') ||
            msg.contains('user already exists') ||
            msg.contains('email address already taken') ||
            msg.contains('already been taken')) {
          return 'Email sudah terdaftar. Silakan masuk.';
        }
        if (msg.contains('invalid email') || msg.contains('format')) {
          return 'Format email tidak valid.';
        }
        if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
          return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
        }
        return error.message;
      }

      final str = error.toString().toLowerCase();
      if (str.contains('no account found') ||
          str.contains('incorrect password') ||
          str.contains('invalid credentials') ||
          str.contains('credentials')) {
        return 'Email belum terdaftar atau kata sandi salah. Silakan periksa kembali atau buat akun baru.';
      }
      if (str.contains('already exists') || str.contains('already registered')) {
        return 'Email sudah terdaftar. Silakan masuk.';
      }
      if (str.contains('valid email')) {
        return 'Format email tidak valid.';
      }
      if (str.contains('socketexception') ||
          str.contains('network') ||
          str.contains('connection') ||
          str.contains('failed host lookup') ||
          str.contains('clientexception')) {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }

      return error.toString().replaceFirst('Exception: ', '');
    }

    test('Maps Supabase and local auth errors to clear user-friendly Indonesian messages', () {
      // 1. Invalid credentials
      final err1 = const AuthException('Invalid login credentials', statusCode: '400');
      expect(
        parseAuthError(err1),
        equals('Email belum terdaftar atau kata sandi salah. Silakan periksa kembali atau buat akun baru.'),
      );

      // 2. Already registered
      final err2 = const AuthException('User already registered', statusCode: '400');
      expect(
        parseAuthError(err2),
        equals('Email sudah terdaftar. Silakan masuk.'),
      );

      // 3. Invalid email format
      final err3 = const AuthException('Unable to validate email address: invalid format', statusCode: '400');
      expect(
        parseAuthError(err3),
        equals('Format email tidak valid.'),
      );

      // 4. Network error
      final err4 = Exception('ClientException: Failed host lookup: supabase.co');
      expect(
        parseAuthError(err4),
        equals('Gagal terhubung ke server. Periksa koneksi internet Anda.'),
      );
    });
  });
}

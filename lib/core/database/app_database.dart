import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_platform/db_platform.dart';

/// Platform-agnostic SQLite database engine for Life OS Life OS.
/// Supports Android, iOS, Windows, macOS, Linux, and Web seamlessly.
///
/// Schema version history:
///  v1: Initial schema (finance_transactions, tasks, secure_notes)
///  v2: Added location columns + vault_files + app_users
///  v3: Added is_verified, verification_code to app_users
///  v4: Added habits, habit_completions, focus_sessions, water_logs, mood_logs,
///      wallets, emergency_card; wallet_id on finance_transactions;
///      color_tag, is_archived on secure_notes
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  static const String _databaseName = 'life_hub_v2.db';
  static const int _databaseVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final factory = await getPlatformDatabaseFactory();
    final dbPath = await getPlatformDatabasePath(_databaseName);

    return await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          try {
            await db.execute('ALTER TABLE app_users ADD COLUMN phone_number TEXT;');
          } catch (_) {}
        },
      ),
    );
  }

  /// In-memory database initialization for unit and integration testing.
  static Future<Database> initInMemoryDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return await openDatabase(
      inMemoryDatabasePath,
      version: _databaseVersion,
      onCreate: instance._onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Finance Transactions
    await db.execute('''
      CREATE TABLE finance_transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        note TEXT,
        linked_task_id TEXT,
        wallet_id TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_finance_timestamp ON finance_transactions(timestamp)');
    await db.execute('CREATE INDEX idx_finance_type ON finance_transactions(type)');
    await db.execute('CREATE INDEX idx_finance_wallet ON finance_transactions(wallet_id)');

    // 2. Tasks
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        due_date INTEGER,
        estimated_cost_cents INTEGER NOT NULL DEFAULT 0,
        is_expense_logged INTEGER NOT NULL DEFAULT 0,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');

    // 3. Secure Notes
    await db.execute('''
      CREATE TABLE secure_notes (
        id TEXT PRIMARY KEY,
        encrypted_title TEXT NOT NULL,
        encrypted_content TEXT NOT NULL,
        encrypted_tags TEXT NOT NULL,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        color_tag TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        note_type TEXT NOT NULL DEFAULT 'text',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_pinned ON secure_notes(is_pinned, updated_at DESC)');
    await db.execute('CREATE INDEX idx_notes_archived ON secure_notes(is_archived)');

    // 4. Vault Files
    await db.execute('''
      CREATE TABLE vault_files (
        id TEXT PRIMARY KEY,
        encrypted_file_name TEXT NOT NULL,
        encrypted_mime_type TEXT NOT NULL,
        relative_path TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        iv_base64 TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_vault_created ON vault_files(created_at DESC)');

    // 5. App Users
    await db.execute('''
      CREATE TABLE app_users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        display_name TEXT,
        photo_url TEXT,
        phone_number TEXT,
        auth_provider TEXT NOT NULL,
        password_hash TEXT,
        salt TEXT,
        is_verified INTEGER NOT NULL DEFAULT 1,
        verification_code TEXT,
        created_at INTEGER NOT NULL,
        last_login_at INTEGER NOT NULL
      )
    ''');

    // 6. Wallets (Multi-Wallet — Pillar 11)
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL DEFAULT 57534,
        color_hex TEXT NOT NULL DEFAULT '#0284C7',
        balance_cents INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Seed default wallet (Rekening Utama)
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('wallets', {
      'id': 'wallet_default',
      'name': 'Rekening Utama',
      'icon_code_point': 57534,
      'color_hex': '#0284C7',
      'balance_cents': 0,
      'is_default': 1,
      'sort_order': 0,
      'created_at': now,
      'updated_at': now,
    });

    // 7. Habits (Pillar 7)
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        frequency TEXT NOT NULL DEFAULT 'daily',
        category TEXT NOT NULL DEFAULT 'productivity',
        target_days TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        streak_current INTEGER NOT NULL DEFAULT 0,
        streak_longest INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_habits_active ON habits(is_active)');

    // 8. Habit Completions
    await db.execute('''
      CREATE TABLE habit_completions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        completed_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_completions_habit ON habit_completions(habit_id, completed_date DESC)');

    // 9. Focus Sessions (Pillar 8)
    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        duration_seconds INTEGER NOT NULL,
        break_type TEXT NOT NULL DEFAULT 'short',
        session_number INTEGER NOT NULL DEFAULT 1,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_focus_started ON focus_sessions(started_at DESC)');

    // 10. Water Logs (Pillar 9)
    await db.execute('''
      CREATE TABLE water_logs (
        id TEXT PRIMARY KEY,
        amount_ml INTEGER NOT NULL,
        daily_goal_ml INTEGER NOT NULL DEFAULT 2000,
        logged_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_water_logged ON water_logs(logged_at DESC)');

    // 11. Mood Logs (Pillar 9)
    await db.execute('''
      CREATE TABLE mood_logs (
        id TEXT PRIMARY KEY,
        mood_level INTEGER NOT NULL,
        note TEXT,
        logged_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_mood_logged ON mood_logs(logged_at DESC)');

    // 12. Emergency Card (Pillar 10) — Single row upsert pattern
    await db.execute('''
      CREATE TABLE emergency_card (
        id TEXT PRIMARY KEY DEFAULT 'singleton',
        blood_type TEXT,
        allergies TEXT,
        medical_notes TEXT,
        emergency_contacts_json TEXT NOT NULL DEFAULT '[]',
        owner_name TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE finance_transactions ADD COLUMN latitude REAL;');
      await db.execute('ALTER TABLE finance_transactions ADD COLUMN longitude REAL;');
      await db.execute('ALTER TABLE finance_transactions ADD COLUMN location_name TEXT;');
      await db.execute('ALTER TABLE tasks ADD COLUMN latitude REAL;');
      await db.execute('ALTER TABLE tasks ADD COLUMN longitude REAL;');
      await db.execute('ALTER TABLE tasks ADD COLUMN location_name TEXT;');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vault_files (
          id TEXT PRIMARY KEY,
          encrypted_file_name TEXT NOT NULL,
          encrypted_mime_type TEXT NOT NULL,
          relative_path TEXT NOT NULL,
          file_size_bytes INTEGER NOT NULL,
          iv_base64 TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_vault_created ON vault_files(created_at DESC)');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_users (
          id TEXT PRIMARY KEY,
          email TEXT NOT NULL,
          display_name TEXT,
          photo_url TEXT,
          auth_provider TEXT NOT NULL,
          password_hash TEXT,
          salt TEXT,
          is_verified INTEGER NOT NULL DEFAULT 1,
          verification_code TEXT,
          created_at INTEGER NOT NULL,
          last_login_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE app_users ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 1;'); } catch (_) {}
      try { await db.execute('ALTER TABLE app_users ADD COLUMN verification_code TEXT;'); } catch (_) {}
    }

    if (oldVersion < 4) {
      // Wallets table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL DEFAULT 57534,
          color_hex TEXT NOT NULL DEFAULT '#0284C7',
          balance_cents INTEGER NOT NULL DEFAULT 0,
          is_default INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      // Seed the default wallet
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('wallets', {
        'id': 'wallet_default',
        'name': 'Rekening Utama',
        'icon_code_point': 57534,
        'color_hex': '#0284C7',
        'balance_cents': 0,
        'is_default': 1,
        'sort_order': 0,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Add wallet_id to existing finance_transactions, migrating all to default
      try { await db.execute('ALTER TABLE finance_transactions ADD COLUMN wallet_id TEXT;'); } catch (_) {}
      await db.execute("UPDATE finance_transactions SET wallet_id = 'wallet_default' WHERE wallet_id IS NULL");

      // Add new columns to secure_notes
      try { await db.execute('ALTER TABLE secure_notes ADD COLUMN color_tag TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE secure_notes ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0;'); } catch (_) {}
      try { await db.execute("ALTER TABLE secure_notes ADD COLUMN note_type TEXT NOT NULL DEFAULT 'text';"); } catch (_) {}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_archived ON secure_notes(is_archived);'); } catch (_) {}

      // Habits
      await db.execute('''
        CREATE TABLE IF NOT EXISTS habits (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          frequency TEXT NOT NULL DEFAULT 'daily',
          category TEXT NOT NULL DEFAULT 'productivity',
          target_days TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
          streak_current INTEGER NOT NULL DEFAULT 0,
          streak_longest INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_active ON habits(is_active)');

      // Habit Completions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS habit_completions (
          id TEXT PRIMARY KEY,
          habit_id TEXT NOT NULL,
          completed_date INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_completions_habit ON habit_completions(habit_id, completed_date DESC)');

      // Focus Sessions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS focus_sessions (
          id TEXT PRIMARY KEY,
          task_id TEXT,
          duration_seconds INTEGER NOT NULL,
          break_type TEXT NOT NULL DEFAULT 'short',
          session_number INTEGER NOT NULL DEFAULT 1,
          started_at INTEGER NOT NULL,
          ended_at INTEGER,
          is_completed INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_started ON focus_sessions(started_at DESC)');

      // Water Logs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS water_logs (
          id TEXT PRIMARY KEY,
          amount_ml INTEGER NOT NULL,
          daily_goal_ml INTEGER NOT NULL DEFAULT 2000,
          logged_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_water_logged ON water_logs(logged_at DESC)');

      // Mood Logs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mood_logs (
          id TEXT PRIMARY KEY,
          mood_level INTEGER NOT NULL,
          note TEXT,
          logged_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_logged ON mood_logs(logged_at DESC)');

      // Emergency Card
      await db.execute('''
        CREATE TABLE IF NOT EXISTS emergency_card (
          id TEXT PRIMARY KEY DEFAULT 'singleton',
          blood_type TEXT,
          allergies TEXT,
          medical_notes TEXT,
          emergency_contacts_json TEXT NOT NULL DEFAULT '[]',
          owner_name TEXT,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Add wallet index on finance_transactions
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_finance_wallet ON finance_transactions(wallet_id)'); } catch (_) {}
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

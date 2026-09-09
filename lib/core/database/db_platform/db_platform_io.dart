import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<DatabaseFactory> getPlatformDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}

Future<String> getPlatformDatabasePath(String databaseName) async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final appSupportDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appSupportDir.path, 'LifeHub', databaseName);
    final dbDir = Directory(p.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return dbPath;
  } else {
    final databasesPath = await getDatabasesPath();
    return p.join(databasesPath, databaseName);
  }
}

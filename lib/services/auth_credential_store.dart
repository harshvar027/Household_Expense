import '../database/database_helper.dart';
import '../models/app_user_record.dart';

/// Persistence for the single local household auth account.
abstract class AuthCredentialStore {
  Future<bool> hasUser();
  Future<AppUserRecord?> readUser();
  Future<void> upsertUser(AppUserRecord user);
  Future<void> deleteUser();
}

/// Production store backed by the encrypted SQLite database.
class DatabaseAuthCredentialStore implements AuthCredentialStore {
  DatabaseAuthCredentialStore({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  @override
  Future<bool> hasUser() => _db.hasAppUser();

  @override
  Future<AppUserRecord?> readUser() => _db.getAppUser();

  @override
  Future<void> upsertUser(AppUserRecord user) => _db.upsertAppUser(user);

  @override
  Future<void> deleteUser() => _db.deleteAppUser();
}

/// In-memory store for unit tests.
class InMemoryAuthCredentialStore implements AuthCredentialStore {
  AppUserRecord? _user;

  @override
  Future<bool> hasUser() async => _user != null;

  @override
  Future<AppUserRecord?> readUser() async => _user;

  @override
  Future<void> upsertUser(AppUserRecord user) async {
    _user = user;
  }

  @override
  Future<void> deleteUser() async {
    _user = null;
  }
}

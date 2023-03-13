import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  final FlutterSecureStorage _storage;

  factory SecureStorage() => _instance;

  SecureStorage._internal()
      : _storage = FlutterSecureStorage(
          iOptions: const IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

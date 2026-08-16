import 'package:hive/hive.dart';

import '../models/session_model.dart';

/// Source de données locale d'authentification : persiste la session
/// JWT dans une boîte Hive afin qu'elle survive aux redémarrages.
class AuthLocalDataSource {
  AuthLocalDataSource(this._box);

  static const String _sessionKey = 'session';

  final Box<dynamic> _box;

  Future<void> saveSession(SessionModel session) =>
      _box.put(_sessionKey, session.toMap());

  SessionModel? readSession() {
    final raw = _box.get(_sessionKey);
    if (raw is! Map) return null;
    try {
      return SessionModel.fromMap(raw);
    } on Exception {
      return null;
    }
  }

  Future<void> clearSession() => _box.delete(_sessionKey);
}

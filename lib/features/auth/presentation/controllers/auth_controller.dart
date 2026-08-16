import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Contrôleur d'état de l'authentification (ChangeNotifier + provider).
class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  /// Restaure la session persistée au démarrage de l'application
  /// (avec refresh token si le jeton d'accès est expiré).
  Future<void> restoreSession() async {
    try {
      _user = await _repository.restoreSession();
      _status = AuthStatus.authenticated;
    } on Object {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _repository.register(name: name, email: email, password: password),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    _status = AuthStatus.unauthenticated;
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      _status = AuthStatus.authenticated;
      _busy = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
    } on Object {
      _error = 'Une erreur inattendue est survenue. Veuillez réessayer.';
    }
    _busy = false;
    notifyListeners();
    return false;
  }
}

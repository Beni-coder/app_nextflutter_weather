import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';

/// Backend d'authentification simulé (side "serveur").
///
/// OpenWeatherMap n'exposant aucune API d'authentification, ce backend
/// reproduit fidèlement le comportement d'un serveur REST d'authentification
/// JWT (register / login / refresh) : comptes persistés, mots de passe
/// salés et hachés (SHA-256), jetons JWT signés en HMAC-SHA256 avec
/// expiration, rotation des refresh tokens.
///
/// Il vit dans la couche data et est uniquement consommé par
/// [AuthRemoteDataSource], exactement comme un vrai serveur distant.
class AuthBackend {
  AuthBackend(
    this._usersBox, {
    String jwtSecret = 'certif-weather-app-jwt-secret-2026',
    Duration accessTokenTtl = const Duration(minutes: 30),
    Duration refreshTokenTtl = const Duration(days: 14),
  })  : _secret = jwtSecret,
        _accessTtl = accessTokenTtl,
        _refreshTtl = refreshTokenTtl;

  final Box<dynamic> _usersBox;
  final String _secret;
  final Duration _accessTtl;
  final Duration _refreshTtl;

  static final RegExp _emailRegExp = RegExp(
    r'^[\w.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
  );

  /// Inscrit un nouveau compte et renvoie une session fraîche.
  Future<SessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _simulateLatency();

    final normalizedEmail = email.trim().toLowerCase();
    _validateRegistration(
      name: name,
      email: normalizedEmail,
      password: password,
    );

    if (_usersBox.containsKey(normalizedEmail)) {
      throw const AuthException('Un compte existe déjà avec cet e-mail.');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final createdAt = DateTime.now();

    await _usersBox.put(normalizedEmail, {
      'email': normalizedEmail,
      'name': name.trim(),
      'salt': salt,
      'password_hash': passwordHash,
      'created_at': createdAt.millisecondsSinceEpoch,
    });

    return _createSession(
      UserModel(
        email: normalizedEmail,
        name: name.trim(),
        createdAt: createdAt,
      ),
    );
  }

  /// Connecte un utilisateur existant et renvoie une session fraîche.
  Future<SessionModel> login({
    required String email,
    required String password,
  }) async {
    await _simulateLatency();

    final normalizedEmail = email.trim().toLowerCase();
    final raw = _usersBox.get(normalizedEmail);

    if (raw is! Map) {
      throw const AuthException(
        'Aucun compte n\'est associé à cet e-mail. Créez d\'abord un compte.',
      );
    }

    final storedHash = raw['password_hash'] as String;
    final salt = raw['salt'] as String;
    if (_hashPassword(password, salt) != storedHash) {
      throw const AuthException('Mot de passe incorrect.');
    }

    return _createSession(UserModel.fromMap(raw));
  }

  /// Échange un refresh token valide contre une nouvelle session
  /// (rotation du refresh token).
  Future<SessionModel> refresh(String refreshToken) async {
    await _simulateLatency();

    final claims = decodeToken(refreshToken, expectedType: 'refresh');
    if (claims == null) {
      throw const AuthException(
        'Session expirée ou invalide. Veuillez vous reconnecter.',
      );
    }

    final email = claims['sub'] as String?;
    final raw = email == null ? null : _usersBox.get(email);
    if (raw is! Map) {
      throw const AuthException(
        'Session expirée ou invalide. Veuillez vous reconnecter.',
      );
    }

    return _createSession(UserModel.fromMap(raw));
  }

  /// Décode et valide un jeton (signature + type + expiration).
  /// Retourne les claims si le jeton est valide, sinon null.
  Map<String, dynamic>? decodeToken(
    String token, {
    required String expectedType,
  }) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final expectedSignature = _sign('${parts[0]}.${parts[1]}');
    if (!_constantTimeEquals(expectedSignature, parts[2])) return null;

    final Map<String, dynamic> claims;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      claims = jsonDecode(decoded) as Map<String, dynamic>;
    } on Exception {
      return null;
    }

    if (claims['typ'] != expectedType) return null;

    final exp = claims['exp'];
    if (exp is! int) return null;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    if (expiry.isBefore(DateTime.now())) return null;

    return claims;
  }

  // ---------------------------------------------------------------------
  // Jour JSON Web Tokens
  // ---------------------------------------------------------------------

  SessionModel _createSession(UserModel user) {
    final now = DateTime.now();
    final issuedAt = now.millisecondsSinceEpoch ~/ 1000;

    final accessToken = _issueJwt({
      'sub': user.email,
      'name': user.name,
      'typ': 'access',
      'jti': _generateSalt(),
      'iat': issuedAt,
      'exp': issuedAt + _accessTtl.inSeconds,
    });

    final refreshToken = _issueJwt({
      'sub': user.email,
      'typ': 'refresh',
      'jti': _generateSalt(),
      'iat': issuedAt,
      'exp': issuedAt + _refreshTtl.inSeconds,
    });

    return SessionModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessExpiresAt: now.add(_accessTtl),
      user: user,
    );
  }

  String _issueJwt(Map<String, dynamic> payload) {
    final header = _encodeSegment({'alg': 'HS256', 'typ': 'JWT'});
    final body = _encodeSegment(payload);
    final signature = _sign('$header.$body');
    return '$header.$body.$signature';
  }

  String _encodeSegment(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  String _sign(String data) => base64Url
      .encode(
        Hmac(sha256, utf8.encode(_secret)).convert(utf8.encode(data)).bytes,
      )
      .replaceAll('=', '');

  // ---------------------------------------------------------------------
  // Jour mots de passe
  // ---------------------------------------------------------------------

  String _generateSalt() {
    final random = Random.secure();
    final bytes =
        List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  // ---------------------------------------------------------------------
  // Validations (messages en français destinés à l'UI)
  // ---------------------------------------------------------------------

  void _validateRegistration({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.trim().isEmpty) {
      throw const AuthException('Veuillez saisir votre nom complet.');
    }
    if (!_emailRegExp.hasMatch(email)) {
      throw const AuthException('L\'adresse e-mail saisie est invalide.');
    }
    if (password.length < 6) {
      throw const AuthException(
        'Le mot de passe doit contenir au moins 6 caractères.',
      );
    }
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));
}

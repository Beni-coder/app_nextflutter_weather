import 'user_model.dart';

/// Modèle de sérialisation d'une session JWT (couche data).
class SessionModel {
  const SessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final UserModel user;

  factory SessionModel.fromMap(Map<dynamic, dynamic> map) => SessionModel(
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String,
        accessExpiresAt: DateTime.fromMillisecondsSinceEpoch(
          map['access_expires_at'] as int,
        ),
        user: UserModel.fromMap(map['user'] as Map<dynamic, dynamic>),
      );

  Map<String, dynamic> toMap() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'access_expires_at': accessExpiresAt.millisecondsSinceEpoch,
        'user': user.toMap(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModel &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.accessExpiresAt == accessExpiresAt &&
          other.user == user;

  @override
  int get hashCode =>
      Object.hash(accessToken, refreshToken, accessExpiresAt, user);
}

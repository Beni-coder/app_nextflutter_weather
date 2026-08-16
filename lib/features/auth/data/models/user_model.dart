import '../../domain/entities/app_user.dart';

/// Modèle de sérialisation d'un utilisateur (couche data).
class UserModel extends AppUser {
  const UserModel({
    required super.email,
    required super.name,
    super.createdAt,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    final createdAtRaw = map['created_at'];
    return UserModel(
      email: map['email'] as String,
      name: map['name'] as String,
      createdAt: createdAtRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        if (createdAt != null)
          'created_at': createdAt!.millisecondsSinceEpoch,
      };
}

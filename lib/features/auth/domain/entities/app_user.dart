/// Utilisateur authentifié de l'application.
class AppUser {
  const AppUser({
    required this.email,
    required this.name,
    this.createdAt,
  });

  final String email;
  final String name;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.email == email &&
          other.name == name &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(email, name, createdAt);

  @override
  String toString() => 'AppUser($email, $name)';
}

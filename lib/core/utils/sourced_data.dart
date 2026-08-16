/// Donnée renvoyée par un dépôt, accompagnée de sa provenance :
/// réseau (live) ou cache local (mode hors-ligne).
class SourcedData<T> {
  const SourcedData({
    required this.data,
    this.fromCache = false,
    this.fetchedAt,
  });

  final T data;

  /// true si la donnée provient du cache local plutôt que du réseau.
  final bool fromCache;

  /// Date à laquelle la donnée a été récupérée (utile en mode hors-ligne).
  final DateTime? fetchedAt;
}

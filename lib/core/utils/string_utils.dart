/// Met la première lettre d'une chaîne en majuscule (utile pour les
/// libellés français comme les jours de la semaine).
extension StringCapitalization on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

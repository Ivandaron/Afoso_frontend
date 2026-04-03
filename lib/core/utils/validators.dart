class Validators {
  Validators._();

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le téléphone est requis';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (!RegExp(r'^\d{8,15}$').hasMatch(cleaned)) {
      return 'Numéro de téléphone invalide (8-15 chiffres)';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return "L'email est requis";
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$').hasMatch(value.trim())) {
      return 'Adresse email invalide';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Le mot de passe est requis';
    if (value.length < 8) return 'Minimum 8 caractères';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Au moins une majuscule requise';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Au moins un chiffre requis';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty)
        return 'Veuillez confirmer votre mot de passe';
      if (value != password) return 'Les mots de passe ne correspondent pas';
      return null;
    };
  }

  static String? name(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    if (value.trim().length < 2) {
      return 'Minimum 2 caractères';
    }
    return null;
  }

  static String? city(String? value) => name(value, fieldName: 'La ville');
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) return "L'adresse est requise";
    if (value.trim().length < 5) return 'Adresse trop courte';
    return null;
  }
}

/// Calcul de la force du mot de passe (0-4)
int passwordStrength(String password) {
  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
  return score > 4 ? 4 : score;
}

String passwordStrengthLabel(int strength) {
  switch (strength) {
    case 0:
    case 1:
      return 'Très faible';
    case 2:
      return 'Faible';
    case 3:
      return 'Moyen';
    case 4:
      return 'Fort';
    default:
      return '';
  }
}

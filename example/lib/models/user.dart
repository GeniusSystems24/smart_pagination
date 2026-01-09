/// User model for contact/employee search examples
class User {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String department;
  final String role;
  final bool isOnline;
  final DateTime lastSeen;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.department,
    required this.role,
    this.isOnline = false,
    required this.lastSeen,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Country model for location selector examples
class Country {
  final String code;
  final String name;
  final String flag;
  final String dialCode;
  final String continent;

  const Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.continent,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

/// Tag model for tag selector examples
class Tag {
  final String id;
  final String name;
  final int color;
  final int usageCount;

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    this.usageCount = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

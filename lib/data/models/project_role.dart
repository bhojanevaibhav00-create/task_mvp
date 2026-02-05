enum ProjectRole {
  owner,
  admin,
  member,
}

extension ProjectRoleX on ProjectRole {
  /// ✅ Human-readable label (USED BY UI CHIPS)
  String get label {
    switch (this) {
      case ProjectRole.owner:
        return 'Owner';
      case ProjectRole.admin:
        return 'Admin';
      case ProjectRole.member:
        return 'Member';
    }
  }

  /// ✅ Convenience flags (USED FOR SAFETY CHECKS)
  bool get isOwner => this == ProjectRole.owner;
  bool get isAdmin => this == ProjectRole.admin;
  bool get isMember => this == ProjectRole.member;

  /// ✅ Database ↔ Enum conversion (SAFE)
  static ProjectRole fromString(String value) {
    return ProjectRole.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ProjectRole.member,
    );
  }
}
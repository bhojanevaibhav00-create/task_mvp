enum ProjectRole {
  owner,
  admin,
  member;

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

  static ProjectRole fromString(String value) {
    return ProjectRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectRole.member,
    );
  }
}

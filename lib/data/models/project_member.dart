/// Placeholder model for project membership.
/// This will map to the 'ProjectMembers' table in the database.
class ProjectMember {
  final int projectId;
  final int userId;
  final String role; // 'admin', 'editor', 'viewer'
  final DateTime joinedAt;

  ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });
}

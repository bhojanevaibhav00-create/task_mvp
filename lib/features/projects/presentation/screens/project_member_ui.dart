import 'package:task_mvp/data/models/user_model.dart';
import 'package:task_mvp/data/models/project_role.dart';

class ProjectMemberUI {
  final int projectId;
  final User user;
  final ProjectRole role;

  ProjectMemberUI({
    required this.projectId,
    required this.user,
    required this.role,
  });
}
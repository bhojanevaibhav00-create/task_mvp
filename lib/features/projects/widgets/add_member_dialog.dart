import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; // drift.Value साठी आवश्यक
import '../../../data/database/database.dart';
import '../../../core/providers/task_providers.dart';
// 🚀 हा इम्पोर्ट 'projectMembersProvider' आणि 'collaborationActionProvider' साठी अनिवार्य आहे
import '../../../core/providers/collaboration_providers.dart'; 

class AddMemberDialog extends ConsumerWidget {
  final int projectId;

  const AddMemberDialog({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.read(databaseProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Team Member', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: FutureBuilder<List<User>>(
          // डुप्लिकेट्स रोखण्यासाठी फक्त उपलब्ध युजर्सची यादी मिळवणे
          future: _getAvailableUsers(database, projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(
                child: Text("No new users available", style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.blue)),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(user.email ?? 'No email'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => _addMemberToProject(context, ref, user),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // --- १. डुप्लिकेट्स रोखण्याचे लॉजिक (Prevent Duplicates) ---
  Future<List<User>> _getAvailableUsers(AppDatabase db, int pId) async {
    // आधीच असलेल्या मेंबर्सची यादी मिळवणे
    final members = await (db.select(db.projectMembers)..where((t) => t.projectId.equals(pId))).get();
    final memberIds = members.map((m) => m.userId).toList();
    
    // जे युजर्स आधीच मेंबर नाहीत, फक्त त्यांनाच दाखवणे
    return (db.select(db.users)..where((t) => t.id.isNotIn(memberIds))).get();
  }

  // --- २. मेंबर ॲड करणे आणि Activity Log करणे ---
  Future<void> _addMemberToProject(BuildContext context, WidgetRef ref, User user) async {
    // collaborationActionProvider वापरल्यामुळे 'Activity Timeline' मध्ये आपोआप नोंद होईल
    await ref.read(collaborationActionProvider.notifier).addMember(
      projectId, 
      user.id, 
      'Member',
    );

    if (context.mounted) {
      // यशस्वीरित्या ॲड झाल्यावर Snackbar दाखवणे
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${user.name} added to project"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // १. डायलॉग बंद करणे
      Navigator.pop(context);
      
      // २. 'Project Members' स्क्रीन रिफ्रेश करण्यासाठी प्रोव्हायडर इनवॅलिडेट करणे
      ref.invalidate(projectMembersProvider(projectId));
    }
  }
}
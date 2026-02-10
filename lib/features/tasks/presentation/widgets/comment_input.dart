import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../data/database/database.dart';

class CommentInput extends ConsumerStatefulWidget {
  final int taskId;
  final int projectId;

  const CommentInput({
    super.key,
    required this.taskId,
    required this.projectId,
  });

  @override
  ConsumerState<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isMentioning = false;

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _showOverlay(List<User> members) {
    _hideOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 250,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -160), // Positions list above the input
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: members.isEmpty 
                ? const Center(child: Text("No members found", style: TextStyle(fontSize: 12, color: Colors.grey)))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final user = members[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12, 
                          child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 10)),
                        ),
                        title: Text(user.name, style: const TextStyle(fontSize: 13)),
                        onTap: () => _addMention(user.name),
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTextChanged(String text) {
    if (text.endsWith('@')) {
      setState(() => _isMentioning = true);
      // Fetch users (You can filter this by project members if preferred)
      final members = ref.read(allUsersProvider).value ?? [];
      _showOverlay(members);
    } else if (_isMentioning && (!text.contains('@') || text.endsWith(' '))) {
      setState(() => _isMentioning = false);
      _hideOverlay();
    }
  }

  void _addMention(String name) {
    final text = _controller.text;
    // Replace the trailing '@' with the mention
    final newText = text.substring(0, text.length - 1) + "@$name ";
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _hideOverlay();
    setState(() => _isMentioning = false);
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // ✅ NEW LOGIC: Save to Repository
    try {
      // Assuming a default user ID for the current session (e.g., 1)
      // In a real app, you'd get this from an AuthProvider
      const currentUserId = 1; 

      await ref.read(commentRepositoryProvider).addComment(
        taskId: widget.taskId,
        userId: currentUserId,
        content: text,
        projectId: widget.projectId,
      );

      _controller.clear();
      _hideOverlay();
      setState(() => _isMentioning = false);
      
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comment added"), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Comment Submit Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Write a comment... use @",
                  hintStyle: TextStyle(fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
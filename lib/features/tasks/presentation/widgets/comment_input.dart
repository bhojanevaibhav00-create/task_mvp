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
          offset: const Offset(0, -160), 
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
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
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
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
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _onTextChanged(String text) {
    // Basic logic: trigger if last char is '@'
    if (text.isNotEmpty && text.endsWith('@')) {
      setState(() => _isMentioning = true);
      final members = ref.read(allUsersProvider).value ?? [];
      _showOverlay(members);
    } else if (_isMentioning && (text.isEmpty || text.endsWith(' ') || !text.contains('@'))) {
      setState(() => _isMentioning = false);
      _hideOverlay();
    }
  }

  void _addMention(String name) {
    final text = _controller.text;
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

    try {
      const currentUserId = 1; // Default for Local MVP

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
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                maxLines: null,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  hintText: "Write a comment... use @",
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
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
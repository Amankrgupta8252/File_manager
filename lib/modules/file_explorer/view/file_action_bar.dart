import 'package:flutter/material.dart';

class FileActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onMove;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const FileActionBar({
    super.key,
    required this.selectedCount,
    required this.onShare,
    required this.onCopy,
    required this.onMove,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        // color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          _buildActionItem(Icons.share_outlined, "Share", onShare),

          _buildActionItem(Icons.copy_outlined, "Copy", onCopy),

          _buildActionItem(Icons.drive_file_move_outlined, "Move", onMove),

          _buildActionItem(Icons.edit_outlined, "Rename", onRename),

          _buildActionItem(
            Icons.delete_outline,
            "Delete",
            onDelete,
            // isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              // color: isDestructive ? Colors.red : Colors.black87,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                // color: isDestructive ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
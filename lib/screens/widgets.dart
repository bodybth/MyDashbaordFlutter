import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/theme_service.dart';

const kPrimary   = Color(0xFF667EEA);
const kSecondary = Color(0xFF764BA2);

// ── GradientAppBar ────────────────────────────────────────────────
// Theme toggle removed — now lives in Settings screen
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Watch theme so the gradient stays reactive to dark mode
    context.watch<ThemeService>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [kPrimary, kSecondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
      ),
      child: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
    );
  }
}

// ── GradientButton ────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  const GradientButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kPrimary, kSecondary]),
          borderRadius: BorderRadius.circular(12)),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, color: Colors.white) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      ),
    );
  }
}

// ── Category Manager ──────────────────────────────────────────────
void showCategoryManager({
  required BuildContext context,
  required String title,
  required List<AppCategory> categories,
  required void Function(AppCategory) onAdd,
  required void Function(String id) onDelete,
  bool allowDeleteAll = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategorySheet(
        title: title,
        categories: categories,
        onAdd: onAdd,
        onDelete: onDelete,
        allowDeleteAll: allowDeleteAll),
  );
}

class _CategorySheet extends StatefulWidget {
  final String title;
  final List<AppCategory> categories;
  final void Function(AppCategory) onAdd;
  final void Function(String) onDelete;
  final bool allowDeleteAll;
  const _CategorySheet({
    required this.title,
    required this.categories,
    required this.onAdd,
    required this.onDelete,
    required this.allowDeleteAll,
  });
  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _ctrl = TextEditingController();
  String _emoji = '📁';
  final _emojis = [
    '📁','⚡','🚀','💡','💧','🔧','🔥','📚',
    '🧪','🔬','🧲','📐','📏','🌡️','⚗️','🔋',
    '💻','📡','🛠️','🎯'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => _pickEmoji(context),
                child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(_emoji, style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                          hintText: 'Category name...',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
              const SizedBox(width: 8),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  onPressed: () {
                    if (_ctrl.text.trim().isEmpty) return;
                    widget.onAdd(AppCategory(name: _ctrl.text.trim(), emoji: _emoji));
                    setState(() { _ctrl.clear(); });
                  },
                  child: const Text('Add')),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.categories.length,
              itemBuilder: (_, i) {
                final cat = widget.categories[i];
                return ListTile(
                  leading: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(cat.name),
                  trailing: (widget.allowDeleteAll || widget.categories.length > 1)
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => showDialog(
                              context: context,
                              builder: (d) => AlertDialog(
                                title: const Text('Delete'),
                                content: Text('Delete "${cat.emoji} ${cat.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      onPressed: () { Navigator.pop(d); widget.onDelete(cat.id); setState(() {}); },
                                      child: const Text('Delete')),
                                ])))
                      : const Tooltip(message: 'Need at least 1', child: Icon(Icons.lock_outline, color: Colors.grey)),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _pickEmoji(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pick Emoji'),
          content: Wrap(
            spacing: 8, runSpacing: 8,
            children: _emojis.map((e) => GestureDetector(
              onTap: () { setState(() => _emoji = e); Navigator.pop(context); },
              child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: _emoji == e ? kPrimary.withOpacity(0.15) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text(e, style: const TextStyle(fontSize: 22))),
            )).toList(),
          ),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📝 Notes',
        actions: [
          IconButton(icon: const Icon(Icons.upload_file), onPressed: () => _showImportDialog(context)),
          IconButton(icon: const Icon(Icons.download), onPressed: () => _showExportDialog(context)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showNoteEditor(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          if (storage.notes.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notes_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No notes yet\nTap + to add one',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: storage.notes.length,
            itemBuilder: (ctx, i) => _NoteCard(note: storage.notes[i]),
          );
        },
      ),
    );
  }

  void _showNoteEditor(BuildContext context, [Note? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String branch = existing?.branch ?? 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'New Note' : 'Edit Note',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: branch,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: noteBranches
                    .map((b) => DropdownMenuItem(value: b, child: Text(branchLabels[b] ?? b)))
                    .toList(),
                onChanged: (v) => setState(() => branch = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: existing == null ? 'Save Note' : 'Update Note',
                  icon: Icons.save,
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final storage = context.read<StorageService>();
                    if (existing == null) {
                      storage.addNote(Note(
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        branch: branch,
                      ));
                    } else {
                      storage.updateNote(Note(
                        id: existing.id,
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        branch: branch,
                        date: existing.date,
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final json = context.read<StorageService>().exportData();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Data'),
        content: SizedBox(
          height: 200,
          child: TextField(
            controller: TextEditingController(text: json),
            maxLines: null,
            readOnly: true,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste your backup JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final result = context.read<StorageService>().importData(ctrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result == 'success' ? '✅ Data imported!' : '❌ $result'),
              ));
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(branchLabels[note.branch] ?? note.branch,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA))),
                ),
                const Spacer(),
                Text(DateFormat('MMM dd').format(note.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => storage.deleteNote(note.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(note.content, style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

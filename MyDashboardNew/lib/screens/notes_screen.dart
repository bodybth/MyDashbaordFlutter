import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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
          Consumer<StorageService>(
            builder: (_, storage, __) => IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Manage Categories',
              onPressed: () => showCategoryManager(
                context: context,
                title: 'Note Categories',
                categories: storage.noteCategories,
                onAdd: (cat) => storage.addNoteCategory(cat),
                onDelete: (id) => storage.deleteNoteCategory(id),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Import', onPressed: () => _showImportOptions(context)),
          IconButton(icon: const Icon(Icons.download), tooltip: 'Export', onPressed: () => _showExportOptions(context)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showNoteEditor(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          if (storage.notes.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notes_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No notes yet\nTap + to add one', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]));
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

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF667EEA).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.share, color: Color(0xFF667EEA))),
        title: const Text('Save / Share as JSON file'),
        subtitle: const Text('Save to Downloads or share via app'),
        onTap: () { Navigator.pop(context); _exportAsFile(context); },
      ),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF764BA2).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.copy, color: Color(0xFF764BA2))),
        title: const Text('Copy JSON to clipboard'),
        subtitle: const Text('Paste it anywhere manually'),
        onTap: () { Navigator.pop(context); _exportAsCopy(context); },
      ),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _exportAsFile(BuildContext context) async {
    final json = context.read<StorageService>().exportData();
    final filename = 'dashboard-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], subject: 'Dashboard Backup');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    }
  }

  void _exportAsCopy(BuildContext context) {
    final json = context.read<StorageService>().exportData();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [Icon(Icons.copy, color: Color(0xFF667EEA)), SizedBox(width: 8), Text('Copy JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Tap Copy to copy all data:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 150, child: TextField(controller: TextEditingController(text: json), maxLines: null, readOnly: true,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'), decoration: const InputDecoration(border: OutlineInputBorder()))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy), label: const Text('Copy All'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: json));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)));
          },
        ),
      ],
    ));
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Import Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF667EEA).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder_open, color: Color(0xFF667EEA))),
        title: const Text('Pick JSON file'),
        subtitle: const Text('Browse and select your backup file'),
        onTap: () { Navigator.pop(context); _importFromFile(context); },
      ),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF764BA2).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.paste, color: Color(0xFF764BA2))),
        title: const Text('Paste JSON text'),
        subtitle: const Text('Paste copied backup text manually'),
        onTap: () { Navigator.pop(context); _importFromPaste(context); },
      ),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      String json;
      if (file.bytes != null) { json = String.fromCharCodes(file.bytes!); }
      else if (file.path != null) { json = await File(file.path!).readAsString(); }
      else { throw Exception('Could not read file'); }
      if (context.mounted) _confirmAndImport(context, json);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    }
  }

  void _importFromPaste(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.paste, color: Color(0xFF667EEA)), SizedBox(width: 8), Text('Paste JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Paste your backup JSON below:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, maxLines: 8,
            decoration: const InputDecoration(hintText: 'Paste JSON here...', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload), label: const Text('Import'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
          onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            _confirmAndImport(context, ctrl.text.trim());
          },
        ),
      ],
    ));
  }

  void _confirmAndImport(BuildContext context, String json) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Confirm Import'),
      content: const Text('This will overwrite ALL current data.\n\nAre you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            final result = context.read<StorageService>().importData(json);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result == 'success' ? '✅ Imported!' : '❌ $result'), duration: const Duration(seconds: 3)));
          },
          child: const Text('Yes, overwrite'),
        ),
      ],
    ));
  }

  void _showNoteEditor(BuildContext context, [Note? existing]) {
    final storage = context.read<StorageService>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String branch = existing?.branch ?? (storage.noteCategories.isNotEmpty ? storage.noteCategories.first.id : 'general');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(existing == null ? 'New Note' : 'Edit Note', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Consumer<StorageService>(
              builder: (_, s, __) => DropdownButtonFormField<String>(
                value: s.noteCategories.any((c) => c.id == branch) ? branch : s.noteCategories.first.id,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: s.noteCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
                onChanged: (v) => setState(() => branch = v!),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: GradientButton(
              label: existing == null ? 'Save Note' : 'Update Note',
              icon: Icons.save,
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final s = context.read<StorageService>();
                if (existing == null) {
                  s.addNote(Note(title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), branch: branch));
                } else {
                  s.updateNote(Note(id: existing.id, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), branch: branch, date: existing.date));
                }
                Navigator.pop(ctx);
              },
            )),
          ]),
        ),
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
    final cat = storage.noteCategories.firstWhere((c) => c.id == note.branch,
        orElse: () => AppCategory(id: note.branch, name: note.branch, emoji: '📁'));
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF667EEA).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${cat.emoji} ${cat.name}', style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA))),
            ),
            const Spacer(),
            Text(DateFormat('MMM dd').format(note.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF667EEA), size: 16),
              onPressed: () {
                // find NotesScreen method via a helper approach
                _editNote(context, note);
              },
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
              onPressed: () => storage.deleteNote(note.id),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
          const SizedBox(height: 8),
          Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note.content, style: TextStyle(color: Colors.grey[700], fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  void _editNote(BuildContext context, Note note) {
    final storage = context.read<StorageService>();
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);
    String branch = note.branch;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Edit Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: storage.noteCategories.any((c) => c.id == branch) ? branch : storage.noteCategories.first.id,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: storage.noteCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
              onChanged: (v) => setState(() => branch = v!),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: GradientButton(
              label: 'Update Note', icon: Icons.save,
              onPressed: () {
                storage.updateNote(Note(id: note.id, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), branch: branch, date: note.date));
                Navigator.pop(ctx);
              },
            )),
          ]),
        ),
      ),
    );
  }
}

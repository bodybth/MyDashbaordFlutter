import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import 'widgets.dart';

// ─────────────────────────────────────────────────────────────────
// Sections available for selective JSON export / import
// ─────────────────────────────────────────────────────────────────
const _kSections = {
  'gpa':         '📊 GPA & Courses',
  'assignments': '📋 Assignments',
  'schedule':    '📅 Schedule',
  'library':     '📚 Library & Notes',
  'formulas':    '📐 Formulas',
  'priorities':  '🎯 Priority Labels',
};

// ─────────────────────────────────────────────────────────────────
// SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _latestVersion;   // non-null when a newer release is available
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _doUpdateCheck();
  }

  Future<void> _doUpdateCheck() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final v = await UpdateService.checkForUpdate();
    if (mounted) setState(() { _latestVersion = v; _checkingUpdate = false; });
  }

  // ── build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDark;

    return Scaffold(
      appBar: const GradientAppBar(title: '⚙️ Settings'),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Update banner — visible only when a newer version exists on GitHub
        if (_latestVersion != null) ...[
          _UpdateBanner(
            version: _latestVersion!,
            onDownload: UpdateService.openReleasesPage,
            onDismiss: () => setState(() => _latestVersion = null)),
          const SizedBox(height: 16),
        ],

        // ── Appearance ───────────────────────────────────────────
        _SectionHeader('🎨 Appearance'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: kPrimary),
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(isDark ? 'Currently dark' : 'Currently light'),
            value: isDark, activeColor: kPrimary,
            onChanged: (_) => context.read<ThemeService>().toggle())),
        const SizedBox(height: 20),

        // ── App Updates ──────────────────────────────────────────
        _SectionHeader('🔄 App Updates'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: _icon(Icons.system_update_rounded, Colors.green),
            title: const Text('Check for Updates', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_checkingUpdate
                ? 'Checking…'
                : _latestVersion != null
                    ? '🆕  v$_latestVersion available'
                    : 'App is up to date  ✓'),
            trailing: _checkingUpdate
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _checkingUpdate ? null : () async {
              await _doUpdateCheck();
              if (mounted && _latestVersion != null) _showUpdateDialog(_latestVersion!);
              else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You\'re on the latest version ✓')));
              }
            })),
        const SizedBox(height: 20),

        // ── Data Backup (JSON) ───────────────────────────────────
        _SectionHeader('💾 Data Backup'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            ListTile(
              leading: _icon(Icons.upload_rounded, kPrimary),
              title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Choose sections → save/share as JSON'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSectionPicker(isExport: true)),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: _icon(Icons.download_rounded, kSecondary),
              title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Choose sections → restore from JSON'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSectionPicker(isExport: false)),
          ])),
        const SizedBox(height: 12),

        // ── Media Backup (ZIP with manifest) ─────────────────────
        _SectionHeader('🖼️ Media Backup'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            ListTile(
              leading: _icon(Icons.photo_library_rounded, Colors.teal),
              title: const Text('Export Notes with Media', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Creates a ZIP: photos, PDFs + manifest so they reimport perfectly'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportNotesWithMedia()),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: _icon(Icons.folder_zip_rounded, Colors.orange),
              title: const Text('Import Notes with Media', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Restore notes + attachments from a media ZIP'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importNotesWithMedia()),
          ])),
        const SizedBox(height: 20),

        // ── Danger Zone ──────────────────────────────────────────
        _SectionHeader('⚠️ Danger Zone'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: _icon(Icons.delete_forever, Colors.red),
            title: const Text('Clear All Data',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
            subtitle: const Text('Permanently delete everything'),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: _confirmClear)),
        const SizedBox(height: 20),

        // ── About ────────────────────────────────────────────────
        _SectionHeader('ℹ️ About'),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) {
                // buildNumber = versionCode set by CI (e.g. 250227029)
                // This is the real unique build identifier — always shown to user
                final build = snap.hasData ? snap.data!.buildNumber : '…';
                return ListTile(
                  leading: const Icon(Icons.info_outline, color: kPrimary),
                  title: const Text('Build', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(build, style: const TextStyle(color: Colors.grey)));
              }),
            const Divider(height: 1, indent: 56),
            const ListTile(
              leading: Icon(Icons.school_outlined, color: kPrimary),
              title: Text('Engineering Student Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Built for students, by students')),
          ])),
      ]),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────
  Widget _icon(IconData i, Color c) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Icon(i, color: c));

  void _showUpdateDialog(String version) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.system_update_rounded, color: Colors.green),
        SizedBox(width: 10),
        Text('Update Available'),
      ]),
      content: Text('Version $version is available on GitHub.\n\nDownload it and tap Install — your data will be preserved.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () { Navigator.pop(ctx); UpdateService.openReleasesPage(); },
          child: const Text('Open GitHub Releases')),
      ]));
  }

  // ════════════════════════════════════════════════════════════════
  // MEDIA EXPORT
  //
  // ZIP structure produced:
  //
  //   manifest.json          ← note metadata + tells app where each file belongs
  //   files/
  //     <noteId>_<safeName>  ← the actual image or PDF
  //
  // manifest.json schema:
  // {
  //   "version": 1,
  //   "exportedAt": "ISO8601",
  //   "notes": [
  //     {
  //       "id": "abc123",
  //       "title": "My Note",
  //       "content": "note body text",
  //       "branch": "nb_notes",      ← which notebook section
  //       "date": "ISO8601",
  //       "attachments": [
  //         {
  //           "id": "att1",
  //           "name": "lecture.pdf",   ← original display name (preserved)
  //           "type": "pdf",           ← "image" | "pdf"
  //           "zipPath": "files/abc123_lecture.pdf"  ← path inside ZIP
  //         }
  //       ]
  //     }
  //   ]
  // }
  //
  // On import: manifest tells the app the title, content, branch, and for each
  // attachment its display name, type, and where to find the bytes inside the ZIP.
  // Files are extracted to private storage and Note is saved to StorageService
  // with the correct localPaths so it appears immediately in the UI.
  // ════════════════════════════════════════════════════════════════
  Future<void> _exportNotesWithMedia() async {
    final storage = context.read<StorageService>();
    final withMedia = storage.notes.where((n) => n.attachments.isNotEmpty).toList();

    if (withMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes with attachments found.')));
      return;
    }

    // Let user pick which notes to include
    final selected = await showDialog<List<Note>>(
        context: context,
        builder: (_) => _NotePickerDialog(notes: withMedia));
    if (selected == null || selected.isEmpty || !mounted) return;

    _showProgress('Building ZIP…');
    try {
      // Build an Archive in memory (correct API for archive package)
      final archive = Archive();
      final manifestNotes = <Map<String, dynamic>>[];
      int fileCount = 0;

      for (final note in selected) {
        final attEntries = <Map<String, dynamic>>[];

        for (final att in note.attachments) {
          final f = File(att.localPath);
          if (!await f.exists()) continue;

          // Safe internal filename: <noteId>_<sanitised original name>
          final safeName = att.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
          final zipPath  = 'files/${note.id}_$safeName';

          // Read bytes and add as ArchiveFile
          final bytes = await f.readAsBytes();
          archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
          fileCount++;

          attEntries.add({
            'id':      att.id,
            'name':    att.name,    // original display name
            'type':    att.type,
            'zipPath': zipPath,     // where to find it in the zip
          });
        }

        manifestNotes.add({
          'id':          note.id,
          'title':       note.title,
          'content':     note.content,
          'branch':      note.branch,
          'date':        note.date.toIso8601String(),
          'attachments': attEntries,
        });
      }

      if (fileCount == 0) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attachment files found on device.')));
        }
        return;
      }

      // Add manifest.json
      final manifestJson = jsonEncode({
        'version':    1,
        'exportedAt': DateTime.now().toIso8601String(),
        'notes':      manifestNotes,
      });
      final manifestBytes = utf8.encode(manifestJson);
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      // Encode archive → zip bytes → temp file → share
      final zipBytes = ZipEncoder().encode(archive)!;
      final tmpDir   = await getTemporaryDirectory();
      final date     = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final zipFile  = File('${tmpDir.path}/dashboard-notes-$date.zip');
      await zipFile.writeAsBytes(zipBytes);

      if (mounted) Navigator.pop(context); // close progress

      await Share.shareXFiles(
        [XFile(zipFile.path, mimeType: 'application/zip')],
        subject: 'Dashboard Notes + Media (${selected.length} notes, $fileCount files)');

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MEDIA IMPORT
  // Reads manifest.json from the ZIP, extracts each file to private
  // app storage at the correct localPath, then saves / updates the
  // Note in StorageService — so it appears in the UI immediately.
  // ════════════════════════════════════════════════════════════════
  Future<void> _importNotesWithMedia() async {
    // Step 1: pick zip file
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['zip'], withData: false);
    if (picked == null || picked.files.isEmpty) return;
    final zipPath = picked.files.first.path;
    if (zipPath == null || !mounted) return;

    // Step 2: read + parse manifest
    _showProgress('Reading ZIP…');
    Archive archive;
    List<Map<String, dynamic>> manifestNotes;
    try {
      final bytes = await File(zipPath).readAsBytes();
      archive = ZipDecoder().decodeBytes(bytes);

      final manifestEntry = archive.files.firstWhere(
          (f) => f.name == 'manifest.json',
          orElse: () => throw Exception(
              'No manifest.json found.\nThis ZIP was not exported by this app.'));

      final manifest = jsonDecode(
          utf8.decode(manifestEntry.content as List<int>)) as Map<String, dynamic>;
      manifestNotes = (manifest['notes'] as List)
          .map((n) => n as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Read failed: $e')));
      }
      return;
    }

    if (!mounted) { Navigator.pop(context); return; }
    Navigator.pop(context); // close reading progress

    // Step 3: show preview + confirm
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _ImportPreviewDialog(notesJson: manifestNotes));
    if (confirm != true || !mounted) return;

    // Step 4: extract files + restore notes
    _showProgress('Importing…');
    try {
      final storage  = context.read<StorageService>();
      final appDir   = await getApplicationDocumentsDirectory();
      final attachDir = Directory('${appDir.path}/note_attachments');
      if (!await attachDir.exists()) await attachDir.create(recursive: true);

      int notesImported = 0;
      int filesExtracted = 0;

      for (final noteJson in manifestNotes) {
        final attachmentsJson = noteJson['attachments'] as List;
        final restoredAttachments = <NoteAttachment>[];

        for (final attJson in attachmentsJson) {
          final zipInternalPath = attJson['zipPath'] as String;
          final originalName    = attJson['name']    as String;
          final attType         = attJson['type']    as String;
          final attId           = attJson['id']      as String;

          // Find file entry in archive
          ArchiveFile? entry;
          for (final f in archive.files) {
            if (f.name == zipInternalPath) { entry = f; break; }
          }
          if (entry == null) continue;
          final fileBytes = entry.content as List<int>;
          if (fileBytes.isEmpty) continue;

          // Write to private storage — filename is the last part of the zipPath
          final diskName  = zipInternalPath.split('/').last;
          final localPath = '${attachDir.path}/$diskName';
          await File(localPath).writeAsBytes(fileBytes);
          filesExtracted++;

          restoredAttachments.add(NoteAttachment(
              id: attId, name: originalName, type: attType, localPath: localPath));
        }

        // Rebuild Note with real local paths
        final note = Note(
          id:          noteJson['id']      as String,
          title:       noteJson['title']   as String,
          content:     noteJson['content'] as String,
          branch:      noteJson['branch']  as String,
          date:        DateTime.tryParse(noteJson['date'] as String) ?? DateTime.now(),
          attachments: restoredAttachments);

        // Update existing or add new
        final idx = storage.notes.indexWhere((n) => n.id == note.id);
        if (idx >= 0) storage.updateNote(note); else storage.addNote(note);
        notesImported++;
      }

      if (mounted) {
        Navigator.pop(context); // close importing progress
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ $notesImported note(s) imported with $filesExtracted file(s)'),
            duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  // ── Section picker for JSON export / import ──────────────────────
  void _showSectionPicker({required bool isExport}) {
    final selected = <String>{..._kSections.keys};
    showModalBottomSheet(
        context: context, isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dragHandle(),
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(children: [
                Text(isExport ? '📤 Export — Select Sections' : '📥 Import — Select Sections',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => ss(() => selected.length == _kSections.length
                      ? selected.clear() : selected.addAll(_kSections.keys)),
                  child: Text(selected.length == _kSections.length ? 'None' : 'All')),
              ])),
            const Divider(),
            ..._kSections.entries.map((e) => CheckboxListTile(
              value: selected.contains(e.key),
              title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
              activeColor: kPrimary,
              onChanged: (v) => ss(() => v! ? selected.add(e.key) : selected.remove(e.key)),
              controlAffinity: ListTileControlAffinity.leading)),
            const Divider(),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(width: double.infinity,
                child: GradientButton(
                  label: isExport ? 'Continue to Export' : 'Continue to Import',
                  icon: isExport ? Icons.upload : Icons.download,
                  onPressed: selected.isEmpty ? () {} : () {
                    Navigator.pop(ctx);
                    if (isExport) _showJsonExportOptions(selected);
                    else _showJsonImportOptions(selected);
                  }))),
          ]))));
  }

  void _showJsonExportOptions(Set<String> sections) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
      _dragHandle(),
      const Padding(padding: EdgeInsets.all(16),
          child: Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: _icon(Icons.share, kPrimary),
        title: const Text('Save / Share as JSON'),
        subtitle: const Text('Save to Downloads or share via app'),
        onTap: () { Navigator.pop(context); _jsonExportFile(sections); }),
      ListTile(
        leading: _icon(Icons.copy, kSecondary),
        title: const Text('Copy JSON to clipboard'),
        subtitle: const Text('Paste it anywhere manually'),
        onTap: () { Navigator.pop(context); _jsonExportCopy(sections); }),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _jsonExportFile(Set<String> sections) async {
    final json = context.read<StorageService>().exportData(sections: sections);
    final suf  = sections.length == _kSections.length ? 'full' : sections.join('-');
    final name = 'dashboard-$suf-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    try {
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')],
          subject: 'Dashboard Backup');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')));
    }
  }

  void _jsonExportCopy(Set<String> sections) {
    final json = context.read<StorageService>().exportData(sections: sections);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Row(children: [Icon(Icons.copy, color: kPrimary), SizedBox(width: 8), Text('Copy JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${sections.length} section(s):', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 150, child: TextField(
            controller: TextEditingController(text: json), maxLines: null,
            readOnly: true, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            decoration: const InputDecoration(border: OutlineInputBorder()))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(icon: const Icon(Icons.copy), label: const Text('Copy All'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: json));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 2)));
          }),
      ]));
  }

  void _showJsonImportOptions(Set<String> sections) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
      _dragHandle(),
      const Padding(padding: EdgeInsets.all(16),
          child: Text('Import Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: _icon(Icons.folder_open, kPrimary),
        title: const Text('Pick JSON file'),
        subtitle: const Text('Browse and select your backup file'),
        onTap: () { Navigator.pop(context); _jsonImportFile(sections); }),
      ListTile(
        leading: _icon(Icons.paste, kSecondary),
        title: const Text('Paste JSON text'),
        subtitle: const Text('Paste copied backup text manually'),
        onTap: () { Navigator.pop(context); _jsonImportPaste(sections); }),
      const SizedBox(height: 16),
    ])));
  }

  Future<void> _jsonImportFile(Set<String> sections) async {
    try {
      final r = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (r == null || r.files.isEmpty) return;
      final f = r.files.first;
      // utf8.decode preserves multi-byte chars (emojis, Arabic, etc.)
      // String.fromCharCodes would corrupt them by treating each byte as a codepoint
      final json = f.bytes != null ? utf8.decode(f.bytes!)
          : f.path != null ? await File(f.path!).readAsString(encoding: utf8)
          : throw Exception('Could not read file');
      if (mounted) _confirmJsonImport(json, sections);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')));
    }
  }

  void _jsonImportPaste(Set<String> sections) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.paste, color: kPrimary), SizedBox(width: 8), Text('Paste JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Paste backup JSON below:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, maxLines: 8,
            decoration: const InputDecoration(hintText: 'Paste here…', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton.icon(icon: const Icon(Icons.upload), label: const Text('Import'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () {
            if (ctrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            _confirmJsonImport(ctrl.text.trim(), sections);
          }),
      ]));
  }

  void _confirmJsonImport(String json, Set<String> sections) {
    final names = sections.map((k) => _kSections[k]!).join('\n• ');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Confirm Import'),
      content: Text('This will overwrite:\n\n• $names\n\nContinue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            final result = context.read<StorageService>().importData(json, sections: sections);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result == 'success' ? '✅ Imported!' : '❌ $result'),
                duration: const Duration(seconds: 3)));
          },
          child: const Text('Yes, overwrite')),
      ]));
  }

  void _confirmClear() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('⚠️ Clear All Data'),
      content: const Text('This will permanently delete everything.\n\nThis cannot be undone!'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(ctx);
            context.read<StorageService>().clearAll();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared.'), duration: Duration(seconds: 2)));
          },
          child: const Text('Delete Everything')),
      ]));
  }

  // ── small helpers ────────────────────────────────────────────────
  Widget _dragHandle() => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)));

  void _showProgress(String msg) {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(msg),
        ])));
  }
}

// ════════════════════════════════════════════════════════════════════
// NOTE PICKER DIALOG
// ════════════════════════════════════════════════════════════════════
class _NotePickerDialog extends StatefulWidget {
  final List<Note> notes;
  const _NotePickerDialog({required this.notes});
  @override State<_NotePickerDialog> createState() => _NotePickerDialogState();
}
class _NotePickerDialogState extends State<_NotePickerDialog> {
  late Set<String> _sel;
  @override void initState() { super.initState(); _sel = widget.notes.map((n) => n.id).toSet(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Select Notes to Export'),
    content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Text('${widget.notes.length} note(s) with attachments',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _sel.length == widget.notes.length
              ? _sel.clear() : _sel = widget.notes.map((n) => n.id).toSet()),
          child: Text(_sel.length == widget.notes.length ? 'None' : 'All')),
      ]),
      Flexible(child: ListView(shrinkWrap: true, children: widget.notes.map((n) =>
        CheckboxListTile(
          value: _sel.contains(n.id),
          onChanged: (v) => setState(() => v! ? _sel.add(n.id) : _sel.remove(n.id)),
          activeColor: kPrimary,
          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('${n.attachments.length} attachment(s)',
              style: const TextStyle(fontSize: 12)),
          secondary: const Icon(Icons.attach_file, color: kPrimary, size: 18),
          controlAffinity: ListTileControlAffinity.leading,
        )).toList())),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
        onPressed: _sel.isEmpty ? null
            : () => Navigator.pop(context, widget.notes.where((n) => _sel.contains(n.id)).toList()),
        child: Text('Export ${_sel.length} note(s)')),
    ]);
}

// ════════════════════════════════════════════════════════════════════
// IMPORT PREVIEW DIALOG
// ════════════════════════════════════════════════════════════════════
class _ImportPreviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> notesJson;
  const _ImportPreviewDialog({required this.notesJson});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import Notes with Media'),
    content: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Found ${notesJson.length} note(s) in backup:',
          style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      ...notesJson.map((n) {
        final count = (n['attachments'] as List).length;
        return Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.note_outlined, size: 18, color: kPrimary),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$count attachment${count == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ])),
          ]));
      }),
      const Divider(),
      const Text('Existing notes with the same ID will be updated.\nNew notes will be added.',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Import')),
    ]);
}

// ════════════════════════════════════════════════════════════════════
// UPDATE BANNER
// ════════════════════════════════════════════════════════════════════
class _UpdateBanner extends StatelessWidget {
  final String version;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;
  const _UpdateBanner({required this.version, required this.onDownload, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3),
          blurRadius: 10, offset: const Offset(0, 4))]),
    child: Row(children: [
      const Icon(Icons.system_update_rounded, color: Colors.white, size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Update Available',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text('v$version is ready on GitHub',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
      TextButton(
        onPressed: onDownload,
        style: TextButton.styleFrom(foregroundColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
        child: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(width: 4),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white70, size: 18),
        onPressed: onDismiss, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
    ]));
}

// ════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.bold,
        color: Colors.grey[600], letterSpacing: 0.5)));
}

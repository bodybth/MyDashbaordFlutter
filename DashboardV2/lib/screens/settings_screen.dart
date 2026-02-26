import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'widgets.dart';

const _kPrimary = Color(0xFF667EEA);
const _kSecondary = Color(0xFF764BA2);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      appBar: const GradientAppBar(title: '⚙️ Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          _SectionHeader(title: 'Appearance'),
          _SettingsCard(children: [
            SwitchListTile(
              leading: Icon(themeService.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: _kPrimary),
              title: const Text('Dark Mode'),
              subtitle: Text(themeService.isDark ? 'Dark theme active' : 'Light theme active'),
              value: themeService.isDark,
              activeColor: _kPrimary,
              onChanged: (_) => themeService.toggle(),
            ),
          ]),

          const SizedBox(height: 16),

          // Data section
          _SectionHeader(title: 'Data Management'),
          _SettingsCard(children: [
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.download, color: _kPrimary)),
              title: const Text('Export Data'),
              subtitle: const Text('Save or share your data as JSON'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showExportOptions(context),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.upload_file, color: _kSecondary)),
              title: const Text('Import Data'),
              subtitle: const Text('Restore from a backup file'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showImportOptions(context),
            ),
          ]),

          const SizedBox(height: 16),

          // About section
          _SectionHeader(title: 'About'),
          _SettingsCard(children: [
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.info_outline, color: Colors.grey)),
              title: const Text('My Dashboard'),
              subtitle: const Text('Engineering Student App v2.0'),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Padding(padding: EdgeInsets.all(16), child: Text('Export Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.share, color: _kPrimary)),
        title: const Text('Save / Share as JSON file'),
        subtitle: const Text('Save to Downloads or share via app'),
        onTap: () { Navigator.pop(context); _exportAsFile(context); },
      ),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.copy, color: _kSecondary)),
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
      title: const Row(children: [Icon(Icons.copy, color: _kPrimary), SizedBox(width: 8), Text('Copy JSON')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Tap Copy to copy all data:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 150, child: TextField(controller: TextEditingController(text: json),
            maxLines: null, readOnly: true,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            decoration: const InputDecoration(border: OutlineInputBorder()))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy), label: const Text('Copy All'),
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
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
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder_open, color: _kPrimary)),
        title: const Text('Pick JSON file'),
        subtitle: const Text('Browse and select your backup file'),
        onTap: () { Navigator.pop(context); _importFromFile(context); },
      ),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.paste, color: _kSecondary)),
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
      title: const Row(children: [Icon(Icons.paste, color: _kPrimary), SizedBox(width: 8), Text('Paste JSON')]),
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
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
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
                content: Text(result == 'success' ? '✅ Imported!' : '❌ $result'),
                duration: const Duration(seconds: 3)));
          },
          child: const Text('Yes, overwrite'),
        ),
      ],
    ));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Column(children: children),
    );
  }
}

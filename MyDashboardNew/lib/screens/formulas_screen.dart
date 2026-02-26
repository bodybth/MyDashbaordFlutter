import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

class FormulasScreen extends StatefulWidget {
  const FormulasScreen({super.key});
  @override
  State<FormulasScreen> createState() => _FormulasScreenState();
}

class _FormulasScreenState extends State<FormulasScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📐 Formulas',
        actions: [
          Consumer<StorageService>(
            builder: (_, storage, __) => IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Manage Categories',
              onPressed: () => showCategoryManager(
                context: context,
                title: 'Formula Categories',
                categories: storage.formulaCategories,
                onAdd: (cat) => storage.addFormulaCategory(cat),
                onDelete: (id) => storage.deleteFormulaCategory(id),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reset to defaults',
              onPressed: () => _confirmReset(context)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showFormulaEditor(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          // Build category map
          final catMap = {for (var c in storage.formulaCategories) c.id: c};

          // Filter formulas
          final filtered = storage.formulas.where((f) {
            final matchCat = _selectedCategory == null || f.category == _selectedCategory;
            final matchSearch = _search.isEmpty ||
                f.name.toLowerCase().contains(_search) ||
                f.formula.toLowerCase().contains(_search) ||
                f.desc.toLowerCase().contains(_search);
            return matchCat && matchSearch;
          }).toList();

          // Group by category
          final grouped = <String, List<Formula>>{};
          for (final f in filtered) {
            grouped.putIfAbsent(f.category, () => []).add(f);
          }

          return Column(children: [
            // Search
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search formulas...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Colors.grey[50],
                ),
              ),
            ),
            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                FilterChip(label: const Text('All'), selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null)),
                const SizedBox(width: 8),
                ...storage.formulaCategories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${cat.emoji} ${cat.name}'),
                    selected: _selectedCategory == cat.id,
                    onSelected: (_) => setState(() => _selectedCategory = _selectedCategory == cat.id ? null : cat.id),
                    selectedColor: const Color(0xFF667EEA).withOpacity(0.2),
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: grouped.isEmpty
                  ? const Center(child: Text('No formulas found', style: TextStyle(color: Colors.grey)))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: grouped.entries.map((entry) {
                        final cat = catMap[entry.key];
                        final label = cat != null ? '${cat.emoji} ${cat.name}' : entry.key;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ...entry.value.map((f) => _FormulaCard(
                            formula: f,
                            onEdit: () => _showFormulaEditor(context, existing: f),
                            onDelete: () => _confirmDelete(context, f),
                          )),
                        ]);
                      }).toList(),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Formulas'),
        content: const Text('This will restore all default formulas and delete any custom ones. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { context.read<StorageService>().resetFormulas(); Navigator.pop(ctx); },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Formula f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Formula'),
        content: Text('Delete "${f.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { context.read<StorageService>().deleteFormula(f.id); Navigator.pop(ctx); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFormulaEditor(BuildContext context, {Formula? existing}) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final formulaCtrl = TextEditingController(text: existing?.formula ?? '');
    final descCtrl = TextEditingController(text: existing?.desc ?? '');
    String category = existing?.category ?? (storage.formulaCategories.isNotEmpty ? storage.formulaCategories.first.id : 'general');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(existing == null ? 'Add Formula' : 'Edit Formula',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Formula Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: formulaCtrl,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(labelText: 'Formula (e.g. F = ma)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Consumer<StorageService>(
              builder: (_, s, __) => DropdownButtonFormField<String>(
                value: s.formulaCategories.any((c) => c.id == category) ? category : s.formulaCategories.first.id,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: s.formulaCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
                onChanged: (v) => setState(() => category = v!),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: GradientButton(
              label: existing == null ? 'Add Formula' : 'Save Changes',
              icon: existing == null ? Icons.add : Icons.save,
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || formulaCtrl.text.trim().isEmpty) return;
                final f = Formula(
                  id: existing?.id,
                  name: nameCtrl.text.trim(),
                  formula: formulaCtrl.text.trim(),
                  desc: descCtrl.text.trim(),
                  category: category,
                  isCustom: true,
                );
                if (existing == null) storage.addFormula(f); else storage.updateFormula(f);
                Navigator.pop(ctx);
              },
            )),
          ]),
        ),
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final Formula formula;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _FormulaCard({required this.formula, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(formula.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (formula.isCustom) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF764BA2).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('custom', style: TextStyle(fontSize: 10, color: Color(0xFF764BA2))),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF667EEA).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(formula.formula,
                  style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF667EEA), fontWeight: FontWeight.bold)),
            ),
            if (formula.desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(formula.desc, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ])),
          Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.copy, size: 18, color: Colors.grey), padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: formula.formula));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
                }),
            const SizedBox(height: 4),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF667EEA)),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onEdit),
            const SizedBox(height: 4),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onDelete),
          ]),
        ]),
      ),
    );
  }
}

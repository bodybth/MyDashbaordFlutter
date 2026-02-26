import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

const _kPrimary = Color(0xFF667EEA);
const _kSecondary = Color(0xFF764BA2);

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '🗂 Collections',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'New Collection',
            onPressed: () => _showAddCollection(context),
          ),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          if (storage.collections.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No collections yet\nTap + to add one',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ]),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
              ),
              itemCount: storage.collections.length,
              itemBuilder: (ctx, i) => _CollectionTile(collection: storage.collections[i]),
            ),
          );
        },
      ),
    );
  }

  void _showAddCollection(BuildContext context) {
    final titleCtrl = TextEditingController();
    String emoji = '📁';
    String type = 'custom';
    final emojis = ['📁', '📐', '📝', '📧', '📚', '⚡', '🚀', '💡', '💧', '🔧', '🔥', '🧪', '📊', '🎯', '🌟'];
    final types = ['formula', 'note', 'email', 'custom'];
    final typeLabels = {'formula': 'Formulas', 'note': 'Notes', 'email': 'Email Addresses', 'custom': 'Custom Text'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('New Collection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Emoji picker row
            SizedBox(height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: emojis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => emoji = emojis[i]),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: emoji == emojis[i] ? _kPrimary.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: emoji == emojis[i] ? Border.all(color: _kPrimary) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emojis[i], style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Collection Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(typeLabels[t]!))).toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: GradientButton(
              label: 'Create Collection',
              icon: Icons.add,
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                context.read<StorageService>().addCollection(Collection(
                  title: titleCtrl.text.trim(),
                  emoji: emoji,
                  type: type,
                ));
                Navigator.pop(ctx);
              },
            )),
          ]),
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  const _CollectionTile({required this.collection});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    // Count items in this collection
    int count = 0;
    if (collection.type == 'formula') {
      count = storage.formulas.length;
    } else if (collection.type == 'note') {
      count = storage.notes.length;
    } else if (collection.type == 'email') {
      // emails stored as notes with branch = collection.id
      count = storage.notes.where((n) => n.branch == 'email_${collection.id}').length;
    } else {
      count = storage.notes.where((n) => n.branch == 'col_${collection.id}').length;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => _CollectionDetailScreen(collection: collection),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_kPrimary.withOpacity(0.85), _kSecondary.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(collection.emoji, style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  Text(collection.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$count items', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
                onSelected: (val) {
                  if (val == 'delete') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Collection'),
                        content: Text('Delete "${collection.title}"? Content inside will be removed.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              context.read<StorageService>().deleteCollection(collection.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red)),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail screens per collection type ───────────────────────────

class _CollectionDetailScreen extends StatelessWidget {
  final Collection collection;
  const _CollectionDetailScreen({required this.collection});

  @override
  Widget build(BuildContext context) {
    switch (collection.type) {
      case 'formula':
        return _FormulaCollectionScreen(collection: collection);
      case 'note':
        return _NoteCollectionScreen(collection: collection);
      case 'email':
        return _EmailCollectionScreen(collection: collection);
      default:
        return _CustomCollectionScreen(collection: collection);
    }
  }
}

// ── FORMULA collection ────────────────────────────────────────────

class _FormulaCollectionScreen extends StatefulWidget {
  final Collection collection;
  const _FormulaCollectionScreen({required this.collection});
  @override
  State<_FormulaCollectionScreen> createState() => _FormulaCollectionScreenState();
}

class _FormulaCollectionScreenState extends State<_FormulaCollectionScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '${widget.collection.emoji} ${widget.collection.title}',
        actions: [
          Consumer<StorageService>(
            builder: (_, storage, __) => IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () => showCategoryManager(
                context: context, title: 'Formula Categories',
                categories: storage.formulaCategories,
                onAdd: (cat) => storage.addFormulaCategory(cat),
                onDelete: (id) => storage.deleteFormulaCategory(id),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _confirmReset(context)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showFormulaEditor(context)),
        ],
      ),
      body: Consumer<StorageService>(builder: (context, storage, _) {
        final catMap = {for (var c in storage.formulaCategories) c.id: c};
        final filtered = storage.formulas.where((f) {
          final matchCat = _selectedCategory == null || f.category == _selectedCategory;
          final matchSearch = _search.isEmpty ||
              f.name.toLowerCase().contains(_search) ||
              f.formula.toLowerCase().contains(_search) ||
              f.desc.toLowerCase().contains(_search);
          return matchCat && matchSearch;
        }).toList();
        final grouped = <String, List<Formula>>{};
        for (final f in filtered) {
          grouped.putIfAbsent(f.category, () => []).add(f);
        }
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(hintText: 'Search formulas...', prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true),
            ),
          ),
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
                  selectedColor: _kPrimary.withOpacity(0.2),
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
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        ...entry.value.map((f) => _FormulaCard(
                          formula: f,
                          onEdit: () => _showFormulaEditor(context, existing: f),
                          onDelete: () {
                            showDialog(context: context, builder: (ctx) => AlertDialog(
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
                            ));
                          },
                        )),
                      ]);
                    }).toList(),
                  ),
          ),
        ]);
      }),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset Formulas'),
      content: const Text('This will restore all default formulas and delete custom ones. Are you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () { context.read<StorageService>().resetFormulas(); Navigator.pop(ctx); },
          child: const Text('Reset'),
        ),
      ],
    ));
  }

  void _showFormulaEditor(BuildContext context, {Formula? existing}) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final formulaCtrl = TextEditingController(text: existing?.formula ?? '');
    final descCtrl = TextEditingController(text: existing?.desc ?? '');
    String category = existing?.category ?? (storage.formulaCategories.isNotEmpty ? storage.formulaCategories.first.id : 'general');

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add Formula' : 'Edit Formula',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Formula Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: formulaCtrl, style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: 'Formula (e.g. F = ma)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Consumer<StorageService>(builder: (_, s, __) => DropdownButtonFormField<String>(
            value: s.formulaCategories.any((c) => c.id == category) ? category : s.formulaCategories.first.id,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: s.formulaCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
            onChanged: (v) => setState(() => category = v!),
          )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add Formula' : 'Save Changes',
            icon: existing == null ? Icons.add : Icons.save,
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || formulaCtrl.text.trim().isEmpty) return;
              final f = Formula(id: existing?.id, name: nameCtrl.text.trim(),
                  formula: formulaCtrl.text.trim(), desc: descCtrl.text.trim(),
                  category: category, isCustom: true);
              if (existing == null) storage.addFormula(f); else storage.updateFormula(f);
              Navigator.pop(ctx);
            },
          )),
        ]),
      )),
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
              if (formula.isCustom) ...[ const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _kSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('custom', style: TextStyle(fontSize: 10, color: _kSecondary))),
              ],
            ]),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(formula.formula,
                  style: const TextStyle(fontFamily: 'monospace', color: _kPrimary, fontWeight: FontWeight.bold))),
            if (formula.desc.isNotEmpty) ...[ const SizedBox(height: 4),
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
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: _kPrimary),
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

// ── NOTE collection ───────────────────────────────────────────────

class _NoteCollectionScreen extends StatelessWidget {
  final Collection collection;
  const _NoteCollectionScreen({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '${collection.emoji} ${collection.title}',
        actions: [
          Consumer<StorageService>(builder: (_, storage, __) => IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => showCategoryManager(
              context: context, title: 'Note Categories',
              categories: storage.noteCategories,
              onAdd: (cat) => storage.addNoteCategory(cat),
              onDelete: (id) => storage.deleteNoteCategory(id),
            ),
          )),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showNoteEditor(context)),
        ],
      ),
      body: Consumer<StorageService>(builder: (context, storage, _) {
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
      }),
    );
  }

  void _showNoteEditor(BuildContext context, [Note? existing]) {
    final storage = context.read<StorageService>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String branch = existing?.branch ?? (storage.noteCategories.isNotEmpty ? storage.noteCategories.first.id : 'general');

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'New Note' : 'Edit Note',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Consumer<StorageService>(builder: (_, s, __) => DropdownButtonFormField<String>(
            value: s.noteCategories.any((c) => c.id == branch) ? branch : s.noteCategories.first.id,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: s.noteCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}'))).toList(),
            onChanged: (v) => setState(() => branch = v!),
          )),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Save Note' : 'Update Note', icon: Icons.save,
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
      )),
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
              decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${cat.emoji} ${cat.name}', style: const TextStyle(fontSize: 11, color: _kPrimary)),
            ),
            const Spacer(),
            Text(DateFormat('MMM dd').format(note.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: _kPrimary, size: 16),
              onPressed: () => _editNote(context, note),
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
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
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
      )),
    );
  }
}

// ── EMAIL collection ──────────────────────────────────────────────

class _EmailCollectionScreen extends StatelessWidget {
  final Collection collection;
  const _EmailCollectionScreen({required this.collection});

  String get _branchKey => 'email_${collection.id}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '${collection.emoji} ${collection.title}',
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEmail(context)),
        ],
      ),
      body: Consumer<StorageService>(builder: (context, storage, _) {
        final emails = storage.notes.where((n) => n.branch == _branchKey).toList();
        if (emails.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.email_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No emails yet\nTap + to add one', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: emails.length,
          itemBuilder: (ctx, i) => _EmailCard(note: emails[i]),
        );
      }),
    );
  }

  void _showAddEmail(BuildContext context, [Note? existing]) {
    final nameCtrl = TextEditingController(text: existing?.title ?? '');
    final emailCtrl = TextEditingController(text: existing?.content ?? '');
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add Email Address' : 'Edit Email Address',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Dr. Smith)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add Email' : 'Save',
            icon: Icons.save,
            onPressed: () {
              if (emailCtrl.text.trim().isEmpty) return;
              final s = context.read<StorageService>();
              final note = Note(id: existing?.id, title: nameCtrl.text.trim().isEmpty ? emailCtrl.text.trim() : nameCtrl.text.trim(),
                  content: emailCtrl.text.trim(), branch: _branchKey);
              if (existing == null) s.addNote(note); else s.updateNote(note);
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  final Note note;
  const _EmailCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.email_outlined, color: _kPrimary),
        ),
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(note.content, style: const TextStyle(color: _kPrimary, fontSize: 13)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: note.content));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied!'), duration: Duration(seconds: 1)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => context.read<StorageService>().deleteNote(note.id),
          ),
        ]),
      ),
    );
  }
}

// ── CUSTOM collection ─────────────────────────────────────────────

class _CustomCollectionScreen extends StatelessWidget {
  final Collection collection;
  const _CustomCollectionScreen({required this.collection});

  String get _branchKey => 'col_${collection.id}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '${collection.emoji} ${collection.title}',
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddItem(context)),
        ],
      ),
      body: Consumer<StorageService>(builder: (context, storage, _) {
        final items = storage.notes.where((n) => n.branch == _branchKey).toList();
        if (items.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No items yet\nTap + to add one', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _CustomItemCard(note: items[i], onEdit: () => _showAddItem(context, items[i])),
        );
      }),
    );
  }

  void _showAddItem(BuildContext context, [Note? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(existing == null ? 'Add Item' : 'Edit Item',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add Item' : 'Save',
            icon: Icons.save,
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final s = context.read<StorageService>();
              final note = Note(id: existing?.id, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), branch: _branchKey);
              if (existing == null) s.addNote(note); else s.updateNote(note);
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }
}

class _CustomItemCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  const _CustomItemCard({required this.note, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: _kPrimary), onPressed: onEdit,
                padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => context.read<StorageService>().deleteNote(note.id),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
          ]),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note.content, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ]),
      ),
    );
  }
}

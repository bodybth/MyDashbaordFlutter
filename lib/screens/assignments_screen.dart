import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

enum _Tab { inProgress, incoming, done }
enum _Sort { deadline, course, priority }

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});
  @override State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  _Tab _tab = _Tab.inProgress;
  _Sort _sort = _Sort.deadline;

  List<Assignment> _filter(List<Assignment> all, List<AppCategory> priorities) {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 3));
    List<Assignment> result;
    switch (_tab) {
      case _Tab.inProgress: result = all.where((a) => !a.completed && a.dueDate.isBefore(cutoff)).toList(); break;
      case _Tab.incoming:   result = all.where((a) => !a.completed && !a.dueDate.isBefore(cutoff)).toList(); break;
      case _Tab.done:       result = all.where((a) => a.completed).toList(); break;
    }
    switch (_sort) {
      case _Sort.deadline:  result.sort((a, b) => a.dueDate.compareTo(b.dueDate)); break;
      case _Sort.course:    result.sort((a, b) => a.course.compareTo(b.course)); break;
      case _Sort.priority:
        final order = {for (int i = 0; i < priorities.length; i++) priorities[i].name: i};
        result.sort((a, b) => (order[a.priority] ?? 99).compareTo(order[b.priority] ?? 99));
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📋 Assignments',
        actions: <Widget>[
          Consumer<StorageService>(builder: (context, storage, _) => IconButton(
            icon: const Icon(Icons.category_outlined), tooltip: 'Priorities',
            onPressed: () => showCategoryManager(context: context, title: 'Manage Priorities',
              categories: storage.priorities, onAdd: (c) => storage.addPriority(c), onDelete: (id) => storage.deletePriority(id)))),
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort, color: Colors.white), tooltip: 'Sort by',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              _sortItem(_Sort.deadline, 'Due Date'),
              _sortItem(_Sort.course,   'Course'),
              _sortItem(_Sort.priority, 'Priority'),
            ]),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _sheet(context, null)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          final list = _filter(storage.assignments, storage.priorities);
          return Column(children: [
            // ── Tab buttons ───────────────────────────────────────
            Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [
                _tabBtn(_Tab.inProgress, '🔄 In-Progress'),
                const SizedBox(width: 8),
                _tabBtn(_Tab.incoming, '📥 Incoming'),
                const SizedBox(width: 8),
                _tabBtn(_Tab.done, '✅ Done'),
              ])),
            // ── Sort label ────────────────────────────────────────
            Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(children: [
                Text('Sorted by: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(_sort == _Sort.deadline ? 'Due Date' : _sort == _Sort.course ? 'Course' : 'Priority',
                    style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.bold)),
              ])),
            // ── List ──────────────────────────────────────────────
            Expanded(child: list.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_tab == _Tab.done ? 'No completed tasks' : _tab == _Tab.inProgress ? 'No in-progress tasks' : 'No upcoming tasks',
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ]))
              : ListView.builder(padding: const EdgeInsets.all(12), itemCount: list.length,
                  itemBuilder: (_, i) => _Card(assignment: list[i], onEdit: () => _sheet(context, list[i])))),
          ]);
        },
      ),
    );
  }

  PopupMenuItem<_Sort> _sortItem(_Sort v, String label) => PopupMenuItem(value: v,
    child: Row(children: [
      Icon(_sort == v ? Icons.check : null, size: 18, color: kPrimary),
      const SizedBox(width: 8), Text(label),
    ]));

  Widget _tabBtn(_Tab tab, String label) {
    final sel = _tab == tab;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [kPrimary, kSecondary]) : null,
          color: sel ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.grey[600], fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 12)))));
  }

  // ── Add/Edit sheet ────────────────────────────────────────────────
  void _sheet(BuildContext context, Assignment? existing) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final courseCtrl = TextEditingController(text: existing?.course ?? '');
    final detailsCtrl = TextEditingController(text: existing?.details ?? '');
    String priority = existing?.priority ?? (storage.priorities.isNotEmpty ? storage.priorities.first.name : '');
    DateTime dueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    DateTime? reminderTime = existing?.reminderTime;

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(existing == null ? 'Add Assignment' : 'Edit Assignment', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Assignment Name *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          // ── Details field ─────────────────────────────────────
          TextField(controller: detailsCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Assignment Details', hintText: 'Describe what needs to be done…', border: OutlineInputBorder(), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          Consumer<StorageService>(builder: (_, s, __) => DropdownButtonFormField<String>(
            value: s.priorities.any((p) => p.name == priority) ? priority : (s.priorities.isNotEmpty ? s.priorities.first.name : null),
            decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
            items: s.priorities.map((p) => DropdownMenuItem(value: p.name, child: Text('${p.emoji} ${p.name}'))).toList(),
            onChanged: (v) => ss(() => priority = v!))),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final p = await showDatePicker(context: ctx, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (p != null) ss(() => dueDate = p);
            },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
              child: Text(DateFormat('MMM dd, yyyy').format(dueDate)))),
          const SizedBox(height: 16),
          // ── Reminder box ──────────────────────────────────────
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: kPrimary.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.notifications_outlined, color: kPrimary, size: 18), SizedBox(width: 6), Text('Reminder', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary))]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications, size: 16),
                  label: Text(reminderTime != null ? DateFormat('MMM dd, hh:mm a').format(reminderTime!) : 'Set Notification', overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: const BorderSide(color: kPrimary)),
                  onPressed: () async {
                    final d = await showDatePicker(context: ctx, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d == null || !ctx.mounted) return;
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (t == null) return;
                    ss(() => reminderTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  })),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.alarm, size: 16),
                  label: const Text('Set Alarm'),
                  style: OutlinedButton.styleFrom(foregroundColor: kSecondary, side: const BorderSide(color: kSecondary)),
                  onPressed: () async {
                    final d = await showDatePicker(context: ctx, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d == null || !ctx.mounted) return;
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (t == null || !ctx.mounted) return;
                    final at = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                    if (at.isAfter(DateTime.now())) {
                      final label = nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Assignment';
                      await NotificationService.scheduleAlarm(id: at.millisecondsSinceEpoch ~/ 1000 % 100000, label: label, alarmTime: at);
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Alarm set for ${at.hour.toString().padLeft(2,"0")}:${at.minute.toString().padLeft(2,"0")}'), duration: const Duration(seconds: 2)));
                    }
                  })),
              ]),
              if (reminderTime != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 6),
                  Expanded(child: Text('Notification: ${DateFormat('MMM dd, hh:mm a').format(reminderTime!)}', style: const TextStyle(fontSize: 12, color: Colors.green))),
                  GestureDetector(onTap: () => ss(() => reminderTime = null), child: const Icon(Icons.close, size: 16, color: Colors.red)),
                ]),
              ],
            ])),
          const SizedBox(height: 16),
          // ── SAVE BUTTON ───────────────────────────────────────
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add Assignment' : 'Save Changes',
            icon: existing == null ? Icons.add : Icons.save,
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final assignment = Assignment(
                id: existing?.id, name: nameCtrl.text.trim(), course: courseCtrl.text.trim(),
                details: detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim(),
                dueDate: dueDate, priority: priority,
                completed: existing?.completed ?? false, reminderTime: reminderTime);
              final s = context.read<StorageService>();
              if (existing == null) s.addAssignment(assignment); else s.updateAssignment(assignment);
              if (reminderTime != null && reminderTime!.isAfter(DateTime.now())) {
                await NotificationService.scheduleReminder(
                  id: assignment.id.hashCode.abs() % 100000, title: '📋 Reminder',
                  body: '${assignment.name} due ${DateFormat('MMM dd').format(dueDate)}', scheduledTime: reminderTime!);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            })),
        ])))));
  }
}

// ── Assignment Card ───────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onEdit;
  const _Card({required this.assignment, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    final overdue = daysLeft < 0 && !assignment.completed;
    final priority = storage.priorities.firstWhere((p) => p.name == assignment.priority, orElse: () => AppCategory(name: assignment.priority, emoji: '🔵'));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: overdue ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none),
      child: ExpansionTile(
        leading: Checkbox(value: assignment.completed, activeColor: kPrimary, onChanged: (_) => storage.toggleAssignment(assignment.id)),
        title: Text(assignment.name, style: TextStyle(fontWeight: FontWeight.w600,
            decoration: assignment.completed ? TextDecoration.lineThrough : null,
            color: assignment.completed ? Colors.grey : null)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${assignment.course.isNotEmpty ? "${assignment.course} • " : ""}${DateFormat("MMM dd").format(assignment.dueDate)} • ${daysLeft >= 0 ? "$daysLeft days left" : "Overdue"}',
              style: TextStyle(color: overdue ? Colors.red : Colors.grey[600], fontSize: 12)),
          if (assignment.reminderTime != null)
            Text('🔔 ${DateFormat("MMM dd, hh:mm a").format(assignment.reminderTime!)}', style: const TextStyle(fontSize: 11, color: kPrimary)),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(priority.emoji, style: const TextStyle(fontSize: 18)),
          IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary, size: 18), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () {
                if (assignment.reminderTime != null) NotificationService.cancelReminder(assignment.id.hashCode.abs() % 100000);
                storage.deleteAssignment(assignment.id);
              }),
        ]),
        children: [
          if (assignment.details != null && assignment.details!.isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(alignment: Alignment.centerLeft,
                child: Text(assignment.details!, style: TextStyle(color: Colors.grey[600], fontSize: 13)))),
        ],
      ),
    );
  }
}

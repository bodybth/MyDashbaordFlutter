import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📋 Assignments',
        actions: [
          Consumer<StorageService>(
            builder: (context, storage, _) => IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Manage Priorities',
              onPressed: () => showCategoryManager(
                context: context,
                title: 'Manage Priorities',
                categories: storage.priorities,
                onAdd: (cat) => storage.addPriority(cat),
                onDelete: (id) => storage.deletePriority(id),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          final pending = storage.assignments.where((a) => !a.completed).toList();
          final done = storage.assignments.where((a) => a.completed).toList();
          if (storage.assignments.isEmpty) {
            return const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text('No assignments yet\nTap + to add one',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (pending.isNotEmpty) ...[
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Pending',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ...pending.map((a) => _AssignmentCard(assignment: a)),
              ],
              if (done.isNotEmpty) ...[
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Completed',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey))),
                ...done.map((a) => _AssignmentCard(assignment: a)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, [Assignment? existing]) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final courseCtrl = TextEditingController(text: existing?.course ?? '');
    String priority = existing?.priority ?? (storage.priorities.first.name);
    DateTime dueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    DateTime? reminderTime = existing?.reminderTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Add Assignment' : 'Edit Assignment',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Assignment Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: courseCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Course', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Consumer<StorageService>(
                  builder: (_, s, __) => DropdownButtonFormField<String>(
                    value: s.priorities.any((p) => p.name == priority) ? priority : s.priorities.first.name,
                    decoration: const InputDecoration(
                        labelText: 'Priority', border: OutlineInputBorder()),
                    items: s.priorities
                        .map((p) => DropdownMenuItem(value: p.name, child: Text('${p.emoji} ${p.name}')))
                        .toList(),
                    onChanged: (v) => setState(() => priority = v!),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                    child: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                  ),
                ),
                const SizedBox(height: 16),
                // Reminder & Alarm section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.notifications_outlined, color: Color(0xFF667EEA), size: 18),
                          SizedBox(width: 6),
                          Text('Reminder',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA))),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.notifications, size: 16),
                              label: Text(reminderTime != null
                                  ? DateFormat('MMM dd, HH:mm').format(reminderTime!)
                                  : 'Local Notification'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF667EEA),
                                side: const BorderSide(color: Color(0xFF667EEA)),
                              ),
                              onPressed: () async {
                                final date = await showDatePicker(
                                    context: ctx,
                                    initialDate: dueDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (date == null || !ctx.mounted) return;
                                final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                                if (time == null) return;
                                setState(() {
                                  reminderTime =
                                      DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.alarm, size: 16),
                              label: const Text('Set Alarm'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF764BA2),
                                side: const BorderSide(color: Color(0xFF764BA2)),
                              ),
                              onPressed: () async {
                                final date = await showDatePicker(
                                    context: ctx,
                                    initialDate: dueDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (date == null || !ctx.mounted) return;
                                final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                                if (time == null || !ctx.mounted) return;
                                final alarmTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                if (alarmTime.isAfter(DateTime.now())) {
                                  final label = nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Assignment';
                                  final alarmId = alarmTime.millisecondsSinceEpoch ~/ 1000 % 100000;
                                  await NotificationService.scheduleAlarm(
                                    id: alarmId,
                                    label: label,
                                    alarmTime: alarmTime,
                                  );
                                  if (ctx.mounted)
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                        content: Text(
                                            'Alarm set for ${alarmTime.hour.toString().padLeft(2, "0")}:${alarmTime.minute.toString().padLeft(2, "0")}'),
                                        duration: const Duration(seconds: 2)));
                                }
                              },
                            ),
                          ),
                        ]),
                        if (reminderTime != null) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                                'Notification: ${DateFormat('MMM dd, HH:mm').format(reminderTime!)}',
                                style: const TextStyle(fontSize: 12, color: Colors.green)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => reminderTime = null),
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ]),
                        ],
                      ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: existing == null ? 'Add Assignment' : 'Save Changes',
                    icon: existing == null ? Icons.add : Icons.save,
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final assignment = Assignment(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        course: courseCtrl.text.trim(),
                        dueDate: dueDate,
                        priority: priority,
                        completed: existing?.completed ?? false,
                        reminderTime: reminderTime,
                      );
                      final s = context.read<StorageService>();
                      if (existing == null)
                        s.addAssignment(assignment);
                      else
                        s.updateAssignment(assignment);

                      // Schedule reminder notification
                      if (reminderTime != null && reminderTime!.isAfter(DateTime.now())) {
                        final idHash = assignment.id.hashCode.abs() % 100000;
                        await NotificationService.scheduleReminder(
                          id: idHash,
                          title: '📋 Assignment Reminder',
                          body: '${assignment.name} is due on ${DateFormat('MMM dd').format(dueDate)}',
                          scheduledTime: reminderTime!,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Assignment Card widget
class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    final priority = storage.priorities.firstWhere((p) => p.name == assignment.priority,
        orElse: () => AppCategory(name: assignment.priority, emoji: '🔵'));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: assignment.completed,
          activeColor: const Color(0xFF667EEA),
          onChanged: (_) => storage.toggleAssignment(assignment.id),
        ),
        title: Text(assignment.name,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: assignment.completed ? TextDecoration.lineThrough : null,
                color: assignment.completed ? Colors.grey : null)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${assignment.course} • ${DateFormat('MMM dd').format(assignment.dueDate)} • ${daysLeft >= 0 ? '$daysLeft days left' : 'Overdue'}',
              style: TextStyle(
                  color: daysLeft < 0 && !assignment.completed ? Colors.red : Colors.grey[600],
                  fontSize: 12)),
          if (assignment.reminderTime != null)
            Text('🔔 ${DateFormat('MMM dd, HH:mm').format(assignment.reminderTime!)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA))),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${priority.emoji}', style: const TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF667EEA), size: 18),
            onPressed: () => _showEditDialog(context, assignment),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            onPressed: () {
              if (assignment.reminderTime != null) {
                NotificationService.cancelReminder(assignment.id.hashCode.abs() % 100000);
              }
              storage.deleteAssignment(assignment.id);
            },
          ),
        ]),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Assignment assignment) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: assignment.name);
    final courseCtrl = TextEditingController(text: assignment.course);
    String priority = assignment.priority;
    DateTime dueDate = assignment.dueDate;
    DateTime? reminderTime = assignment.reminderTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Edit Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: storage.priorities.any((p) => p.name == priority) ? priority : storage.priorities.first.name,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: storage.priorities.map((p) => DropdownMenuItem(value: p.name, child: Text('${p.emoji} ${p.name}'))).toList(),
                onChanged: (v) => setState(() => priority = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: dueDate,
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                  child: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.alarm, size: 16),
                    label: const Text('Alarm'),
                    onPressed: () async {
                      final date = await showDatePicker(context: ctx, initialDate: dueDate,
                          firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (date == null || !ctx.mounted) return;
                      final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                      if (time == null || !ctx.mounted) return;
                      final alarmTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      if (alarmTime.isAfter(DateTime.now())) {
                        final label = nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Assignment';
                        final alarmId = alarmTime.millisecondsSinceEpoch ~/ 1000 % 100000;
                        await NotificationService.scheduleAlarm(
                          id: alarmId,
                          label: label,
                          alarmTime: alarmTime,
                        );
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Alarm set for ${alarmTime.hour.toString().padLeft(2, "0")}:${alarmTime.minute.toString().padLeft(2, "0")}'),
                            duration: const Duration(seconds: 2)));
                      }
                    },
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

const _kPrimary = Color(0xFF667EEA);
const _kSecondary = Color(0xFF764BA2);

enum TaskFilter { inProgress, incoming, done }
enum TaskSort { deadline, course, priority }

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});
  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  TaskFilter _filter = TaskFilter.incoming;
  TaskSort _sort = TaskSort.deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📋 Tasks',
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
          // Sort button
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort by',
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              PopupMenuItem(value: TaskSort.deadline,
                  child: Row(children: [
                    Icon(Icons.calendar_today, size: 18, color: _sort == TaskSort.deadline ? _kPrimary : Colors.grey),
                    const SizedBox(width: 8), const Text('Due Date'),
                  ])),
              PopupMenuItem(value: TaskSort.course,
                  child: Row(children: [
                    Icon(Icons.school_outlined, size: 18, color: _sort == TaskSort.course ? _kPrimary : Colors.grey),
                    const SizedBox(width: 8), const Text('Course'),
                  ])),
              PopupMenuItem(value: TaskSort.priority,
                  child: Row(children: [
                    Icon(Icons.flag_outlined, size: 18, color: _sort == TaskSort.priority ? _kPrimary : Colors.grey),
                    const SizedBox(width: 8), const Text('Priority'),
                  ])),
            ],
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showTaskDialog(context)),
        ],
      ),
      body: Column(
        children: [
          // Filter buttons
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _FilterBtn(label: '⏳ In-Progress', active: _filter == TaskFilter.inProgress,
                  onTap: () => setState(() => _filter = TaskFilter.inProgress)),
              const SizedBox(width: 8),
              _FilterBtn(label: '📬 Incoming', active: _filter == TaskFilter.incoming,
                  onTap: () => setState(() => _filter = TaskFilter.incoming)),
              const SizedBox(width: 8),
              _FilterBtn(label: '✅ Done', active: _filter == TaskFilter.done,
                  onTap: () => setState(() => _filter = TaskFilter.done)),
            ]),
          ),
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storage, _) {
                // Priority ordering for sort
                const priorityOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};

                List<Assignment> filtered;
                switch (_filter) {
                  case TaskFilter.inProgress:
                    filtered = storage.assignments.where((a) => !a.completed && a.inProgress).toList();
                    break;
                  case TaskFilter.incoming:
                    filtered = storage.assignments.where((a) => !a.completed && !a.inProgress).toList();
                    break;
                  case TaskFilter.done:
                    filtered = storage.assignments.where((a) => a.completed).toList();
                    break;
                }

                // Sort
                switch (_sort) {
                  case TaskSort.deadline:
                    filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                    break;
                  case TaskSort.course:
                    filtered.sort((a, b) => a.course.compareTo(b.course));
                    break;
                  case TaskSort.priority:
                    filtered.sort((a, b) {
                      final pa = priorityOrder[a.priority] ?? 99;
                      final pb = priorityOrder[b.priority] ?? 99;
                      return pa.compareTo(pb);
                    });
                    break;
                }

                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(_emptyMessage(), textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  ]));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _AssignmentCard(
                    assignment: filtered[i],
                    onEdit: () => _showTaskDialog(context, existing: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case TaskFilter.inProgress: return 'No tasks in progress';
      case TaskFilter.incoming: return 'No incoming tasks\nTap + to add one';
      case TaskFilter.done: return 'No completed tasks yet';
    }
  }

  void _showTaskDialog(BuildContext context, {Assignment? existing}) {
    final storage = context.read<StorageService>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final courseCtrl = TextEditingController(text: existing?.course ?? '');
    final detailsCtrl = TextEditingController(text: existing?.details ?? '');
    String priority = existing?.priority ?? (storage.priorities.first.name);
    DateTime dueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 3));
    DateTime? reminderTime = existing?.reminderTime;
    bool inProgress = existing?.inProgress ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(existing == null ? 'Add Task' : 'Edit Task',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Task Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: courseCtrl,
                  decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: detailsCtrl, maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Assignment Details (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Describe the assignment, requirements...')),
              const SizedBox(height: 12),
              Consumer<StorageService>(
                builder: (_, s, __) => DropdownButtonFormField<String>(
                  value: s.priorities.any((p) => p.name == priority) ? priority : s.priorities.first.name,
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: s.priorities.map((p) => DropdownMenuItem(value: p.name, child: Text('${p.emoji} ${p.name}'))).toList(),
                  onChanged: (v) => setState(() => priority = v!),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                      context: ctx, initialDate: dueDate,
                      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                  child: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                ),
              ),
              const SizedBox(height: 12),
              // In-progress toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as In-Progress'),
                subtitle: const Text('Move task to in-progress tab'),
                value: inProgress,
                activeColor: _kPrimary,
                onChanged: (v) => setState(() => inProgress = v),
              ),
              const SizedBox(height: 8),
              // Reminder section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimary.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.notifications_outlined, color: _kPrimary, size: 18),
                    SizedBox(width: 6),
                    Text('Reminder', style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimary)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.notifications, size: 16),
                        label: Text(reminderTime != null
                            ? DateFormat('MMM dd, hh:mm a').format(reminderTime!)
                            : 'Set Reminder'),
                        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, side: const BorderSide(color: _kPrimary)),
                        onPressed: () async {
                          final date = await showDatePicker(context: ctx, initialDate: dueDate,
                              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (date == null || !ctx.mounted) return;
                          final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now(),
                              builder: (context, child) => MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              ));
                          if (time == null) return;
                          setState(() => reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.alarm, size: 16),
                        label: const Text('Set Alarm'),
                        style: OutlinedButton.styleFrom(foregroundColor: _kSecondary, side: const BorderSide(color: _kSecondary)),
                        onPressed: () async {
                          final date = await showDatePicker(context: ctx, initialDate: dueDate,
                              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (date == null || !ctx.mounted) return;
                          final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now(),
                              builder: (context, child) => MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              ));
                          if (time == null || !ctx.mounted) return;
                          final alarmTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          if (alarmTime.isAfter(DateTime.now())) {
                            final label = nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Assignment';
                            final alarmId = alarmTime.millisecondsSinceEpoch ~/ 1000 % 100000;
                            await NotificationService.scheduleAlarm(id: alarmId, label: label, alarmTime: alarmTime);
                            if (ctx.mounted) {
                              final tod = TimeOfDay.fromDateTime(alarmTime);
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text('Alarm set for ${tod.format(ctx)}'),
                                duration: const Duration(seconds: 2)));
                            }
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
                      Text('Set for ${DateFormat('MMM dd, hh:mm a').format(reminderTime!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.green)),
                      const Spacer(),
                      GestureDetector(onTap: () => setState(() => reminderTime = null),
                          child: const Icon(Icons.close, size: 16, color: Colors.red)),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: GradientButton(
                label: existing == null ? 'Add Task' : 'Save Changes',
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
                    inProgress: inProgress,
                    details: detailsCtrl.text.trim(),
                    reminderTime: reminderTime,
                  );
                  final s = context.read<StorageService>();
                  if (existing == null) s.addAssignment(assignment); else s.updateAssignment(assignment);
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
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(colors: [_kPrimary, _kSecondary]) : null,
            color: active ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? Colors.transparent : Colors.grey.withOpacity(0.3)),
            boxShadow: active ? [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.grey[600])),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onEdit;
  const _AssignmentCard({required this.assignment, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    final priority = storage.priorities.firstWhere((p) => p.name == assignment.priority,
        orElse: () => AppCategory(name: assignment.priority, emoji: '🔵'));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Checkbox(
                value: assignment.completed,
                activeColor: _kPrimary,
                onChanged: (_) => storage.toggleAssignment(assignment.id),
              ),
              title: Text(assignment.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: assignment.completed ? TextDecoration.lineThrough : null,
                      color: assignment.completed ? Colors.grey : null)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    '${assignment.course.isNotEmpty ? assignment.course + ' • ' : ''}${DateFormat('MMM dd').format(assignment.dueDate)} • ${daysLeft >= 0 ? '$daysLeft days left' : 'Overdue'}',
                    style: TextStyle(
                        color: daysLeft < 0 && !assignment.completed ? Colors.red : Colors.grey[600],
                        fontSize: 12)),
                if (assignment.reminderTime != null)
                  Text('🔔 ${DateFormat('MMM dd, hh:mm a').format(assignment.reminderTime!)}',
                      style: const TextStyle(fontSize: 11, color: _kPrimary)),
                if (assignment.inProgress && !assignment.completed)
                  Container(margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('⏳ In Progress', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold))),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${priority.emoji}', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: _kPrimary, size: 18),
                  onPressed: onEdit,
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
            if (assignment.details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kPrimary.withOpacity(0.15)),
                  ),
                  child: Text(assignment.details,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

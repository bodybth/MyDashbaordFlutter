import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              ]),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (pending.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...pending.map((a) => _AssignmentCard(assignment: a)),
              ],
              if (done.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                ),
                ...done.map((a) => _AssignmentCard(assignment: a)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Assignment Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseCtrl,
                decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: ['Low', 'Medium', 'High', 'Urgent']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => priority = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                  child: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Add Assignment',
                  icon: Icons.add,
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    context.read<StorageService>().addAssignment(Assignment(
                          name: nameCtrl.text.trim(),
                          course: courseCtrl.text.trim(),
                          dueDate: dueDate,
                          priority: priority,
                        ));
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
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  const _AssignmentCard({required this.assignment});

  Color get _priorityColor {
    switch (assignment.priority) {
      case 'Urgent': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.blue;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: assignment.completed,
          activeColor: const Color(0xFF667EEA),
          onChanged: (_) => storage.toggleAssignment(assignment.id),
        ),
        title: Text(
          assignment.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: assignment.completed ? TextDecoration.lineThrough : null,
            color: assignment.completed ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${assignment.course} • ${DateFormat('MMM dd').format(assignment.dueDate)} • ${daysLeft >= 0 ? '$daysLeft days left' : 'Overdue'}',
          style: TextStyle(color: daysLeft < 0 ? Colors.red : Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _priorityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(assignment.priority,
                  style: TextStyle(color: _priorityColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => storage.deleteAssignment(assignment.id),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

class GpaScreen extends StatelessWidget {
  const GpaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📊 GPA Calculator',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCourse(context),
          ),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          if (storage.isExpired) return _expiredWidget();
          return Column(
            children: [
              _GpaCard(gpa: storage.gpa, credits: storage.totalCredits),
              Expanded(
                child: storage.courses.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: storage.courses.length,
                        itemBuilder: (ctx, i) => _CourseCard(
                          course: storage.courses[i],
                          onDelete: () => storage.deleteCourse(storage.courses[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No courses yet\nTap + to add one', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );

  Widget _expiredWidget() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('App access has expired', style: TextStyle(fontSize: 20, color: Colors.grey)),
          ],
        ),
      );

  void _showAddCourse(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedGrade = 'A (4.0)';
    int selectedCredits = 3;

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
              const Text('Add Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'Grade', border: OutlineInputBorder()),
                items: gradeValues.keys
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => selectedGrade = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedCredits,
                decoration: const InputDecoration(labelText: 'Credits', border: OutlineInputBorder()),
                items: [1, 2, 3, 4, 5]
                    .map((c) => DropdownMenuItem(value: c, child: Text('$c credits')))
                    .toList(),
                onChanged: (v) => setState(() => selectedCredits = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Add Course',
                  icon: Icons.add,
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    context.read<StorageService>().addCourse(Course(
                          name: nameCtrl.text.trim(),
                          grade: gradeValues[selectedGrade]!,
                          credits: selectedCredits,
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

class _GpaCard extends StatelessWidget {
  final double gpa;
  final int credits;
  const _GpaCard({required this.gpa, required this.credits});

  Color get _gpaColor {
    if (gpa >= 3.7) return Colors.green;
    if (gpa >= 3.0) return Colors.blue;
    if (gpa >= 2.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(gpa.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Current GPA', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Column(
            children: [
              Text('$credits', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Total Credits', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onDelete;
  const _CourseCard({required this.course, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF667EEA).withOpacity(0.15),
          child: Text(course.grade.toStringAsFixed(1),
              style: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${course.credits} credits'),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
      ),
    );
  }
}

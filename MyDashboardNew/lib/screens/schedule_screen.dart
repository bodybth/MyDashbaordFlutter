import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

const _kPrimary = Color(0xFF667EEA);
const _kSecondary = Color(0xFF764BA2);

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _isHorizontal = false;

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) hour = 12;
      else if (hour > 12) hour -= 12;
      return '${hour}:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📅 Schedule',
        actions: [
          IconButton(
            icon: Icon(_isHorizontal ? Icons.view_list : Icons.grid_on),
            tooltip: _isHorizontal ? 'List View' : 'Table View',
            onPressed: () => setState(() => _isHorizontal = !_isHorizontal),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context)),
        ],
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          if (storage.scheduleItems.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No classes yet\nTap + to add one',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              ]),
            );
          }

          // Group by day
          final grouped = <String, List<ScheduleItem>>{};
          for (final day in weekDays) {
            final items = storage.scheduleItems.where((s) => s.day == day).toList();
            if (items.isNotEmpty) grouped[day] = items;
          }

          if (_isHorizontal) {
            return _HorizontalTableView(grouped: grouped, formatTime: _formatTime, onEdit: (item) {
              Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => _EditScheduleModal(item: item)));
            }, onDelete: (item) => storage.deleteScheduleItem(item.id));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kPrimary, _kSecondary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ...entry.value.map((item) => _ScheduleCard(item: item, formatTime: _formatTime)),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, [ScheduleItem? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    String selectedDay = existing?.day ?? 'Sunday';
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(
            hour: int.parse(existing.time.split(':')[0]),
            minute: int.parse(existing.time.split(':')[1]),
          )
        : const TimeOfDay(hour: 8, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Add Class' : 'Edit Class',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Class Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
              items: weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => selectedDay = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: selectedTime,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => selectedTime = t);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Time (AM/PM)', border: OutlineInputBorder()),
                child: Text(_formatTimeOfDay(selectedTime)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location / Room', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: GradientButton(
              label: existing == null ? 'Add Class' : 'Save Changes',
              icon: existing == null ? Icons.add : Icons.save,
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                final storage = context.read<StorageService>();
                if (existing == null) {
                  storage.addScheduleItem(ScheduleItem(
                    name: nameCtrl.text.trim(), day: selectedDay,
                    time: timeStr, location: locationCtrl.text.trim(),
                  ));
                } else {
                  storage.updateScheduleItem(existing.copyWith(
                    name: nameCtrl.text.trim(), day: selectedDay,
                    time: timeStr, location: locationCtrl.text.trim(),
                  ));
                }
                Navigator.pop(ctx);
              },
            )),
          ]),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ── Horizontal Table View ─────────────────────────────────────────

class _HorizontalTableView extends StatelessWidget {
  final Map<String, List<ScheduleItem>> grouped;
  final String Function(String) formatTime;
  final void Function(ScheduleItem) onEdit;
  final void Function(ScheduleItem) onDelete;

  const _HorizontalTableView({required this.grouped, required this.formatTime, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final days = grouped.keys.toList();
    // Collect all unique times sorted
    final allTimes = grouped.values.expand((items) => items.map((i) => i.time)).toSet().toList()..sort();

    if (days.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(_kPrimary.withOpacity(0.1)),
          columns: [
            const DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
            ...days.map((day) => DataColumn(
              label: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary)),
            )),
          ],
          rows: allTimes.map((time) {
            return DataRow(cells: [
              DataCell(Text(formatTime(time),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary, fontSize: 12))),
              ...days.map((day) {
                final item = grouped[day]?.firstWhere((i) => i.time == time,
                    orElse: () => ScheduleItem(name: '', day: day, time: time, location: ''));
                if (item == null || item.name.isEmpty) return const DataCell(Text('—', style: TextStyle(color: Colors.grey)));
                return DataCell(
                  GestureDetector(
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(item.name),
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          if (item.location.isNotEmpty) Text('📍 ${item.location}'),
                        ]),
                        actions: [
                          TextButton(onPressed: () { Navigator.pop(ctx); onEdit(item); }, child: const Text('Edit')),
                          TextButton(onPressed: () { Navigator.pop(ctx); onDelete(item); },
                              child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kPrimary, _kSecondary]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (item.location.isNotEmpty)
                          Text(item.location, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                      ]),
                    ),
                  ),
                );
              }),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Schedule card & Edit modal ────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final String Function(String) formatTime;
  const _ScheduleCard({required this.item, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(formatTime(item.time),
              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: item.location.isNotEmpty ? Text('📍 ${item.location}') : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _kPrimary),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _EditScheduleModal(item: item),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => storage.deleteScheduleItem(item.id),
          ),
        ]),
      ),
    );
  }
}

class _EditScheduleModal extends StatefulWidget {
  final ScheduleItem item;
  const _EditScheduleModal({required this.item});
  @override
  State<_EditScheduleModal> createState() => _EditScheduleModalState();
}

class _EditScheduleModalState extends State<_EditScheduleModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late String _day;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _locationCtrl = TextEditingController(text: widget.item.location);
    _day = widget.item.day;
    _time = TimeOfDay(
      hour: int.parse(widget.item.time.split(':')[0]),
      minute: int.parse(widget.item.time.split(':')[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Edit Class'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Class Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _day,
            decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
            items: weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _day = v!),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _time,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
              );
              if (t != null) setState(() => _time = t);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Time (AM/PM)', border: OutlineInputBorder()),
              child: Text(_formatTimeOfDay(_time)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location / Room', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: GradientButton(
            label: 'Save Changes',
            icon: Icons.save,
            onPressed: () {
              final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
              context.read<StorageService>().updateScheduleItem(widget.item.copyWith(
                name: _nameCtrl.text.trim(), day: _day,
                time: timeStr, location: _locationCtrl.text.trim(),
              ));
              Navigator.pop(context);
            },
          )),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _tableView = false;

  /// Convert stored "HH:mm" → "hh:mm AM/PM"
  static String _ampm(String t24) {
    try {
      final p = t24.split(':');
      int h = int.parse(p[0]);
      final m = int.parse(p[1]);
      final suf = h >= 12 ? 'PM' : 'AM';
      h = h % 12; if (h == 0) h = 12;
      return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')} $suf';
    } catch (_) { return t24; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: '📅 Schedule',
        actions: <Widget>[
          IconButton(
            tooltip: _tableView ? 'List view' : 'Table view',
            icon: Icon(_tableView ? Icons.view_list_rounded : Icons.table_chart_outlined),
            onPressed: () => setState(() => _tableView = !_tableView)),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _sheet(context, null)),
        ],
      ),
      body: Consumer<StorageService>(builder: (context, storage, _) {
        if (storage.scheduleItems.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No classes yet\nTap + to add one', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
          ]));
        }
        final grouped = <String, List<ScheduleItem>>{};
        for (final day in weekDays) {
          final items = storage.scheduleItems.where((s) => s.day == day).toList();
          if (items.isNotEmpty) grouped[day] = items;
        }
        return _tableView ? _TableView(grouped: grouped, ampm: _ampm, onEdit: _sheet, storage: storage) : _ListView(grouped: grouped, ampm: _ampm, onEdit: _sheet, storage: storage);
      }),
    );
  }

  void _sheet(BuildContext context, ScheduleItem? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    String day = existing?.day ?? 'Sunday';
    TimeOfDay time = existing != null
        ? TimeOfDay(hour: int.parse(existing.time.split(':')[0]), minute: int.parse(existing.time.split(':')[1]))
        : const TimeOfDay(hour: 8, minute: 0);

    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(existing == null ? 'Add Class' : 'Edit Class', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Class Name *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: day,
            decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
            items: weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => ss(() => day = v!)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final t = await showTimePicker(context: ctx, initialTime: time,
                  builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: false), child: child!));
              if (t != null) ss(() => time = t);
            },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Time (AM/PM)', border: OutlineInputBorder()),
              child: Text(time.format(ctx)))),
          const SizedBox(height: 12),
          TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location / Room', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GradientButton(
            label: existing == null ? 'Add Class' : 'Save Changes',
            icon: existing == null ? Icons.add : Icons.save,
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final ts = '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}';
              final storage = context.read<StorageService>();
              if (existing == null) storage.addScheduleItem(ScheduleItem(name: nameCtrl.text.trim(), day: day, time: ts, location: locCtrl.text.trim()));
              else storage.updateScheduleItem(existing.copyWith(name: nameCtrl.text.trim(), day: day, time: ts, location: locCtrl.text.trim()));
              Navigator.pop(ctx);
            })),
        ]))));
  }
}

// ── List View ─────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final Map<String, List<ScheduleItem>> grouped;
  final String Function(String) ampm;
  final void Function(BuildContext, ScheduleItem?) onEdit;
  final StorageService storage;
  const _ListView({required this.grouped, required this.ampm, required this.onEdit, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: grouped.entries.map((e) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(margin: const EdgeInsets.only(top: 12, bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, kSecondary]), borderRadius: BorderRadius.circular(20)),
        child: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ...e.value.map((item) => Card(margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(ampm(item.time), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12))),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: item.location.isNotEmpty ? Text('📍 ${item.location}') : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: kPrimary, size: 20), onPressed: () => onEdit(context, item)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => storage.deleteScheduleItem(item.id)),
          ])))),
    ])).toList());
  }
}

// ── Table View ────────────────────────────────────────────────────
class _TableView extends StatelessWidget {
  final Map<String, List<ScheduleItem>> grouped;
  final String Function(String) ampm;
  final void Function(BuildContext, ScheduleItem?) onEdit;
  final StorageService storage;
  const _TableView({required this.grouped, required this.ampm, required this.onEdit, required this.storage});

  @override
  Widget build(BuildContext context) {
    final days = grouped.keys.toList();
    final maxRows = days.fold<int>(0, (m, d) => grouped[d]!.length > m ? grouped[d]!.length : m);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Table(
          border: TableBorder.all(color: Colors.grey.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
          defaultColumnWidth: const FixedColumnWidth(140),
          children: [
            // Header
            TableRow(decoration: const BoxDecoration(gradient: LinearGradient(colors: [kPrimary, kSecondary])),
              children: days.map((d) => Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(d, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center))).toList()),
            // Data rows
            ...List.generate(maxRows, (row) => TableRow(
              children: days.map((day) {
                final items = grouped[day]!;
                if (row >= items.length) return const SizedBox(height: 64);
                final item = items[row];
                return InkWell(
                  onTap: () => onEdit(context, item),
                  child: Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ampm(item.time), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (item.location.isNotEmpty) Text('📍 ${item.location}', style: TextStyle(fontSize: 10, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Align(alignment: Alignment.centerRight,
                      child: GestureDetector(onTap: () => storage.deleteScheduleItem(item.id),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 16))),
                  ])));
              }).toList())),
          ],
        ),
      ),
    );
  }
}

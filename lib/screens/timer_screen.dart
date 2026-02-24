import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'widgets.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _presets = {
    'Pomodoro': 25, 'Short Break': 5, 'Long Break': 15, 'Deep Focus': 50,
  };

  String _mode = 'Pomodoro';
  int _minutes = 25;
  int _seconds = 0;
  bool _running = false;
  Timer? _timer;
  int _sessions = 0;

  @override
  void initState() { super.initState(); _loadSessions(); }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('timer_sessions_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate == today) {
      if (mounted) setState(() => _sessions = prefs.getInt('timer_sessions_count') ?? 0);
    } else {
      await prefs.setString('timer_sessions_date', today);
      await prefs.setInt('timer_sessions_count', 0);
      if (mounted) setState(() => _sessions = 0);
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_sessions_date', DateTime.now().toIso8601String().substring(0, 10));
    await prefs.setInt('timer_sessions_count', _sessions);
  }

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) { _seconds--; }
        else if (_minutes > 0) { _minutes--; _seconds = 59; }
        else { _timer?.cancel(); _running = false; _sessions++; _saveSessions(); _onTimerDone(); }
      });
    });
  }

  void _pause() { _timer?.cancel(); setState(() => _running = false); }
  void _reset() { _timer?.cancel(); setState(() { _running = false; _minutes = _presets[_mode]!; _seconds = 0; }); }
  void _setMode(String mode) { _timer?.cancel(); setState(() { _mode = mode; _minutes = _presets[mode]!; _seconds = 0; _running = false; }); }

  Future<void> _onTimerDone() async {
    await NotificationService.showImmediate(
      title: '⏱️ $_mode Complete!',
      body: '$_mode session finished. $_sessions sessions done today.',
    );
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('⏰ $_mode Done!'),
      content: Text('Session complete!\n$_sessions sessions today 🔥'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
          onPressed: () { Navigator.pop(context); _reset(); _start(); },
          child: const Text('Start Again'),
        ),
      ],
    ));
  }

  double get _progress {
    final total = _presets[_mode]! * 60;
    return 1.0 - ((_minutes * 60 + _seconds) / total);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isBreak = _mode.contains('Break');
    final accent = isBreak ? Colors.green : const Color(0xFF667EEA);

    return Scaffold(
      appBar: const GradientAppBar(title: '⏱️ Study Timer'),
      body: Column(children: [
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: _presets.keys.map((mode) {
            final selected = _mode == mode;
            return Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(mode), selected: selected,
                onSelected: (_) => _setMode(mode),
                selectedColor: const Color(0xFF667EEA),
                labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.bold),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 40),
        Center(child: SizedBox(width: 240, height: 240,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 240, height: 240,
              child: CircularProgressIndicator(
                value: _progress, strokeWidth: 12,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${_minutes.toString().padLeft(2,'0')}:${_seconds.toString().padLeft(2,'0')}',
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: accent)),
              Text(_mode, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              if (_running) const Padding(padding: EdgeInsets.only(top: 4),
                child: Text('● RUNNING', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
            ]),
          ]),
        )),
        const SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: Icon(Icons.refresh, size: 32, color: Colors.grey[500]), onPressed: _reset, tooltip: 'Reset'),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _running ? _pause : _start,
            child: Container(width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isBreak
                    ? [Colors.green, Colors.teal]
                    : [const Color(0xFF667EEA), const Color(0xFF764BA2)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))],
              ),
              child: Icon(_running ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(icon: Icon(Icons.skip_next, size: 32, color: Colors.grey[500]), onPressed: _onTimerDone, tooltip: 'Skip'),
        ]),
        const SizedBox(height: 32),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF667EEA).withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.local_fire_department, color: Color(0xFF667EEA)),
            const SizedBox(width: 8),
            Text('$_sessions sessions completed today',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF667EEA))),
          ]),
        ),
      ]),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'widgets.dart';

// Timer uses AutomaticKeepAliveClientMixin to survive tab switches
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // <-- keeps timer alive when switching tabs

  static const _presets = {
    'Pomodoro': 25,
    'Short Break': 5,
    'Long Break': 15,
    'Deep Focus': 50,
  };

  String _mode = 'Pomodoro';
  int _minutes = 25;
  int _seconds = 0;
  bool _running = false;
  Timer? _timer;
  int _sessions = 0;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('timer_sessions_date', today);
    await prefs.setInt('timer_sessions_count', _sessions);
  }

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else if (_minutes > 0) {
          _minutes--;
          _seconds = 59;
        } else {
          _timer?.cancel();
          _running = false;
          _sessions++;
          _saveSessions();
          _onTimerDone();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _minutes = _presets[_mode]!;
      _seconds = 0;
    });
  }

  void _setMode(String mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _minutes = _presets[mode]!;
      _seconds = 0;
      _running = false;
    });
  }

  Future<void> _onTimerDone() async {
    // Send notification so user is alerted even if phone is locked
    await NotificationService.showImmediate(
      title: '⏱️ $_mode Complete!',
      body: '$_mode session finished. ${_sessions} sessions done today. Take a break!',
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
      ),
    );
  }

  double get _progress {
    final total = _presets[_mode]! * 60;
    final remaining = _minutes * 60 + _seconds;
    return 1.0 - (remaining / total);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: const GradientAppBar(title: '⏱️ Study Timer'),
      body: Column(children: [
        const SizedBox(height: 20),
        // Mode chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _presets.keys.map((mode) {
              final selected = _mode == mode;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(mode),
                  selected: selected,
                  onSelected: (_) => _setMode(mode),
                  selectedColor: const Color(0xFF667EEA),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),
        // Timer circle
        Center(
          child: SizedBox(
            width: 240, height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240, height: 240,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      _mode.contains('Break') ? Colors.green : const Color(0xFF667EEA),
                    ),
                  ),
                ),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 56, fontWeight: FontWeight.bold,
                      color: _mode.contains('Break') ? Colors.green : const Color(0xFF667EEA),
                    ),
                  ),
                  Text(_mode, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  if (_running)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('● RUNNING', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 32, color: Colors.grey),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _running ? _pause : _start,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _mode.contains('Break')
                      ? [Colors.green, Colors.teal]
                      : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4),
                )],
              ),
              child: Icon(_running ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.skip_next, size: 32, color: Colors.grey),
            onPressed: _onTimerDone,
            tooltip: 'Skip',
          ),
        ]),
        const SizedBox(height: 32),
        // Sessions counter
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
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

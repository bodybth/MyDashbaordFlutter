import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const _presets = {'Pomodoro': 25, 'Short Break': 5, 'Long Break': 15, 'Deep Focus': 50};
  String _mode = 'Pomodoro';
  int _minutes = 25;
  int _seconds = 0;
  bool _running = false;
  Timer? _timer;
  int _sessions = 0;

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else if (_minutes > 0) {
        setState(() { _minutes--; _seconds = 59; });
      } else {
        _timer?.cancel();
        setState(() { _running = false; _sessions++; });
        _showDoneDialog();
      }
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

  void _showDoneDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⏰ Time is up!'),
        content: Text('$_mode session complete!\n$_sessions sessions done today.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          TextButton(
            onPressed: () { Navigator.pop(context); _reset(); _start(); },
            child: const Text('Start Again'),
          ),
        ],
      ),
    );
  }

  double get _progress {
    final total = _presets[_mode]! * 60;
    final elapsed = total - (_minutes * 60 + _seconds);
    return elapsed / total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: '⏱️ Study Timer'),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Mode selector
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
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 40),
          // Timer circle
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF667EEA)),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
                      ),
                      Text(_mode, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 32),
                onPressed: _reset,
                color: Colors.grey,
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _running ? _pause : _start,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_running ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Sessions count
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFF667EEA)),
                const SizedBox(width: 8),
                Text('$_sessions sessions completed today',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF667EEA))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

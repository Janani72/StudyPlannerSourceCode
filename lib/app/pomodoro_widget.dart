import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroWidget extends StatefulWidget {
  final VoidCallback? onSessionDone;
  const PomodoroWidget({super.key, this.onSessionDone});
  @override
  State<PomodoroWidget> createState() => _PomodoroWidgetState();
}

class _PomodoroWidgetState extends State<PomodoroWidget> {
  int secs = 25 * 60;
  Timer? timer;
  bool running = false;

  void _toggle() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (secs > 0) {
            secs--;
          } else {
            timer?.cancel();
            running = false;
            widget.onSessionDone?.call();
          }
        });
      });
      setState(() => running = true);
    }
  }

  void _reset() {
    timer?.cancel();
    setState(() {
      secs = 25 * 60;
      running = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        Text('$m:$s',
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold)),
        const Spacer(),
        FilledButton.icon(
          onPressed: _toggle,
          icon: Icon(running ? Icons.pause : Icons.play_arrow),
          label: Text(running ? 'Pause' : 'Start'),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/constants/app_colors.dart';

class TimerWidget extends StatefulWidget {
  final DateTime startTime;
  final Duration? elapsed;
  final VoidCallback? onTimeUpdate;

  const TimerWidget({
    super.key,
    required this.startTime,
    this.elapsed,
    this.onTimeUpdate,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _baseElapsed = Duration.zero;
  DateTime _runStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _baseElapsed =
        widget.elapsed ?? DateTime.now().difference(widget.startTime);
    _elapsed = _baseElapsed;
    _runStartedAt = DateTime.now();
    _startTimer();
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsed != widget.elapsed && widget.elapsed != null) {
      _baseElapsed = widget.elapsed!;
      _elapsed = widget.elapsed!;
      _runStartedAt = DateTime.now();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = _baseElapsed + DateTime.now().difference(_runStartedAt);
      });
      widget.onTimeUpdate?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: AppColors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime expiryTime;
  final VoidCallback? onExpired;
  final Color? textColor;
  final Color? warningColor;
  final TextStyle? textStyle;
  final bool showWarningBelow30s;
  final bool allowExpiredCallback;

  const CountdownTimer({
    super.key,
    required this.expiryTime,
    this.onExpired,
    this.textColor,
    this.warningColor,
    this.textStyle,
    this.showWarningBelow30s = true,
    this.allowExpiredCallback = true,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiryTime != widget.expiryTime) {
      _calculateTimeRemaining();
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.expiryTime)) {
      _timeRemaining = Duration.zero;
      _isExpired = true;
    } else {
      _timeRemaining = widget.expiryTime.difference(now);
      _isExpired = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeRemaining();

      if (_isExpired &&
          widget.onExpired != null &&
          widget.allowExpiredCallback) {
        print('⏰ COUNTDOWN TIMER: Calling onExpired callback');
        widget.onExpired!();
        _timer?.cancel();
      } else if (_isExpired &&
          widget.onExpired != null &&
          !widget.allowExpiredCallback) {
        print(
          '🔒 COUNTDOWN TIMER: Expiry blocked - allowExpiredCallback=false',
        );
        _timer?.cancel();
      }

      setState(() {});
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _showWarning =>
      widget.showWarningBelow30s &&
      _timeRemaining.inSeconds <= 30 &&
      !_isExpired;

  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return Text(
        'EXPIRED',
        style:
            widget.textStyle?.copyWith(
              color: widget.warningColor ?? Colors.red,
              fontWeight: FontWeight.bold,
            ) ??
            TextStyle(
              color: widget.warningColor ?? Colors.red,
              fontWeight: FontWeight.bold,
            ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showWarning) ...[
          Icon(
            Icons.warning_amber_rounded,
            color: widget.warningColor ?? Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatTime(_timeRemaining),
          style:
              widget.textStyle?.copyWith(
                color:
                    _showWarning
                        ? (widget.warningColor ?? Colors.orange)
                        : (widget.textColor ?? Colors.black),
                fontWeight: _showWarning ? FontWeight.bold : null,
              ) ??
              TextStyle(
                color:
                    _showWarning
                        ? (widget.warningColor ?? Colors.orange)
                        : (widget.textColor ?? Colors.black),
                fontWeight: _showWarning ? FontWeight.bold : null,
              ),
        ),
      ],
    );
  }
}

class CountdownBanner extends StatelessWidget {
  final DateTime expiryTime;
  final VoidCallback? onExpired;
  final String? requestStatus;

  const CountdownBanner({
    super.key,
    required this.expiryTime,
    this.onExpired,
    this.requestStatus,
  });

  @override
  Widget build(BuildContext context) {
    final timeRemaining = expiryTime.difference(DateTime.now());

    // Only show banner when less than 30 seconds remain
    if (timeRemaining.inSeconds > 30 || timeRemaining.isNegative) {
      return const SizedBox.shrink();
    }

    // Don't show banner for confirmed requests
    if (requestStatus == 'confirmed') {
      print('🔒 COUNTDOWN BANNER: Hidden for confirmed request');
      return const SizedBox.shrink();
    }

    // Disable onExpired callback for confirmed requests
    final allowExpiredCallback = requestStatus != 'confirmed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ride request expires in:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          CountdownTimer(
            expiryTime: expiryTime,
            onExpired: onExpired,
            textColor: Colors.white,
            warningColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            showWarningBelow30s: true, // Banner itself is the warning
            allowExpiredCallback: allowExpiredCallback,
          ),
        ],
      ),
    );
  }
}

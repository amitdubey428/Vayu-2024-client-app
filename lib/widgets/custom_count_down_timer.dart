import 'dart:async';
import 'package:flutter/material.dart';

class Countdown extends StatefulWidget {
  final Duration duration;
  final VoidCallback onFinish;
  final Widget Function(BuildContext, Duration) builder;
  final Function(Duration)? onReset; // Optional callback for external reset

  const Countdown({
    super.key,
    required this.duration,
    required this.onFinish,
    required this.builder,
    this.onReset,
  });

  @override
  CountdownState createState() => CountdownState();
}

class CountdownState extends State<Countdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    resetTimer(widget.duration);
  }

  void resetTimer(Duration duration) {
    setState(() {
      _timer?.cancel();
      _remaining = duration;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remaining.inSeconds <= 0) {
          _timer?.cancel();
          widget.onFinish();
        } else {
          setState(() {
            _remaining -= const Duration(seconds: 1);
          });
        }
      });
    });
    if (widget.onReset != null) {
      widget.onReset!(duration);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _remaining);
  }
}

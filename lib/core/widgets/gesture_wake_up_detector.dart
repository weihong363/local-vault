import 'package:flutter/material.dart';

class GestureWakeUpDetector extends StatelessWidget {
  final VoidCallback onGestureDetected;

  const GestureWakeUpDetector({
    super.key,
    required this.onGestureDetected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onGestureDetected,
      child: Container(),
    );
  }
}

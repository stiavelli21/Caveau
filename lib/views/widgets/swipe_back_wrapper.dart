import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget wrapper that enables returning to the previous screen by swiping
/// from left to right across the screen.
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeBack;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.onSwipeBack,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper> {
  double _dragDistance = 0;

  void _handleDragStart(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? details.delta.dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;
    // Check if the gesture is a deliberate left-to-right swipe
    if (velocity > 250 || (velocity >= 0 && _dragDistance > 80)) {
      HapticFeedback.lightImpact();
      if (widget.onSwipeBack != null) {
        widget.onSwipeBack!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: widget.child,
    );
  }
}

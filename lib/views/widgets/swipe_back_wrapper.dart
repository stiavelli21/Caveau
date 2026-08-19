import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gesture wrapper that enables popping/dismissing screens via left-to-right swipe gestures.
/// 
/// Provides native-like iOS interactive pop gesture behavior uniformly across Android and iOS,
/// complete with haptic feedback when triggered.
class SwipeBackWrapper extends StatefulWidget {
  /// The underlying screen widget wrapped by this gesture detector.
  final Widget child;

  /// Optional custom callback executed instead of default `Navigator.of(context).pop()`.
  final VoidCallback? onSwipeBack;

  /// Creates a [SwipeBackWrapper] around [child].
  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.onSwipeBack,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper> {
  /// Cumulative horizontal drag distance during the current gesture.
  double _dragDistance = 0;

  void _handleDragStart(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? details.delta.dx;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx;
    
    // Check if the gesture is a deliberate left-to-right swipe (high velocity > 250 px/s or distance > 80 px)
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

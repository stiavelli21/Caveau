import 'package:flutter/material.dart';

/// Responsive breakpoint constant for desktop/widescreen layouts.
const double kDesktopBreakpoint = 900.0;

/// Helper returning `true` if current viewport width qualifies as desktop / horizontal widescreen.
bool isDesktopView(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
}

/// Helper returning `true` if current viewport width is standard mobile portrait.
bool isMobileView(BuildContext context) {
  return MediaQuery.sizeOf(context).width < kDesktopBreakpoint;
}

/// Widget providing separate builders for mobile and desktop viewport sizes.
class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktopView(context)) {
      return desktop(context);
    }
    return mobile(context);
  }
}

/// Centered container wrapper for desktop screens (LockScreen, Onboarding, Generator, Settings).
class DesktopCenteredCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const DesktopCenteredCard({
    super.key,
    required this.child,
    this.maxWidth = 480.0,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    if (isMobileView(context)) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

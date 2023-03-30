import 'package:flutter/material.dart';

class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior() : super();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
        return StretchingOverscrollIndicator(
          axisDirection: details.direction,
          child: child,
        );
      case TargetPlatform.fuchsia:
        return StretchingOverscrollIndicator(
          axisDirection: details.direction,
          child: child,
        );
    }
  }
}

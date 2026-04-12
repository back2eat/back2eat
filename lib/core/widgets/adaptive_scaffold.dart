import 'package:flutter/material.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  const AdaptiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    // Tablet/Desktop → constrain content width (pixel perfect)
    final maxWidth = w >= 900 ? 520.0 : (w >= 600 ? 520.0 : double.infinity);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

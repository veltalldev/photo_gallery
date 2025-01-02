import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomSheet;

  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface,
                ],
                stops: const [
                  0.0,
                  0.3,
                  0.4,
                  1.0,
                ],
                tileMode: TileMode.clamp,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: child,
          ),
        ],
      ),
      bottomSheet: bottomSheet,
    );
  }
}

import 'package:flutter/material.dart';

class SplashscreenView extends StatefulWidget {
  const SplashscreenView({super.key});

  @override
  State<SplashscreenView> createState() => _SplashscreenViewState();
}

class _SplashscreenViewState extends State<SplashscreenView> {
  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        color: themeColors.primaryContainer,
        child: Center(
          child: Icon(Icons.explore, color: themeColors.onPrimaryContainer),
        ),
      ),
    );
  }
}

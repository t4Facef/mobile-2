import 'package:flutter/material.dart';
import 'package:mobile_2_bim/views/map_view.dart';

class SplashscreenView extends StatefulWidget {
  const SplashscreenView({super.key});

  @override
  State<SplashscreenView> createState() => _SplashscreenViewState();
}

class _SplashscreenViewState extends State<SplashscreenView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MapView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        color: themeColors.secondary,
        child: Center(
          child: Icon(
            Icons.explore_outlined,
            color: themeColors.onPrimaryContainer,
            size: 80,
          ),
        ),
      ),
    );
  }
}

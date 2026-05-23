import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.body,
    this.floatingActionButton,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.3,
        title: Row(
          children: [
            Icon(Icons.explore, color: themeColors.primary, size: 30),
            SizedBox(width: 6),
            Text(
              'RouteAI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: themeColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.list_alt),
                    Text(
                      "Entregas",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: themeColors.primaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: themeColors.surfaceContainerLowest,
                        ),
                        Text(
                          "Rota",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: themeColors.surfaceContainerLowest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

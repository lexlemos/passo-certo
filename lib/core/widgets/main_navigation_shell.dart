import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_scaffold.dart';
import 'navbar.dart';

class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: navigationShell,
      bottomNavigationBar: NavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

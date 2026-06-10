import 'package:flutter/material.dart';

import '../../features/navigation/presentation/pages/profile_page.dart';
import '../../features/navigation/presentation/pages/route_planning_page.dart';
import 'navbar.dart';

/// O shell principal do aplicativo Passo Certo.
///
/// Este Scaffold gerencia a navegação entre as abas principais usando um [IndexedStack]
/// para preservar o estado visual e o foco de acessibilidade das páginas de forma performática.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    RoutePlanningPage(),
    Center(
      child: Text(
        'Comunidade',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

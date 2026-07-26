import 'package:flutter/material.dart';

/// Um componente de barra de navegação inferior reutilizável e acessível com 4 abas.
class NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: navTheme.backgroundColor ?? theme.colorScheme.surface,
        selectedItemColor:
            navTheme.selectedItemColor ?? theme.colorScheme.primary,
        unselectedItemColor:
            navTheme.unselectedItemColor ??
            theme.colorScheme.onSurface.withValues(alpha: 0.6),
        selectedLabelStyle: navTheme.selectedLabelStyle,
        unselectedLabelStyle: navTheme.unselectedLabelStyle,
        type: navTheme.type ?? BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Semantics(
              label: 'Aba Início',
              hint: 'Toque duas vezes para navegar para a tela inicial',
              selected: currentIndex == 0,
              button: true,
              child: const Icon(Icons.home),
            ),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: 'Aba Rotas',
              hint: 'Toque duas vezes para planejar o seu trajeto',
              selected: currentIndex == 1,
              button: true,
              child: const Icon(Icons.map),
            ),
            label: 'Rotas',
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: 'Aba Comunidade',
              hint: 'Toque duas vezes para navegar para a comunidade',
              selected: currentIndex == 2,
              button: true,
              child: const Icon(Icons.people),
            ),
            label: 'Comunidade',
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: 'Aba Perfil',
              hint: 'Toque duas vezes para acessar suas informações de perfil',
              selected: currentIndex == 3,
              button: true,
              child: const Icon(Icons.person),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

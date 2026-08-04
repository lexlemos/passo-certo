import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// O shell de layout principal do aplicativo Passo Certo.
///
/// Este Scaffold recebe o [body] (a tela ativa) e a [bottomNavigationBar]
/// como parâmetros, fornecendo uma AppBar customizada e acessível.
class MainScaffold extends StatelessWidget {
  final Widget body;
  final Widget bottomNavigationBar;

  const MainScaffold({
    super.key,
    required this.body,
    required this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 130,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: SvgPicture.asset(
            'assets/images/Logo_passoufs.svg',
            height: 40,
            fit: BoxFit.contain,
            semanticsLabel: 'Logo PassoUFS',
            alignment: Alignment.centerLeft,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              semanticLabel: 'Notificações',
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

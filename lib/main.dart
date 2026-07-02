import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/routes/presentation/bloc/route_planning_bloc.dart';

void main() async {
  // Garante a inicialização correta dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o container de injeção de dependências
  await di.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoutePlanningBloc>(
      create: (context) => di.sl<RoutePlanningBloc>(),
      child: MaterialApp.router(
        title: 'Passo Certo',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

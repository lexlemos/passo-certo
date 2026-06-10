import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/widgets/main_scaffold.dart';
import 'features/navigation/presentation/bloc/profile_bloc.dart';
import 'features/navigation/presentation/bloc/route_planning_bloc.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoutePlanningBloc>(
          create: (context) => di.sl<RoutePlanningBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => di.sl<ProfileBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Passo Certo',
        theme: AppTheme.lightTheme,
        home: const MainScaffold(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

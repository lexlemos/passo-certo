import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/community/presentation/bloc/obstacle_bloc.dart';

void main() async {
  // Garante a inicialização correta dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis de ambiente (.env)
  await dotenv.load(fileName: ".env");

  // Configura o armazenamento em disco para HydratedBloc
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  // Inicializa o container de injeção de dependências
  await di.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ObstacleBloc>(
      create: (context) => di.sl<ObstacleBloc>(),
      child: MaterialApp.router(
        title: 'Passo Certo',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

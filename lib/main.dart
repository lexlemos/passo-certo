import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/community/presentation/bloc/obstacle_bloc.dart';

void main() async {
  // Garante a inicialização correta dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis de ambiente (.env)
  await dotenv.load(fileName: '.env');

  // Inicializa o cliente Supabase com as chaves do ambiente
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
    return MultiBlocProvider(
      providers: [
        // AuthBloc no topo da árvore: disponível em todas as rotas.
        // O AuthWrapper dispara AuthCheckRequested no initState.
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        // ObstacleBloc disponível globalmente (mapa usa em múltiplas rotas).
        BlocProvider<ObstacleBloc>(
          create: (_) => di.sl<ObstacleBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Passo Certo',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

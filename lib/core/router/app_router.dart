import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_wrapper.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/routes/presentation/pages/route_planning_page.dart';
import '../../features/routes/presentation/bloc/route_planning_bloc.dart';
import '../../features/routes/presentation/bloc/active_navigation_bloc.dart';
import '../../features/routes/presentation/bloc/add_place_bloc.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/main_navigation_shell.dart';
import '../di/injection_container.dart' as di;

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Configuração declarativa de rotas do aplicativo.
///
/// ## Hierarquia de rotas
///
/// ```
/// /                 → AuthWrapper (splash + portão de auth)
/// /login            → LoginPage
/// /signup           → (futura tela de cadastro)
/// /home             → HomePage       ┐
/// /routes           → RoutePlanningPage ├ dentro do StatefulShellRoute
/// /profile          → ProfilePage    ┘
/// ```
///
/// O redirecionamento pós-auth é feito pelo próprio [AuthWrapper] via
/// `context.go()`, mantendo o GoRouter como fonte de verdade da navegação.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ── Splash / Auth Gate ─────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),

    // ── Autenticação ───────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),

    // ── App Principal (com BottomNavigationBar) ────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/routes',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider<RoutePlanningBloc>(
                    create: (context) => di.sl<RoutePlanningBloc>(),
                  ),
                  BlocProvider<ActiveNavigationBloc>(
                    create: (context) => di.sl<ActiveNavigationBloc>(),
                  ),
                  BlocProvider<AddPlaceBloc>(
                    create: (context) => di.sl<AddPlaceBloc>(),
                  ),
                ],
                child: const RoutePlanningPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/routes/presentation/pages/route_planning_page.dart';
import '../../features/routes/presentation/bloc/route_planning_bloc.dart';
import '../../features/routes/presentation/bloc/active_navigation_bloc.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/main_navigation_shell.dart';
import '../di/injection_container.dart' as di;

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
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
                ],
                child: const RoutePlanningPage(),
              ),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityPage(),
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

import 'package:get_it/get_it.dart';

import '../../features/routes/data/repositories/mock_route_repository_impl.dart';
import '../../features/routes/domain/repositories/route_repository.dart';
import '../../features/routes/domain/usecases/get_recommended_route.dart';
import '../../features/routes/domain/usecases/get_routes.dart';
import '../../features/profile/domain/usecases/validate_emergency_contact.dart';
import '../../features/profile/presentation/bloc/profile_navigation_bloc.dart';
import '../../features/profile/presentation/bloc/profile_emergency_bloc.dart';
import '../../features/routes/presentation/bloc/route_planning_bloc.dart';

/// Instância do localizador de serviços global.
final sl = GetIt.instance;

/// Inicializa as dependências do projeto.
Future<void> init() async {
  // --- Presentation Layer (BLoCs) ---
  // Registra instâncias do tipo Factory, para criar uma nova instância a cada solicitação.
  sl.registerFactory(() => RoutePlanningBloc(
        getRoutesUseCase: sl(),
        getRecommendedRouteUseCase: sl(),
      ));
  sl.registerFactory(() => ProfileNavigationBloc());
  sl.registerFactory(() => ProfileEmergencyBloc(validateEmergencyContactUseCase: sl()));

  // --- Domain Layer (Use Cases) ---
  // Registra instâncias LazySingleton, que criam e cacheiam uma instância única somente quando solicitadas.
  sl.registerLazySingleton(() => GetRoutesUseCase(sl()));
  sl.registerLazySingleton(() => GetRecommendedRouteUseCase(sl()));
  sl.registerLazySingleton(() => ValidateEmergencyContactUseCase());

  // --- Data Layer (Repositories) ---
  sl.registerLazySingleton<RouteRepository>(() => MockRouteRepositoryImpl());
}

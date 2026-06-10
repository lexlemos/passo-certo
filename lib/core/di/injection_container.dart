import 'package:get_it/get_it.dart';

import '../../features/navigation/domain/usecases/get_recommended_route.dart';
import '../../features/navigation/domain/usecases/validate_emergency_contact.dart';
import '../../features/navigation/presentation/bloc/profile_bloc.dart';
import '../../features/navigation/presentation/bloc/route_planning_bloc.dart';

/// Instância do localizador de serviços global.
final sl = GetIt.instance;

/// Inicializa as dependências do projeto.
Future<void> init() async {
  // --- Presentation Layer (BLoCs) ---
  // Registra instâncias do tipo Factory, para criar uma nova instância a cada solicitação.
  sl.registerFactory(() => RoutePlanningBloc(getRecommendedRouteUseCase: sl()));
  sl.registerFactory(() => ProfileBloc(validateEmergencyContactUseCase: sl()));

  // --- Domain Layer (Use Cases) ---
  // Registra instâncias LazySingleton, que criam e cacheiam uma instância única somente quando solicitadas.
  sl.registerLazySingleton(() => GetRecommendedRouteUseCase());
  sl.registerLazySingleton(() => ValidateEmergencyContactUseCase());
}

import 'package:get_it/get_it.dart';

import '../../features/routes/data/repositories/ors_route_repository_impl.dart';
import '../../features/routes/domain/repositories/route_repository.dart';
import '../../features/routes/domain/usecases/get_recommended_route.dart';
import '../../features/routes/domain/usecases/get_routes.dart';
import '../../features/routes/domain/usecases/calculate_accessible_route.dart';
import '../../features/profile/domain/usecases/validate_emergency_contact.dart';
import '../../features/profile/presentation/bloc/profile_navigation_bloc.dart';
import '../../features/profile/presentation/bloc/profile_emergency_bloc.dart';
import '../../features/routes/presentation/bloc/route_planning_bloc.dart';
import '../../features/routes/data/repositories/nominatim_geocoding_repository_impl.dart';
import '../../features/routes/domain/repositories/geocoding_repository.dart';
import '../../features/routes/domain/usecases/search_address.dart';
import '../../features/routes/domain/services/voice_navigation_service.dart';
import '../../features/routes/data/services/flutter_tts_service_impl.dart';
import '../../features/routes/presentation/bloc/active_navigation_bloc.dart';
import '../../features/routes/domain/usecases/get_current_location_place.dart';
import '../../features/routes/domain/repositories/location_tracking_repository.dart';
import '../../features/routes/data/repositories/geolocator_tracking_repository_impl.dart';

import '../../features/community/data/repositories/in_memory_obstacle_repository_impl.dart';
import '../../features/community/domain/repositories/obstacle_repository.dart';
import '../../features/community/domain/usecases/get_obstacles.dart';
import '../../features/community/domain/usecases/report_obstacle.dart';
import '../../features/community/presentation/bloc/obstacle_bloc.dart';

/// Instância do localizador de serviços global.
final sl = GetIt.instance;

/// Inicializa as dependências do projeto.
Future<void> init() async {
  // --- Presentation Layer (BLoCs) ---
  // Registra instâncias do tipo Factory, para criar uma nova instância a cada solicitação.
  sl.registerFactory(() => RoutePlanningBloc(
        calculateAccessibleRouteUseCase: sl(),
        profileNavigationBloc: sl(),
        getCurrentLocationPlaceUseCase: sl(),
      ));
  sl.registerLazySingleton(() => ProfileNavigationBloc());
  sl.registerFactory(() => ProfileEmergencyBloc(validateEmergencyContactUseCase: sl()));
  sl.registerFactory(() => ObstacleBloc(
        getObstaclesUseCase: sl(),
        reportObstacleUseCase: sl(),
      ));
  sl.registerFactory(() => ActiveNavigationBloc(
        voiceService: sl(),
        locationTrackingRepository: sl(),
        calculateAccessibleRouteUseCase: sl(),
      ));

  // --- Domain Layer (Use Cases) ---
  // Registra instâncias LazySingleton, que criam e cacheiam uma instância única somente quando solicitadas.
  sl.registerLazySingleton(() => GetRoutesUseCase(sl()));
  sl.registerLazySingleton(() => GetRecommendedRouteUseCase(sl()));
  sl.registerLazySingleton(() => ValidateEmergencyContactUseCase());
  sl.registerLazySingleton(() => GetObstaclesUseCase(sl()));
  sl.registerLazySingleton(() => ReportObstacleUseCase(sl()));
  sl.registerLazySingleton(() => CalculateAccessibleRouteUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SearchAddressUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentLocationPlaceUseCase(sl()));

  // --- Data Layer (Repositories) ---
  sl.registerLazySingleton<RouteRepository>(() => ORSRouteRepositoryImpl());
  sl.registerLazySingleton<ObstacleRepository>(() => InMemoryObstacleRepositoryImpl());
  sl.registerLazySingleton<GeocodingRepository>(() => NominatimGeocodingRepositoryImpl());
  sl.registerLazySingleton<VoiceNavigationService>(() => FlutterTtsServiceImpl());
  sl.registerLazySingleton<LocationTrackingRepository>(() => GeolocatorTrackingRepositoryImpl());
}

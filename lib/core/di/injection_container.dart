import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../features/routes/data/repositories/ors_route_repository_impl.dart';
import '../../features/routes/data/repositories/supabase_place_repository_impl.dart';
import '../../features/routes/domain/repositories/place_repository.dart';
import '../../features/routes/domain/repositories/route_repository.dart';
import '../../features/routes/domain/usecases/get_recommended_route.dart';
import '../../features/routes/domain/usecases/get_routes.dart';
import '../../features/routes/domain/usecases/calculate_accessible_route.dart';
import '../../features/routes/domain/usecases/get_recent_searches.dart';
import '../../features/routes/domain/usecases/save_recent_search.dart';
import '../../features/routes/domain/usecases/add_place.dart';
import '../../features/routes/domain/usecases/delete_place.dart';
import '../../features/profile/domain/usecases/validate_emergency_contact.dart';
import '../../features/profile/presentation/bloc/profile_navigation_bloc.dart';
import '../../features/profile/presentation/bloc/profile_emergency_bloc.dart';
import '../../features/routes/presentation/bloc/route_planning_bloc.dart';
import '../../features/routes/presentation/bloc/add_place_bloc.dart';
import '../../features/routes/data/repositories/nominatim_geocoding_repository_impl.dart';
import '../../features/routes/domain/repositories/geocoding_repository.dart';
import '../../features/routes/domain/usecases/search_address.dart';
import '../../features/routes/domain/services/voice_navigation_service.dart';
import '../../features/routes/data/services/flutter_tts_service_impl.dart';
import '../../features/routes/presentation/bloc/active_navigation_bloc.dart';
import '../../features/routes/domain/usecases/get_current_location_place.dart';
import '../../features/routes/domain/repositories/location_tracking_repository.dart';
import '../../features/routes/data/repositories/geolocator_tracking_repository_impl.dart';
import '../../features/routes/data/datasources/recent_search_local_data_source.dart';
import '../../features/routes/domain/repositories/recent_search_repository.dart';
import '../../features/routes/data/repositories/recent_search_repository_impl.dart';

import '../../features/community/data/datasources/obstacle_local_data_source.dart';
import '../../features/community/data/repositories/supabase_obstacle_repository_impl.dart';
import '../../features/community/domain/repositories/obstacle_repository.dart';
import '../../features/community/domain/usecases/delete_obstacle.dart';
import '../../features/community/domain/usecases/get_obstacles.dart';
import '../../features/community/domain/usecases/report_obstacle.dart';
import '../../features/community/presentation/bloc/obstacle_bloc.dart';
import '../../features/community/presentation/bloc/community_bloc.dart';
import '../services/location_service.dart';
import '../services/geolocator_location_service_impl.dart';

import '../../features/auth/data/repositories/supabase_auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/get_current_user_id.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/domain/usecases/update_profile.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Instância do localizador de serviços global.
final sl = GetIt.instance;

/// Inicializa as dependências do projeto.
Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // --- Presentation Layer (BLoCs) ---
  // Registra instâncias do tipo Factory, para criar uma nova instância a cada solicitação.
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUserUseCase: sl(),
      signInUseCase: sl(),
      signUpUseCase: sl(),
      signOutUseCase: sl(),
      updateProfileUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => RoutePlanningBloc(
      calculateAccessibleRouteUseCase: sl(),
      preferencesReader: sl<ProfileNavigationBloc>(),
      getCurrentLocationPlaceUseCase: sl(),
      getObstaclesUseCase: sl(),
      saveRecentSearchUseCase: sl(),
      getRecentSearchesUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => ProfileNavigationBloc());
  sl.registerFactory(
    () => ProfileEmergencyBloc(validateEmergencyContactUseCase: sl()),
  );
  sl.registerFactory(
    () => ObstacleBloc(
      getObstaclesUseCase: sl(),
      reportObstacleUseCase: sl(),
      deleteObstacleUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => AddPlaceBloc(addPlaceUseCase: sl(), deletePlaceUseCase: sl()),
  );
  sl.registerFactory(() => CommunityBloc());
  sl.registerFactory(
    () => ActiveNavigationBloc(
      voiceService: sl(),
      locationTrackingRepository: sl(),
      calculateAccessibleRouteUseCase: sl(),
      getObstaclesUseCase: sl(),
      preferencesReader: sl<ProfileNavigationBloc>(),
    ),
  );

  // --- Domain Layer (Use Cases) ---
  // Registra instâncias LazySingleton, que criam e cacheiam uma instância única somente quando solicitadas.
  sl.registerLazySingleton(() => GetRoutesUseCase(sl()));
  sl.registerLazySingleton(() => GetRecommendedRouteUseCase(sl()));
  sl.registerLazySingleton(() => ValidateEmergencyContactUseCase());
  sl.registerLazySingleton(() => GetObstaclesUseCase(sl()));
  sl.registerLazySingleton(() => ReportObstacleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteObstacleUseCase(sl()));
  sl.registerLazySingleton(
    () => CalculateAccessibleRouteUseCase(sl()),
  );
  sl.registerLazySingleton(
    () =>
        SearchAddressUseCase(placeRepository: sl(), geocodingRepository: sl()),
  );
  sl.registerLazySingleton(() => GetCurrentLocationPlaceUseCase(sl(), sl()));
  sl.registerLazySingleton(() => AddPlaceUseCase(sl()));
  sl.registerLazySingleton(() => DeletePlaceUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentSearchesUseCase(sl()));
  sl.registerLazySingleton(() => SaveRecentSearchUseCase(sl()));
  // Auth use cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserIdUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  // --- Data Layer (External) ---
  // O SupabaseClient é um singleton já inicializado no main(); apenas o referenciamos aqui.
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // --- Data Layer (Repositories) ---
  sl.registerLazySingleton<http.Client>(
    () => http.Client(),
    dispose: (client) => client.close(),
  );

  sl.registerLazySingleton<RouteRepository>(
    () => ORSRouteRepositoryImpl(client: sl()),
  );
  sl.registerLazySingleton<ObstacleLocalDataSource>(
    () => ObstacleLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ObstacleRepository>(
    () => SupabaseObstacleRepositoryImpl(
      supabaseClient: sl(),
      localDataSource: sl(),
    ),
  );
  // Auth repository — LazySingleton: uma única instância por ciclo de vida do app,
  // pois a sessão Supabase é global e gerenciada pelo GoTrueClient interno.
  sl.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepositoryImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<GeocodingRepository>(
    () => NominatimGeocodingRepositoryImpl(client: sl()),
  );
  sl.registerLazySingleton<VoiceNavigationService>(
    () => FlutterTtsServiceImpl(),
  );
  sl.registerLazySingleton<LocationTrackingRepository>(
    () => GeolocatorTrackingRepositoryImpl(),
  );
  sl.registerLazySingleton<LocationService>(
    () => GeolocatorLocationServiceImpl(),
  );
  sl.registerLazySingleton<PlaceRepository>(
    () => SupabasePlaceRepositoryImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<RecentSearchLocalDataSource>(
    () => RecentSearchLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<RecentSearchRepository>(
    () => RecentSearchRepositoryImpl(localDataSource: sl()),
  );
}

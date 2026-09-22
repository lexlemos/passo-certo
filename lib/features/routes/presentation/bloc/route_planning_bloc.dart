import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../domain/entities/navigation_route.dart';
import '../../domain/entities/navigation_preferences.dart';
import '../../domain/usecases/calculate_accessible_route.dart';
import '../../domain/usecases/get_current_location_place.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../../community/domain/usecases/get_obstacles.dart';
import '../../domain/usecases/get_recent_searches.dart';
import '../../domain/usecases/save_recent_search.dart';
import '../../domain/entities/place.dart';

// --- EVENTS ---
abstract class RoutePlanningEvent {}

class SwapLocationsEvent extends RoutePlanningEvent {
  final String originText;
  final String destinationText;
  SwapLocationsEvent({required this.originText, required this.destinationText});
}

class SelectFilterEvent extends RoutePlanningEvent {
  final String filter;
  SelectFilterEvent({required this.filter});
}

class SearchRoutesEvent extends RoutePlanningEvent {
  final String originText;
  final String destinationText;
  SearchRoutesEvent({required this.originText, required this.destinationText});
}

class SelectRouteEvent extends RoutePlanningEvent {
  final int routeIndex;
  SelectRouteEvent({required this.routeIndex});
}

class LoadRoutesEvent extends RoutePlanningEvent {}

class LoadRecentSearchesEvent extends RoutePlanningEvent {}

class UpdateOriginEvent extends RoutePlanningEvent {
  final String originText;
  final double originLat;
  final double originLng;
  UpdateOriginEvent({
    required this.originText,
    required this.originLat,
    required this.originLng,
  });
}

class UpdateDestinationEvent extends RoutePlanningEvent {
  final String destinationText;
  final double destLat;
  final double destLng;
  UpdateDestinationEvent({
    required this.destinationText,
    required this.destLat,
    required this.destLng,
  });
}

class CalculateRouteEvent extends RoutePlanningEvent {}

class FetchCurrentLocationForOriginEvent extends RoutePlanningEvent {}

class ClearOriginEvent extends RoutePlanningEvent {}

class ClearDestinationEvent extends RoutePlanningEvent {}

class ClearRouteSearchEvent extends RoutePlanningEvent {}

class ClearCalculatedRoutesEvent extends RoutePlanningEvent {}

// --- STATE ---
class RoutePlanningState extends Equatable {
  final String originText;
  final double? originLat;
  final double? originLng;
  final String destinationText;
  final double? destLat;
  final double? destLng;
  final String selectedFilter;
  final List<NavigationRoute> routes;
  final NavigationRoute? recommendedRoute;
  final int selectedRouteIndex;
  final bool isLoading;
  final String? errorMessage;
  final List<Place> recentSearches;

  const RoutePlanningState({
    required this.originText,
    this.originLat,
    this.originLng,
    required this.destinationText,
    this.destLat,
    this.destLng,
    required this.selectedFilter,
    required this.routes,
    this.recommendedRoute,
    required this.selectedRouteIndex,
    this.isLoading = false,
    this.errorMessage,
    this.recentSearches = const [],
  });

  const RoutePlanningState._empty()
    : originText = '',
      originLat = null,
      originLng = null,
      destinationText = '',
      destLat = null,
      destLng = null,
      selectedFilter = 'accessible',
      routes = const [],
      recommendedRoute = null,
      selectedRouteIndex = 0,
      isLoading = false,
      errorMessage = null,
      recentSearches = const [];

  static const _unset = Object();

  RoutePlanningState copyWith({
    String? originText,
    Object? originLat = _unset,
    Object? originLng = _unset,
    String? destinationText,
    Object? destLat = _unset,
    Object? destLng = _unset,
    String? selectedFilter,
    List<NavigationRoute>? routes,
    Object? recommendedRoute = _unset,
    int? selectedRouteIndex,
    bool? isLoading,
    Object? errorMessage = _unset,
    List<Place>? recentSearches,
  }) {
    return RoutePlanningState(
      originText: originText ?? this.originText,
      originLat: identical(originLat, _unset)
          ? this.originLat
          : originLat as double?,
      originLng: identical(originLng, _unset)
          ? this.originLng
          : originLng as double?,
      destinationText: destinationText ?? this.destinationText,
      destLat: identical(destLat, _unset) ? this.destLat : destLat as double?,
      destLng: identical(destLng, _unset) ? this.destLng : destLng as double?,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      routes: routes ?? this.routes,
      recommendedRoute: identical(recommendedRoute, _unset)
          ? this.recommendedRoute
          : recommendedRoute as NavigationRoute?,
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [
    originText,
    originLat,
    originLng,
    destinationText,
    destLat,
    destLng,
    selectedFilter,
    routes,
    recommendedRoute,
    selectedRouteIndex,
    isLoading,
    errorMessage,
    recentSearches,
  ];
}

// --- BLOC ---
class RoutePlanningBloc extends Bloc<RoutePlanningEvent, RoutePlanningState> {
  final CalculateAccessibleRouteUseCase _calculateAccessibleRouteUseCase;
  final NavigationPreferencesReader _preferencesReader;
  final GetCurrentLocationPlaceUseCase _getCurrentLocationPlaceUseCase;
  final GetObstaclesUseCase _getObstaclesUseCase;
  final SaveRecentSearchUseCase _saveRecentSearchUseCase;
  final GetRecentSearchesUseCase _getRecentSearchesUseCase;

  RoutePlanningBloc({
    required CalculateAccessibleRouteUseCase calculateAccessibleRouteUseCase,
    required NavigationPreferencesReader preferencesReader,
    required GetCurrentLocationPlaceUseCase getCurrentLocationPlaceUseCase,
    required GetObstaclesUseCase getObstaclesUseCase,
    required SaveRecentSearchUseCase saveRecentSearchUseCase,
    required GetRecentSearchesUseCase getRecentSearchesUseCase,
  }) : _calculateAccessibleRouteUseCase = calculateAccessibleRouteUseCase,
       _preferencesReader = preferencesReader,
       _getCurrentLocationPlaceUseCase = getCurrentLocationPlaceUseCase,
       _getObstaclesUseCase = getObstaclesUseCase,
       _saveRecentSearchUseCase = saveRecentSearchUseCase,
       _getRecentSearchesUseCase = getRecentSearchesUseCase,
       super(const RoutePlanningState._empty()) {
    on<LoadRoutesEvent>(_onLoadRoutes);
    on<LoadRecentSearchesEvent>(_onLoadRecentSearches);
    on<SwapLocationsEvent>(_onSwapLocations);
    on<SelectFilterEvent>(_onSelectFilter);
    on<SearchRoutesEvent>(_onSearchRoutes);
    on<SelectRouteEvent>(_onSelectRoute);
    on<UpdateOriginEvent>(_onUpdateOrigin);
    on<UpdateDestinationEvent>(_onUpdateDestination);
    on<CalculateRouteEvent>(_onCalculateRoute, transformer: restartable());
    on<FetchCurrentLocationForOriginEvent>(_onFetchCurrentLocationForOrigin);
    on<ClearOriginEvent>(_onClearOrigin);
    on<ClearDestinationEvent>(_onClearDestination);
    on<ClearRouteSearchEvent>(_onClearRouteSearch);
    on<ClearCalculatedRoutesEvent>(_onClearCalculatedRoutes);

    add(LoadRoutesEvent());
    add(LoadRecentSearchesEvent());
  }

  Future<void> _onLoadRecentSearches(
    LoadRecentSearchesEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    final recentSearches = await _getRecentSearchesUseCase();
    emit(state.copyWith(recentSearches: recentSearches));
  }

  Future<void> _onLoadRoutes(
    LoadRoutesEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    add(FetchCurrentLocationForOriginEvent());
  }

  void _onSwapLocations(
    SwapLocationsEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        originText: state.destinationText,
        originLat: state.destLat,
        originLng: state.destLng,
        destinationText: state.originText,
        destLat: state.originLat,
        destLng: state.originLng,
      ),
    );
    add(CalculateRouteEvent());
  }

  void _onSelectFilter(
    SelectFilterEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(state.copyWith(selectedFilter: event.filter));
  }

  Future<void> _onSearchRoutes(
    SearchRoutesEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    double originLat = -10.9472;
    double originLng = -37.0731;
    double destLat = -10.9350;
    double destLng = -37.0650;

    final originLower = event.originText.toLowerCase();
    final destLower = event.destinationText.toLowerCase();

    if (originLower.contains('dia') || originLower.contains('terminal')) {
      originLat = -10.9350;
      originLng = -37.0650;
    }
    if (destLower.contains('ufs') || destLower.contains('ccet')) {
      destLat = -10.9472;
      destLng = -37.0731;
    }

    emit(
      state.copyWith(
        originText: event.originText,
        originLat: originLat,
        originLng: originLng,
        destinationText: event.destinationText,
        destLat: destLat,
        destLng: destLng,
      ),
    );

    add(CalculateRouteEvent());
  }

  void _onSelectRoute(
    SelectRouteEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(state.copyWith(selectedRouteIndex: event.routeIndex));
  }

  void _onUpdateOrigin(
    UpdateOriginEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        originText: event.originText,
        originLat: event.originLat,
        originLng: event.originLng,
        routes: const [],
        recommendedRoute: null,
        selectedRouteIndex: 0,
      ),
    );
  }

  void _onUpdateDestination(
    UpdateDestinationEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        destinationText: event.destinationText,
        destLat: event.destLat,
        destLng: event.destLng,
        routes: const [],
        recommendedRoute: null,
        selectedRouteIndex: 0,
      ),
    );
  }

  Future<void> _onCalculateRoute(
    CalculateRouteEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    final originLat = state.originLat;
    final originLng = state.originLng;
    final destLat = state.destLat;
    final destLng = state.destLng;

    if (originLat == null ||
        originLng == null ||
        destLat == null ||
        destLng == null) {
      return;
    }

    emit(
      state.copyWith(
        routes: const [],
        recommendedRoute: null,
        selectedRouteIndex: 0,
        isLoading: true,
        errorMessage: null,
      ),
    );

    try {
      final preferences = _preferencesReader.current;
      final avoidStairs = preferences.avoidStairs;
      final requiresTactilePaving = preferences.requiresTactilePaving;

      // Injeção Reativa com bounding box cobrindo a rota
      final minLat = originLat < destLat ? originLat : destLat;
      final maxLat = originLat > destLat ? originLat : destLat;
      final minLng = originLng < destLng ? originLng : destLng;
      final maxLng = originLng > destLng ? originLng : destLng;

      // Expand bounding box slightly for safety
      final obstaclesResult = await _getObstaclesUseCase(
        minLat: minLat - 0.05,
        minLng: minLng - 0.05,
        maxLat: maxLat + 0.05,
        maxLng: maxLng + 0.05,
      );

      final activeObstacles = obstaclesResult.fold(
        (_) => <Obstacle>[],
        (obstacles) => obstacles,
      );

      final result = await _calculateAccessibleRouteUseCase(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        avoidStairs: avoidStairs,
        requiresTactilePaving: requiresTactilePaving,
        activeObstacles: activeObstacles,
      );

      if (emit.isDone) return;

      await result.fold(
        (failure) async {
          emit(
            state.copyWith(
              routes: const [],
              recommendedRoute: null,
              selectedRouteIndex: 0,
              isLoading: false,
              errorMessage: failure.message,
            ),
          );
        },
        (routes) async {
          final destinationPlace = Place(
            name: state.destinationText,
            latitude: state.destLat!,
            longitude: state.destLng!,
          );

          await _saveRecentSearchUseCase(destinationPlace);
          final recentSearches = await _getRecentSearchesUseCase();

          if (emit.isDone) return;

          emit(
            state.copyWith(
              routes: routes,
              recommendedRoute: routes.isNotEmpty ? routes.first : null,
              selectedRouteIndex: 0,
              isLoading: false,
              errorMessage: null,
              recentSearches: recentSearches,
            ),
          );
        },
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          routes: const [],
          recommendedRoute: null,
          selectedRouteIndex: 0,
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchCurrentLocationForOrigin(
    FetchCurrentLocationForOriginEvent event,
    Emitter<RoutePlanningState> emit,
  ) async {
    try {
      emit(state.copyWith(originText: 'Obtendo localização...'));

      final place = await _getCurrentLocationPlaceUseCase();

      emit(
        state.copyWith(
          originText: place.name,
          originLat: place.latitude,
          originLng: place.longitude,
        ),
      );

      if (state.destLat != null && state.destLng != null) {
        add(CalculateRouteEvent());
      }
    } catch (_) {
      emit(state.copyWith(originText: 'Falha ao obter localização'));
    }
  }

  void _onClearOrigin(
    ClearOriginEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        originText: '',
        originLat: null, // Because of _unset sentinel, this clears it
        originLng: null,
        routes: const [],
        recommendedRoute: null,
        selectedRouteIndex: 0,
      ),
    );
  }

  void _onClearDestination(
    ClearDestinationEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        destinationText: '',
        destLat: null,
        destLng: null,
        routes: const [],
        recommendedRoute: null,
        selectedRouteIndex: 0,
      ),
    );
  }

  void _onClearRouteSearch(
    ClearRouteSearchEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      RoutePlanningState(
        originText: state.originText,
        originLat: state.originLat,
        originLng: state.originLng,
        destinationText: '',
        selectedFilter: state.selectedFilter,
        routes: const [],
        selectedRouteIndex: 0,
        recentSearches: state.recentSearches,
      ),
    );
  }

  void _onClearCalculatedRoutes(
    ClearCalculatedRoutesEvent event,
    Emitter<RoutePlanningState> emit,
  ) {
    emit(
      state.copyWith(
        routes: const [],
        recommendedRoute: null,
        selectedRouteIndex: 0,
      ),
    );
  }
}

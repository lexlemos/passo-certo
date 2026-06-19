import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/navigation_route.dart';
import '../../domain/usecases/get_recommended_route.dart';

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

// --- STATE ---
class RoutePlanningState {
  final String originText;
  final String destinationText;
  final String selectedFilter;
  final List<NavigationRoute> routes;
  final NavigationRoute? recommendedRoute;
  final int selectedRouteIndex;

  RoutePlanningState({
    required this.originText,
    required this.destinationText,
    required this.selectedFilter,
    required this.routes,
    this.recommendedRoute,
    required this.selectedRouteIndex,
  });

  RoutePlanningState copyWith({
    String? originText,
    String? destinationText,
    String? selectedFilter,
    List<NavigationRoute>? routes,
    NavigationRoute? recommendedRoute,
    int? selectedRouteIndex,
  }) {
    return RoutePlanningState(
      originText: originText ?? this.originText,
      destinationText: destinationText ?? this.destinationText,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      routes: routes ?? this.routes,
      recommendedRoute: recommendedRoute ?? this.recommendedRoute,
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
    );
  }
}

// --- BLOC ---
class RoutePlanningBloc extends Bloc<RoutePlanningEvent, RoutePlanningState> {
  final GetRecommendedRouteUseCase _getRecommendedRouteUseCase;

  RoutePlanningBloc({
    GetRecommendedRouteUseCase? getRecommendedRouteUseCase,
  })  : _getRecommendedRouteUseCase = getRecommendedRouteUseCase ?? GetRecommendedRouteUseCase(),
        super(_createInitialState(getRecommendedRouteUseCase ?? GetRecommendedRouteUseCase())) {
    on<SwapLocationsEvent>(_onSwapLocations);
    on<SelectFilterEvent>(_onSelectFilter);
    on<SearchRoutesEvent>(_onSearchRoutes);
    on<SelectRouteEvent>(_onSelectRoute);
  }

  static RoutePlanningState _createInitialState(GetRecommendedRouteUseCase getRecommendedRouteUseCase) {
    const mockRoutes = [
      NavigationRoute(
        title: 'Via CCET Park',
        estimatedTime: '15 min',
        distance: '1.2 km',
        accessibilityScore: 0.95,
        characteristics: ['PLANO', 'CALÇADAS BOAS'],
        waypoints: [
          RouteCoordinate(-10.9472, -37.0731),
          RouteCoordinate(-10.9450, -37.0715),
          RouteCoordinate(-10.9350, -37.0650),
        ],
      ),
      NavigationRoute(
        title: 'Via Terminal UFS',
        estimatedTime: '12 min',
        distance: '0.9 km',
        accessibilityScore: 0.60,
        characteristics: ['ACLIVE', 'ATENÇÃO CRUZAMENTOS'],
        waypoints: [
          RouteCoordinate(-10.9472, -37.0731),
          RouteCoordinate(-10.9430, -37.0710),
          RouteCoordinate(-10.9350, -37.0650),
        ],
      ),
    ];

    final recommendation = getRecommendedRouteUseCase(mockRoutes);

    return RoutePlanningState(
      originText: 'CCET UFS',
      destinationText: 'Terminal D.I.A.',
      selectedFilter: 'accessible',
      routes: mockRoutes,
      recommendedRoute: recommendation,
      selectedRouteIndex: 0,
    );
  }

  void _onSwapLocations(SwapLocationsEvent event, Emitter<RoutePlanningState> emit) {
    emit(state.copyWith(
      originText: event.destinationText,
      destinationText: event.originText,
    ));
  }

  void _onSelectFilter(SelectFilterEvent event, Emitter<RoutePlanningState> emit) {
    emit(state.copyWith(selectedFilter: event.filter));
  }

  void _onSearchRoutes(SearchRoutesEvent event, Emitter<RoutePlanningState> emit) {
    final recommendation = _getRecommendedRouteUseCase(state.routes);
    emit(state.copyWith(
      originText: event.originText,
      destinationText: event.destinationText,
      recommendedRoute: recommendation,
    ));
  }

  void _onSelectRoute(SelectRouteEvent event, Emitter<RoutePlanningState> emit) {
    emit(state.copyWith(selectedRouteIndex: event.routeIndex));
  }
}

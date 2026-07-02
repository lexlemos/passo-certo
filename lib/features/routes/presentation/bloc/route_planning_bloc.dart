import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/navigation_route.dart';
import '../../domain/usecases/get_routes.dart';
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

/// Evento interno disparado pelo próprio BLoC no construtor
/// para carregar o estado inicial com os dados vindos do repositório.
class LoadRoutesEvent extends RoutePlanningEvent {}

// --- STATE ---
class RoutePlanningState extends Equatable {
  final String originText;
  final String destinationText;
  final String selectedFilter;
  final List<NavigationRoute> routes;
  final NavigationRoute? recommendedRoute;
  final int selectedRouteIndex;

  const RoutePlanningState({
    required this.originText,
    required this.destinationText,
    required this.selectedFilter,
    required this.routes,
    this.recommendedRoute,
    required this.selectedRouteIndex,
  });

  /// Estado vazio seguro para inicialização — sem dados mock.
  const RoutePlanningState._empty()
      : originText = '',
        destinationText = '',
        selectedFilter = 'accessible',
        routes = const [],
        recommendedRoute = null,
        selectedRouteIndex = 0;

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

  @override
  List<Object?> get props => [
        originText,
        destinationText,
        selectedFilter,
        routes,
        recommendedRoute,
        selectedRouteIndex,
      ];
}

// --- BLOC ---
class RoutePlanningBloc extends Bloc<RoutePlanningEvent, RoutePlanningState> {
  final GetRoutesUseCase _getRoutesUseCase;
  final GetRecommendedRouteUseCase _getRecommendedRouteUseCase;

  RoutePlanningBloc({
    required GetRoutesUseCase getRoutesUseCase,
    required GetRecommendedRouteUseCase getRecommendedRouteUseCase,
  })  : _getRoutesUseCase = getRoutesUseCase,
        _getRecommendedRouteUseCase = getRecommendedRouteUseCase,
        super(const RoutePlanningState._empty()) {
    on<LoadRoutesEvent>(_onLoadRoutes);
    on<SwapLocationsEvent>(_onSwapLocations);
    on<SelectFilterEvent>(_onSelectFilter);
    on<SearchRoutesEvent>(_onSearchRoutes);
    on<SelectRouteEvent>(_onSelectRoute);

    // Dispara o carregamento inicial buscando dados do repositório via UseCase
    add(LoadRoutesEvent());
  }

  /// Carrega as rotas e calcula a recomendada de forma assíncrona a partir da camada de dados.
  Future<void> _onLoadRoutes(LoadRoutesEvent event, Emitter<RoutePlanningState> emit) async {
    final routes = await _getRoutesUseCase();
    final recommendation = await _getRecommendedRouteUseCase();

    emit(state.copyWith(
      originText: 'CCET UFS',
      destinationText: 'Terminal D.I.A.',
      routes: routes,
      recommendedRoute: recommendation,
      selectedRouteIndex: 0,
    ));
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

  Future<void> _onSearchRoutes(SearchRoutesEvent event, Emitter<RoutePlanningState> emit) async {
    final recommendation = await _getRecommendedRouteUseCase();
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

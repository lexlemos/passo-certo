import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/navigation_route.dart';
import '../../domain/usecases/get_recommended_route.dart';

// --- EVENTS ---
abstract class RoutePlanningEvent {}

class SwapLocationsEvent extends RoutePlanningEvent {}

class SelectFilterEvent extends RoutePlanningEvent {
  final String filter;
  SelectFilterEvent({required this.filter});
}

class SearchRoutesEvent extends RoutePlanningEvent {}

class SelectRouteEvent extends RoutePlanningEvent {
  final int routeIndex;
  SelectRouteEvent({required this.routeIndex});
}

class MapCreatedEvent extends RoutePlanningEvent {
  final GoogleMapController controller;
  MapCreatedEvent({required this.controller});
}

// --- STATE ---
class RoutePlanningState {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final String selectedFilter;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final GoogleMapController? mapController;
  final List<NavigationRoute> routes;
  final NavigationRoute? recommendedRoute;

  RoutePlanningState({
    required this.originController,
    required this.destinationController,
    required this.selectedFilter,
    required this.markers,
    required this.polylines,
    this.mapController,
    required this.routes,
    this.recommendedRoute,
  });

  RoutePlanningState copyWith({
    TextEditingController? originController,
    TextEditingController? destinationController,
    String? selectedFilter,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    GoogleMapController? mapController,
    List<NavigationRoute>? routes,
    NavigationRoute? recommendedRoute,
  }) {
    return RoutePlanningState(
      originController: originController ?? this.originController,
      destinationController: destinationController ?? this.destinationController,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      mapController: mapController ?? this.mapController,
      routes: routes ?? this.routes,
      recommendedRoute: recommendedRoute ?? this.recommendedRoute,
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
    on<MapCreatedEvent>(_onMapCreated);
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
          LatLng(-10.9472, -37.0731),
          LatLng(-10.9450, -37.0715),
          LatLng(-10.9350, -37.0650),
        ],
      ),
      NavigationRoute(
        title: 'Via Terminal UFS',
        estimatedTime: '12 min',
        distance: '0.9 km',
        accessibilityScore: 0.60,
        characteristics: ['ACLIVE', 'ATENÇÃO CRUZAMENTOS'],
        waypoints: [
          LatLng(-10.9472, -37.0731),
          LatLng(-10.9430, -37.0710),
          LatLng(-10.9350, -37.0650),
        ],
      ),
    ];

    final recommendation = getRecommendedRouteUseCase(mockRoutes);

    final markers = {
      const Marker(
        markerId: MarkerId('origin'),
        position: LatLng(-10.9472, -37.0731),
        infoWindow: InfoWindow(title: 'Origem (CCET UFS)'),
      ),
      const Marker(
        markerId: MarkerId('destination'),
        position: LatLng(-10.9350, -37.0650),
        infoWindow: InfoWindow(title: 'Destino (Terminal D.I.A.)'),
      ),
    };

    final polylines = mockRoutes.map((route) {
      final isRec = route.accessibilityScore >= 0.8;
      return Polyline(
        polylineId: PolylineId(route.title),
        color: isRec ? const Color(0xFF48BB78) : Colors.orange,
        width: 5,
        points: route.waypoints,
      );
    }).toSet();

    return RoutePlanningState(
      originController: TextEditingController(text: 'CCET UFS'),
      destinationController: TextEditingController(text: 'Terminal D.I.A.'),
      selectedFilter: 'accessible',
      markers: markers,
      polylines: polylines,
      routes: mockRoutes,
      recommendedRoute: recommendation,
    );
  }

  void _onSwapLocations(SwapLocationsEvent event, Emitter<RoutePlanningState> emit) {
    final tempText = state.originController.text;
    state.originController.text = state.destinationController.text;
    state.destinationController.text = tempText;

    emit(state.copyWith(
      originController: state.originController,
      destinationController: state.destinationController,
    ));
  }

  void _onSelectFilter(SelectFilterEvent event, Emitter<RoutePlanningState> emit) {
    emit(state.copyWith(selectedFilter: event.filter));
  }

  void _onSearchRoutes(SearchRoutesEvent event, Emitter<RoutePlanningState> emit) {
    // Processamento de busca usando UseCase
    final recommendation = _getRecommendedRouteUseCase(state.routes);
    emit(state.copyWith(recommendedRoute: recommendation));
  }

  void _onSelectRoute(SelectRouteEvent event, Emitter<RoutePlanningState> emit) {
    // Seleção de rota altera marcadores/linhas
  }

  void _onMapCreated(MapCreatedEvent event, Emitter<RoutePlanningState> emit) {
    emit(state.copyWith(mapController: event.controller));
  }

  @override
  Future<void> close() {
    state.originController.dispose();
    state.destinationController.dispose();
    state.mapController?.dispose();
    return super.close();
  }
}

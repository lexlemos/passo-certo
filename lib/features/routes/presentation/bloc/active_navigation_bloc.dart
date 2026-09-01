import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../core/config/app_constants.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../../community/domain/usecases/get_obstacles.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/entities/navigation_preferences.dart';
import '../../domain/repositories/location_tracking_repository.dart';
import '../../domain/services/voice_navigation_service.dart';
import '../../domain/usecases/calculate_accessible_route.dart';

// --- EVENTS ---
abstract class ActiveNavigationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartNavigationEvent extends ActiveNavigationEvent {
  final NavigationRoute route;
  StartNavigationEvent(this.route);

  @override
  List<Object?> get props => [route];
}

class LocationUpdatedEvent extends ActiveNavigationEvent {
  final Position position;
  LocationUpdatedEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class StopNavigationEvent extends ActiveNavigationEvent {}

class RecalculateRouteTriggeredEvent extends ActiveNavigationEvent {}

class GpsServiceStatusChangedEvent extends ActiveNavigationEvent {
  final ServiceStatus serviceStatus;
  GpsServiceStatusChangedEvent(this.serviceStatus);

  @override
  List<Object?> get props => [serviceStatus];
}

// --- STATE ---
class ActiveNavigationState extends Equatable {
  final bool isActive;
  final NavigationRoute? currentRoute;
  final RouteStep? currentStep;
  final int currentStepIndex;
  final double distanceToNextStep;
  final bool isOffRoute;
  final bool isFinished;
  final Position? lastPosition;
  final Set<String> alertedObstacleIds;
  final List<Obstacle> activeObstacles;
  final Obstacle? proximityAlertObstacle;
  final bool isGpsDisabled;
  final double remainingDistanceMeters;
  final int remainingDurationMinutes;

  const ActiveNavigationState({
    required this.isActive,
    this.currentRoute,
    this.currentStep,
    this.currentStepIndex = 0,
    this.distanceToNextStep = 0.0,
    this.isOffRoute = false,
    this.isFinished = false,
    this.lastPosition,
    this.alertedObstacleIds = const {},
    this.activeObstacles = const [],
    this.proximityAlertObstacle,
    this.isGpsDisabled = false,
    this.remainingDistanceMeters = 0.0,
    this.remainingDurationMinutes = 0,
  });

  ActiveNavigationState copyWith({
    bool? isActive,
    NavigationRoute? currentRoute,
    RouteStep? currentStep,
    int? currentStepIndex,
    double? distanceToNextStep,
    bool? isOffRoute,
    bool? isFinished,
    Position? lastPosition,
    Set<String>? alertedObstacleIds,
    List<Obstacle>? activeObstacles,
    Obstacle? proximityAlertObstacle,
    bool clearProximityAlert = false,
    bool? isGpsDisabled,
    double? remainingDistanceMeters,
    int? remainingDurationMinutes,
  }) {
    return ActiveNavigationState(
      isActive: isActive ?? this.isActive,
      currentRoute: currentRoute ?? this.currentRoute,
      currentStep: currentStep ?? this.currentStep,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceToNextStep: distanceToNextStep ?? this.distanceToNextStep,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isFinished: isFinished ?? this.isFinished,
      lastPosition: lastPosition ?? this.lastPosition,
      alertedObstacleIds: alertedObstacleIds ?? this.alertedObstacleIds,
      activeObstacles: activeObstacles ?? this.activeObstacles,
      proximityAlertObstacle: clearProximityAlert
          ? null
          : (proximityAlertObstacle ?? this.proximityAlertObstacle),
      isGpsDisabled: isGpsDisabled ?? this.isGpsDisabled,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      remainingDurationMinutes:
          remainingDurationMinutes ?? this.remainingDurationMinutes,
    );
  }

  @override
  List<Object?> get props => [
    isActive,
    currentRoute,
    currentStep,
    currentStepIndex,
    distanceToNextStep,
    isOffRoute,
    isFinished,
    lastPosition,
    alertedObstacleIds,
    activeObstacles,
    proximityAlertObstacle,
    isGpsDisabled,
    remainingDistanceMeters,
    remainingDurationMinutes,
  ];
}

// --- BLOC ---
class ActiveNavigationBloc
    extends Bloc<ActiveNavigationEvent, ActiveNavigationState>
    with WidgetsBindingObserver {
  final VoiceNavigationService _voiceService;
  final LocationTrackingRepository _locationTrackingRepository;
  final CalculateAccessibleRouteUseCase _calculateAccessibleRouteUseCase;
  final GetObstaclesUseCase _getObstaclesUseCase;
  final NavigationPreferencesReader _preferencesReader;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Timer? _offRouteTimer;
  bool _isRecalculating = false;
  DateTime? _lastLocationTime;
  bool _isObservingLifecycle = false;

  ActiveNavigationBloc({
    required VoiceNavigationService voiceService,
    required LocationTrackingRepository locationTrackingRepository,
    required CalculateAccessibleRouteUseCase calculateAccessibleRouteUseCase,
    required GetObstaclesUseCase getObstaclesUseCase,
    required NavigationPreferencesReader preferencesReader,
  }) : _voiceService = voiceService,
       _locationTrackingRepository = locationTrackingRepository,
       _calculateAccessibleRouteUseCase = calculateAccessibleRouteUseCase,
       _getObstaclesUseCase = getObstaclesUseCase,
       _preferencesReader = preferencesReader,
       super(const ActiveNavigationState(isActive: false)) {
    try {
      WidgetsBinding.instance.addObserver(this);
      _isObservingLifecycle = true;
    } catch (_) {
      _isObservingLifecycle = false;
    }

    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    on<StartNavigationEvent>(_onStartNavigation);
    on<LocationUpdatedEvent>(_onLocationUpdated, transformer: droppable());
    on<StopNavigationEvent>(_onStopNavigation);
    on<RecalculateRouteTriggeredEvent>(
      _onRecalculateRouteTriggered,
      transformer: droppable(),
    );
    on<GpsServiceStatusChangedEvent>(_onGpsServiceStatusChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _voiceService.stop();
      _offRouteTimer?.cancel();
      _offRouteTimer = null;
      _locationTrackingRepository.disableWakelock();
      if (_positionSubscription != null && !_positionSubscription!.isPaused) {
        _positionSubscription!.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (this.state.isActive) {
        _locationTrackingRepository.enableWakelock();
        if (_positionSubscription != null && _positionSubscription!.isPaused) {
          _positionSubscription!.resume();
        }
      }
    }
  }

  Future<void> _onStartNavigation(
    StartNavigationEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _offRouteTimer?.cancel();
    _offRouteTimer = null;
    _lastLocationTime = null;

    await _voiceService.initService();
    await _locationTrackingRepository.enableWakelock();

    final initialStep = event.route.steps.isNotEmpty
        ? event.route.steps.first
        : null;

    double minLat = event.route.waypoints.first.latitude;
    double maxLat = minLat;
    double minLng = event.route.waypoints.first.longitude;
    double maxLng = minLng;
    for (var point in event.route.waypoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final obstaclesResult = await _getObstaclesUseCase(
      minLat: minLat - 0.05,
      maxLat: maxLat + 0.05,
      minLng: minLng - 0.05,
      maxLng: maxLng + 0.05,
    );

    final activeObstacles = obstaclesResult.fold(
      (_) => <Obstacle>[],
      (obstacles) => obstacles,
    );

    emit(
      ActiveNavigationState(
        isActive: true,
        currentRoute: event.route,
        currentStep: initialStep,
        currentStepIndex: 0,
        distanceToNextStep: 0.0,
        remainingDistanceMeters: 0.0,
        remainingDurationMinutes: 0,
        isOffRoute: false,
        isFinished: false,
        activeObstacles: activeObstacles,
        alertedObstacleIds: const {},
        isGpsDisabled: false,
        lastPosition: null,
      ),
    );

    if (initialStep != null) {
      await _voiceService.speak(
        "Iniciando navegação guiada. ${initialStep.instruction}",
      );
    } else {
      await _voiceService.speak("Iniciando navegação guiada.");
    }

    _serviceStatusSubscription = _locationTrackingRepository
        .getServiceStatusStream()
        .listen((status) {
          add(GpsServiceStatusChangedEvent(status));
        });

    _positionSubscription = _locationTrackingRepository
        .getNavigationPositionStream()
        .listen(
          (Position position) {
            final now = DateTime.now();
            if (_lastLocationTime != null &&
                now.difference(_lastLocationTime!).inSeconds <
                    AppConstants.gpsThrottleSeconds) {
              return;
            }
            _lastLocationTime = now;
            add(LocationUpdatedEvent(position));
          },
          onError: (error) {
            add(StopNavigationEvent());
          },
        );
  }

  Future<void> _onGpsServiceStatusChanged(
    GpsServiceStatusChangedEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    final isDisabled = event.serviceStatus == ServiceStatus.disabled;
    if (isDisabled != state.isGpsDisabled) {
      emit(state.copyWith(isGpsDisabled: isDisabled));
      if (isDisabled) {
        await _voiceService.speak(
          "Sinal de GPS perdido. Por favor, reative a localização do dispositivo.",
        );
      } else {
        await _voiceService.speak("Sinal de GPS restabelecido.");
      }
    }
  }

  Future<void> _onLocationUpdated(
    LocationUpdatedEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    final route = state.currentRoute;
    if (route == null || !state.isActive || state.isFinished) return;

    final userPos = LatLng(event.position.latitude, event.position.longitude);
    final distanceCalc = const Distance();

    // 0. Progresso
    final (remainingMeters, remainingMinutes) = _calculateProgress(
      route,
      userPos,
      distanceCalc,
    );

    // Chegada
    if (route.waypoints.isNotEmpty && remainingMeters < 15.0) {
      await _handleArrival(event, emit);
      return;
    }

    // 1. Off-Route
    final isOffRoute = await _checkOffRoute(userPos, route);
    if (isOffRoute) {
      _handleOffRoute(event, remainingMeters, remainingMinutes, emit);
      return;
    } else {
      _handleOnRoute(event, remainingMeters, remainingMinutes, emit);
    }

    // 2. Obstacles
    final proximityAlertTriggered = await _checkProximityAlerts(
      userPos,
      distanceCalc,
      event,
      remainingMeters,
      remainingMinutes,
      emit,
    );

    // 3. Steps
    await _handleSteps(
      userPos,
      distanceCalc,
      event,
      route,
      remainingMeters,
      remainingMinutes,
      proximityAlertTriggered,
      emit,
    );
  }

  (double, int) _calculateProgress(
    NavigationRoute route,
    LatLng userPos,
    Distance distanceCalc,
  ) {
    if (route.waypoints.isEmpty) return (0.0, 0);
    final destCoord = route.waypoints.last;
    final destLatLng = LatLng(destCoord.latitude, destCoord.longitude);
    final remainingMeters = distanceCalc
        .as(LengthUnit.Meter, userPos, destLatLng)
        .toDouble();
    final remainingMinutes = (remainingMeters / 66.0).ceil();
    return (remainingMeters, remainingMinutes);
  }

  Future<void> _handleArrival(
    LocationUpdatedEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    unawaited(HapticFeedback.mediumImpact());
    await _voiceService.speak(
      "Você chegou ao seu destino! Navegação concluída.",
    );
    emit(
      state.copyWith(
        lastPosition: event.position,
        remainingDistanceMeters: 0.0,
        remainingDurationMinutes: 0,
        isFinished: true,
        isActive: false,
        clearProximityAlert: true,
      ),
    );
    add(StopNavigationEvent());
  }

  Future<bool> _checkOffRoute(LatLng userPos, NavigationRoute route) async {
    double distanceToPoly;
    if (route.waypoints.length > 50) {
      final List<double> waypointsFlat = [];
      for (final wp in route.waypoints) {
        waypointsFlat.add(wp.latitude);
        waypointsFlat.add(wp.longitude);
      }
      distanceToPoly = await Isolate.run(
        () => _calculateDistanceToPolylineInIsolate(
          userPos.latitude,
          userPos.longitude,
          waypointsFlat,
        ),
      );
    } else {
      distanceToPoly = _distanceToPolyline(userPos, route.waypoints);
    }
    return distanceToPoly > AppConstants.routeRecalculationThresholdMeters;
  }

  void _handleOffRoute(
    LocationUpdatedEvent event,
    double remainingMeters,
    int remainingMinutes,
    Emitter<ActiveNavigationState> emit,
  ) {
    if (!state.isOffRoute) {
      unawaited(HapticFeedback.heavyImpact());
      unawaited(
        Future.delayed(const Duration(milliseconds: 250), () {
          HapticFeedback.heavyImpact();
        }),
      );
    }

    emit(
      state.copyWith(
        isOffRoute: true,
        lastPosition: event.position,
        remainingDistanceMeters: remainingMeters,
        remainingDurationMinutes: remainingMinutes,
        clearProximityAlert: true,
      ),
    );

    if (_offRouteTimer == null || !_offRouteTimer!.isActive) {
      _offRouteTimer = Timer(const Duration(seconds: 5), () {
        add(RecalculateRouteTriggeredEvent());
      });
    }
  }

  void _handleOnRoute(
    LocationUpdatedEvent event,
    double remainingMeters,
    int remainingMinutes,
    Emitter<ActiveNavigationState> emit,
  ) {
    if (_offRouteTimer != null && _offRouteTimer!.isActive) {
      _offRouteTimer!.cancel();
      _offRouteTimer = null;
    }
    if (state.isOffRoute) {
      emit(
        state.copyWith(
          isOffRoute: false,
          lastPosition: event.position,
          remainingDistanceMeters: remainingMeters,
          remainingDurationMinutes: remainingMinutes,
          clearProximityAlert: true,
        ),
      );
    }
  }

  Future<bool> _checkProximityAlerts(
    LatLng userPos,
    Distance distanceCalc,
    LocationUpdatedEvent event,
    double remainingMeters,
    int remainingMinutes,
    Emitter<ActiveNavigationState> emit,
  ) async {
    for (final obstacle in state.activeObstacles) {
      if (state.alertedObstacleIds.contains(obstacle.id)) continue;

      final dist = distanceCalc.as(
        LengthUnit.Meter,
        userPos,
        LatLng(obstacle.latitude, obstacle.longitude),
      );

      if (dist < 20.0) {
        final newAlerted = Set<String>.from(state.alertedObstacleIds)
          ..add(obstacle.id);
        unawaited(HapticFeedback.heavyImpact());
        await _voiceService.speak(
          "Atenção, obstáculo reportado à frente: ${obstacle.description}",
        );
        emit(
          state.copyWith(
            alertedObstacleIds: newAlerted,
            proximityAlertObstacle: obstacle,
            remainingDistanceMeters: remainingMeters,
            remainingDurationMinutes: remainingMinutes,
          ),
        );
        return true;
      }
    }
    return false;
  }

  Future<void> _handleSteps(
    LatLng userPos,
    Distance distanceCalc,
    LocationUpdatedEvent event,
    NavigationRoute route,
    double remainingMeters,
    int remainingMinutes,
    bool proximityAlertTriggered,
    Emitter<ActiveNavigationState> emit,
  ) async {
    int stepIndex = state.currentStepIndex;
    final steps = route.steps;

    if (stepIndex < steps.length) {
      final nextStep = steps[stepIndex];
      final double distanceToStep = distanceCalc
          .as(LengthUnit.Meter, userPos, nextStep.coordinate)
          .toDouble();

      if (distanceToStep < AppConstants.obstacleProximityRadiusMeters) {
        if (!proximityAlertTriggered) {
          await _voiceService.speak(nextStep.instruction);
        }

        stepIndex++;
        final isFinished = stepIndex >= steps.length;

        if (isFinished) {
          if (!proximityAlertTriggered) {
            await _voiceService.speak("Você chegou ao seu destino.");
          }
          emit(
            state.copyWith(
              lastPosition: event.position,
              currentStepIndex: stepIndex,
              distanceToNextStep: 0.0,
              remainingDistanceMeters: 0.0,
              remainingDurationMinutes: 0,
              isOffRoute: false,
              isFinished: true,
              clearProximityAlert: !proximityAlertTriggered,
            ),
          );
          add(StopNavigationEvent());
        } else {
          final updatedStep = steps[stepIndex];
          emit(
            state.copyWith(
              lastPosition: event.position,
              currentStepIndex: stepIndex,
              currentStep: updatedStep,
              distanceToNextStep: 0.0,
              remainingDistanceMeters: remainingMeters,
              remainingDurationMinutes: remainingMinutes,
              isOffRoute: false,
              isFinished: false,
              clearProximityAlert: !proximityAlertTriggered,
            ),
          );
        }
      } else {
        if (!proximityAlertTriggered) {
          emit(
            state.copyWith(
              lastPosition: event.position,
              distanceToNextStep: distanceToStep,
              remainingDistanceMeters: remainingMeters,
              remainingDurationMinutes: remainingMinutes,
              isOffRoute: false,
              isFinished: false,
              clearProximityAlert: true,
            ),
          );
        }
      }
    } else {
      if (!proximityAlertTriggered) {
        emit(
          state.copyWith(
            lastPosition: event.position,
            remainingDistanceMeters: remainingMeters,
            remainingDurationMinutes: remainingMinutes,
            isOffRoute: false,
            isFinished: true,
            clearProximityAlert: true,
          ),
        );
      }
      add(StopNavigationEvent());
    }
  }

  Future<void> _onRecalculateRouteTriggered(
    RecalculateRouteTriggeredEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    if (_isRecalculating ||
        state.currentRoute == null ||
        state.lastPosition == null)
      return;
    _isRecalculating = true;

    await _voiceService.speak(
      "Você saiu da rota. Recalculando novo trajeto acessível.",
    );
    if (!state.isActive) {
      _isRecalculating = false;
      return;
    }

    try {
      final destCoord = state.currentRoute!.waypoints.last;
      final preferences = _preferencesReader.current;

      final result = await _calculateAccessibleRouteUseCase(
        originLat: state.lastPosition!.latitude,
        originLng: state.lastPosition!.longitude,
        destLat: destCoord.latitude,
        destLng: destCoord.longitude,
        avoidStairs: preferences.avoidStairs,
        requiresTactilePaving: preferences.requiresTactilePaving,
        activeObstacles: state.activeObstacles,
      );

      if (!state.isActive) {
        _isRecalculating = false;
        return;
      }

      await result.fold(
        (failure) async {
          _offRouteTimer = null;
        },
        (routes) async {
          if (routes.isNotEmpty) {
            final newRoute = routes.first;
            final initialStep = newRoute.steps.isNotEmpty
                ? newRoute.steps.first
                : null;

            emit(
              state.copyWith(
                currentRoute: newRoute,
                currentStep: initialStep,
                currentStepIndex: 0,
                distanceToNextStep: 0.0,
                isOffRoute: false,
                isFinished: false,
              ),
            );

            await _voiceService.speak(
              "Nova rota calculada. Siga as instruções.",
            );
          }
          _offRouteTimer = null;
        },
      );
    } catch (_) {
      _offRouteTimer = null;
    } finally {
      _isRecalculating = false;
    }
  }

  static double _calculateDistanceToPolylineInIsolate(
    double userLat,
    double userLng,
    List<double> waypointsFlat,
  ) {
    if (waypointsFlat.length < 4) return 0.0;

    double minDistance = double.infinity;
    final distanceCalc = const Distance();
    final userPos = LatLng(userLat, userLng);

    for (int i = 0; i < waypointsFlat.length - 3; i += 2) {
      final p1 = LatLng(waypointsFlat[i], waypointsFlat[i + 1]);
      final p2 = LatLng(waypointsFlat[i + 2], waypointsFlat[i + 3]);

      final dist = _distanceToSegmentStatic(userPos, p1, p2, distanceCalc);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  static double _distanceToSegmentStatic(
    LatLng p,
    LatLng a,
    LatLng b,
    Distance calc,
  ) {
    final double l2 = calc.as(LengthUnit.Meter, a, b);
    if (l2 == 0) return calc.as(LengthUnit.Meter, p, a);

    final double dx = b.longitude - a.longitude;
    final double dy = b.latitude - a.latitude;

    final double denominator = dx * dx + dy * dy;
    if (denominator == 0) return calc.as(LengthUnit.Meter, p, a);

    final double t =
        ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        denominator;

    if (t <= 0) return calc.as(LengthUnit.Meter, p, a);
    if (t >= 1) return calc.as(LengthUnit.Meter, p, b);

    final LatLng projection = LatLng(a.latitude + t * dy, a.longitude + t * dx);
    return calc.as(LengthUnit.Meter, p, projection);
  }

  double _distanceToPolyline(LatLng point, List<RouteCoordinate> waypoints) {
    if (waypoints.isEmpty) return 0.0;

    double minDistance = double.infinity;
    final distanceCalculator = const Distance();

    for (int i = 0; i < waypoints.length - 1; i++) {
      final p1 = LatLng(waypoints[i].latitude, waypoints[i].longitude);
      final p2 = LatLng(waypoints[i + 1].latitude, waypoints[i + 1].longitude);

      final dist = _distanceToSegment(point, p1, p2, distanceCalculator);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  double _distanceToSegment(LatLng p, LatLng a, LatLng b, Distance calc) {
    return _distanceToSegmentStatic(p, a, b, calc);
  }

  Future<void> _onStopNavigation(
    StopNavigationEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    try {
      await _positionSubscription?.cancel();
    } catch (_) {}
    _positionSubscription = null;

    try {
      await _serviceStatusSubscription?.cancel();
    } catch (_) {}
    _serviceStatusSubscription = null;

    try {
      _offRouteTimer?.cancel();
    } catch (_) {}
    _offRouteTimer = null;

    try {
      await _voiceService.stop();
    } catch (_) {}

    try {
      await _locationTrackingRepository.disableWakelock();
    } catch (_) {}

    emit(const ActiveNavigationState(isActive: false));
  }

  @override
  Future<void> close() async {
    if (_isObservingLifecycle) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
      _isObservingLifecycle = false;
    }
    try {
      await _positionSubscription?.cancel();
    } catch (_) {}
    _positionSubscription = null;

    try {
      await _serviceStatusSubscription?.cancel();
    } catch (_) {}
    _serviceStatusSubscription = null;

    try {
      _offRouteTimer?.cancel();
    } catch (_) {}
    _offRouteTimer = null;

    try {
      await _voiceService.stop();
    } catch (_) {}

    try {
      await _locationTrackingRepository.disableWakelock();
    } catch (_) {}

    return super.close();
  }
}

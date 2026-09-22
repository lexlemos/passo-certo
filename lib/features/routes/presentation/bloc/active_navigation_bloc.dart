import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_constants.dart';
import '../../../community/domain/entities/obstacle.dart';
import '../../../community/domain/usecases/get_obstacles.dart';
import '../../domain/entities/navigation_route.dart';
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

  StreamSubscription<Position>? _positionSubscription;
  Timer? _offRouteTimer;
  bool _isRecalculating = false;
  DateTime? _lastLocationTime;

  ActiveNavigationBloc({
    required VoiceNavigationService voiceService,
    required LocationTrackingRepository locationTrackingRepository,
    required CalculateAccessibleRouteUseCase calculateAccessibleRouteUseCase,
    required GetObstaclesUseCase getObstaclesUseCase,
  }) : _voiceService = voiceService,
       _locationTrackingRepository = locationTrackingRepository,
       _calculateAccessibleRouteUseCase = calculateAccessibleRouteUseCase,
       _getObstaclesUseCase = getObstaclesUseCase,
       super(const ActiveNavigationState(isActive: false)) {
    WidgetsBinding.instance.addObserver(this);

    on<StartNavigationEvent>(_onStartNavigation);
    on<LocationUpdatedEvent>(_onLocationUpdated);
    on<StopNavigationEvent>(_onStopNavigation);
    on<RecalculateRouteTriggeredEvent>(_onRecalculateRouteTriggered);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Para a sintetização de voz quando o aplicativo entra em background (minimizado)
    if (state == AppLifecycleState.paused) {
      _voiceService.stop();
    }
  }

  Future<void> _onStartNavigation(
    StartNavigationEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    if (state.isActive) return;

    await _positionSubscription?.cancel();
    await _voiceService.initService();
    await _locationTrackingRepository.enableWakelock();

    final initialStep = event.route.steps.isNotEmpty
        ? event.route.steps.first
        : null;

    // Busca os obstáculos mais recentes no momento que a rota inicia
    final obstaclesResult = await _getObstaclesUseCase();
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
        isOffRoute: false,
        isFinished: false,
        activeObstacles: activeObstacles,
        alertedObstacleIds: const {},
      ),
    );

    if (initialStep != null) {
      await _voiceService.speak(
        "Iniciando navegação guiada. ${initialStep.instruction}",
      );
    } else {
      await _voiceService.speak("Iniciando navegação guiada.");
    }

    _lastLocationTime = null;
    _positionSubscription = _locationTrackingRepository
        .getNavigationPositionStream()
        .listen(
          (Position position) {
            final now = DateTime.now();
            // Otimização de GPS: Processa posição apenas a cada 3 segundos
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

  Future<void> _onLocationUpdated(
    LocationUpdatedEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    final route = state.currentRoute;
    if (route == null || !state.isActive || state.isFinished) return;

    final userPos = LatLng(event.position.latitude, event.position.longitude);
    final distanceCalc = const Distance();

    // 1. Detecção de Saída de Rota (Desvio > 40 metros da polyline)
    final distanceToPoly = _distanceToPolyline(userPos, route.waypoints);
    if (distanceToPoly > AppConstants.routeRecalculationThresholdMeters) {
      emit(
        state.copyWith(
          isOffRoute: true,
          lastPosition: event.position,
          clearProximityAlert: true,
        ),
      );

      // Inicia timer de 5 segundos se ele já não estiver ativo
      if (_offRouteTimer == null || !_offRouteTimer!.isActive) {
        _offRouteTimer = Timer(const Duration(seconds: 5), () {
          add(RecalculateRouteTriggeredEvent());
        });
      }
      return;
    } else {
      // Se voltou ao trajeto antes dos 5 segundos, cancela o timer e limpa o flag
      if (_offRouteTimer != null && _offRouteTimer!.isActive) {
        _offRouteTimer!.cancel();
        _offRouteTimer = null;
      }
      if (state.isOffRoute) {
        emit(
          state.copyWith(
            isOffRoute: false,
            lastPosition: event.position,
            clearProximityAlert: true,
          ),
        );
      }
    }

    // 2. Consciência Espacial: Verificação de proximidade de obstáculos
    bool proximityAlertTriggered = false;
    for (final obstacle in state.activeObstacles) {
      if (state.alertedObstacleIds.contains(obstacle.id)) continue;

      final dist = distanceCalc.as(
        LengthUnit.Meter,
        userPos,
        LatLng(obstacle.latitude, obstacle.longitude),
      );

      // Alerta disparado se estiver a menos de 15 metros do obstáculo
      if (dist < AppConstants.obstacleProximityRadiusMeters) {
        final newAlerted = Set<String>.from(state.alertedObstacleIds)
          ..add(obstacle.id);

        await _voiceService.speak(
          "Atenção, obstáculo reportado à frente: ${obstacle.description}",
        );

        emit(
          state.copyWith(
            alertedObstacleIds: newAlerted,
            proximityAlertObstacle: obstacle,
          ),
        );

        proximityAlertTriggered = true;
        // Interrompe loop para não acumular alertas (TTS) em obstáculos aglomerados
        break;
      }
    }

    // 3. Acompanhamento dos Passos da Rota
    int stepIndex = state.currentStepIndex;
    final steps = route.steps;

    if (stepIndex < steps.length) {
      final nextStep = steps[stepIndex];
      final double distanceToStep = distanceCalc
          .as(LengthUnit.Meter, userPos, nextStep.coordinate)
          .toDouble();

      // Caso chegue a menos de 15 metros da conversão
      if (distanceToStep < AppConstants.obstacleProximityRadiusMeters) {
        // Enuncia a instrução apenas se não houve alerta de obstáculo agora
        if (!proximityAlertTriggered) {
          await _voiceService.speak(nextStep.instruction);
        }

        // Avança para o próximo passo se disponível
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
        state.lastPosition == null) {
      return;
    }
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

      final result = await _calculateAccessibleRouteUseCase(
        originLat: state.lastPosition!.latitude,
        originLng: state.lastPosition!.longitude,
        destLat: destCoord.latitude,
        destLng: destCoord.longitude,
        avoidStairs: false,
        requiresTactilePaving: false,
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

  /// Calcula a menor distância aproximada do usuário até a linha da rota
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

  Future<void> _onStopNavigation(
    StopNavigationEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _offRouteTimer?.cancel();
    _offRouteTimer = null;
    await _voiceService.stop();
    await _locationTrackingRepository.disableWakelock();

    emit(const ActiveNavigationState(isActive: false));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _offRouteTimer?.cancel();
    _voiceService.stop();
    _locationTrackingRepository.disableWakelock();
    return super.close();
  }
}

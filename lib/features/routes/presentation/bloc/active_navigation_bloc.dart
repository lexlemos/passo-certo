import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  const ActiveNavigationState({
    required this.isActive,
    this.currentRoute,
    this.currentStep,
    this.currentStepIndex = 0,
    this.distanceToNextStep = 0.0,
    this.isOffRoute = false,
    this.isFinished = false,
    this.lastPosition,
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
      ];
}

// --- BLOC ---
class ActiveNavigationBloc extends Bloc<ActiveNavigationEvent, ActiveNavigationState> with WidgetsBindingObserver {
  final VoiceNavigationService _voiceService;
  final LocationTrackingRepository _locationTrackingRepository;
  final CalculateAccessibleRouteUseCase _calculateAccessibleRouteUseCase;
  
  StreamSubscription<Position>? _positionSubscription;
  Timer? _offRouteTimer;
  bool _isRecalculating = false;

  ActiveNavigationBloc({
    required VoiceNavigationService voiceService,
    required LocationTrackingRepository locationTrackingRepository,
    required CalculateAccessibleRouteUseCase calculateAccessibleRouteUseCase,
  })  : _voiceService = voiceService,
        _locationTrackingRepository = locationTrackingRepository,
        _calculateAccessibleRouteUseCase = calculateAccessibleRouteUseCase,
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

    final initialStep = event.route.steps.isNotEmpty ? event.route.steps.first : null;

    emit(ActiveNavigationState(
      isActive: true,
      currentRoute: event.route,
      currentStep: initialStep,
      currentStepIndex: 0,
      distanceToNextStep: 0.0,
      isOffRoute: false,
      isFinished: false,
    ));

    if (initialStep != null) {
      await _voiceService.speak("Iniciando navegação guiada. ${initialStep.instruction}");
    } else {
      await _voiceService.speak("Iniciando navegação guiada.");
    }

    _positionSubscription = _locationTrackingRepository
        .getNavigationPositionStream()
        .listen(
      (Position position) {
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
    if (distanceToPoly > 40.0) {
      emit(state.copyWith(isOffRoute: true, lastPosition: event.position));
      
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
        emit(state.copyWith(isOffRoute: false, lastPosition: event.position));
      }
    }

    // 2. Acompanhamento dos Passos da Rota
    int stepIndex = state.currentStepIndex;
    final steps = route.steps;

    if (stepIndex < steps.length) {
      final nextStep = steps[stepIndex];
      final double distanceToStep = distanceCalc.as(
        LengthUnit.Meter,
        userPos,
        nextStep.coordinate,
      ).toDouble();

      // Caso chegue a menos de 15 metros da conversão
      if (distanceToStep < 15.0) {
        // Enuncia a instrução
        await _voiceService.speak(nextStep.instruction);

        // Avança para o próximo passo se disponível
        stepIndex++;
        
        final isFinished = stepIndex >= steps.length;
        
        if (isFinished) {
          await _voiceService.speak("Você chegou ao seu destino.");
          emit(state.copyWith(
            lastPosition: event.position,
            currentStepIndex: stepIndex,
            distanceToNextStep: 0.0,
            isOffRoute: false,
            isFinished: true,
          ));
          add(StopNavigationEvent());
        } else {
          final updatedStep = steps[stepIndex];
          emit(state.copyWith(
            lastPosition: event.position,
            currentStepIndex: stepIndex,
            currentStep: updatedStep,
            distanceToNextStep: 0.0,
            isOffRoute: false,
            isFinished: false,
          ));
        }
      } else {
        emit(state.copyWith(
          lastPosition: event.position,
          distanceToNextStep: distanceToStep,
          isOffRoute: false,
          isFinished: false,
        ));
      }
    } else {
      emit(state.copyWith(
        lastPosition: event.position,
        isOffRoute: false,
        isFinished: true,
      ));
      add(StopNavigationEvent());
    }
  }

  Future<void> _onRecalculateRouteTriggered(
    RecalculateRouteTriggeredEvent event,
    Emitter<ActiveNavigationState> emit,
  ) async {
    if (_isRecalculating || state.currentRoute == null || state.lastPosition == null) return;
    _isRecalculating = true;

    await _voiceService.speak("Você saiu da rota. Recalculando novo trajeto acessível.");

    try {
      final destCoord = state.currentRoute!.waypoints.last;
      
      final result = await _calculateAccessibleRouteUseCase(
        originLat: state.lastPosition!.latitude,
        originLng: state.lastPosition!.longitude,
        destLat: destCoord.latitude,
        destLng: destCoord.longitude,
        avoidStairs: false,
        requiresTactilePaving: false,
      );

      await result.fold(
        (failure) async {
          // Mantém isOffRoute e reseta timer para nova verificação posterior
          _offRouteTimer = null;
        },
        (routes) async {
          if (routes.isNotEmpty) {
            final newRoute = routes.first;
            final initialStep = newRoute.steps.isNotEmpty ? newRoute.steps.first : null;

            emit(state.copyWith(
              currentRoute: newRoute,
              currentStep: initialStep,
              currentStepIndex: 0,
              distanceToNextStep: 0.0,
              isOffRoute: false,
              isFinished: false,
            ));

            await _voiceService.speak("Nova rota calculada. Siga as instruções.");
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
      final p2 = LatLng(waypoints[i+1].latitude, waypoints[i+1].longitude);

      final dist = _distanceToSegment(point, p1, p2, distanceCalculator);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  double _distanceToSegment(LatLng p, LatLng a, LatLng b, Distance calc) {
    final dAP = calc.as(LengthUnit.Meter, p, a);
    final dBP = calc.as(LengthUnit.Meter, p, b);
    
    final mid = LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);
    final dMP = calc.as(LengthUnit.Meter, p, mid);

    return [dAP, dBP, dMP].reduce((curr, next) => curr < next ? curr : next).toDouble();
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

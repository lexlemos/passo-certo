import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'dart:developer' as developer;

import '../../domain/entities/obstacle.dart';
import '../../domain/usecases/get_obstacles.dart';
import '../../domain/usecases/report_obstacle.dart';

// --- EVENTS ---
abstract class ObstacleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadObstaclesEvent extends ObstacleEvent {}

class ReportNewObstacleEvent extends ObstacleEvent {
  final ObstacleType type;
  final LatLng location;
  final String description;
  final ObstacleSeverity severity;

  ReportNewObstacleEvent({
    required this.type,
    required this.location,
    required this.description,
    required this.severity,
  });

  @override
  List<Object?> get props => [type, location, description, severity];
}

// --- STATE ---
class ObstacleState extends Equatable {
  final List<Obstacle> obstacles;
  final bool isLoading;
  final String? errorMessage;
  final bool isReportedSuccess;

  const ObstacleState({
    required this.obstacles,
    this.isLoading = false,
    this.errorMessage,
    this.isReportedSuccess = false,
  });

  ObstacleState copyWith({
    List<Obstacle>? obstacles,
    bool? isLoading,
    String? errorMessage,
    bool? isReportedSuccess,
  }) {
    return ObstacleState(
      obstacles: obstacles ?? this.obstacles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isReportedSuccess: isReportedSuccess ?? this.isReportedSuccess,
    );
  }

  @override
  List<Object?> get props => [
    obstacles,
    isLoading,
    errorMessage,
    isReportedSuccess,
  ];
}

// --- BLOC ---
class ObstacleBloc extends Bloc<ObstacleEvent, ObstacleState> {
  final GetObstaclesUseCase _getObstaclesUseCase;
  final ReportObstacleUseCase _reportObstacleUseCase;

  ObstacleBloc({
    required GetObstaclesUseCase getObstaclesUseCase,
    required ReportObstacleUseCase reportObstacleUseCase,
  }) : _getObstaclesUseCase = getObstaclesUseCase,
       _reportObstacleUseCase = reportObstacleUseCase,
       super(const ObstacleState(obstacles: [])) {
    on<LoadObstaclesEvent>(_onLoadObstacles);
    on<ReportNewObstacleEvent>(_onReportNewObstacle);

    // Carrega a lista inicial de obstáculos
    add(LoadObstaclesEvent());
  }

  Future<void> _onLoadObstacles(
    LoadObstaclesEvent event,
    Emitter<ObstacleState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        isReportedSuccess: false,
        errorMessage: null,
      ),
    );

    final result = await _getObstaclesUseCase();

    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (obstacles) =>
          emit(state.copyWith(isLoading: false, obstacles: obstacles)),
    );
  }

  Future<void> _onReportNewObstacle(
    ReportNewObstacleEvent event,
    Emitter<ObstacleState> emit,
  ) async {
    developer.log(
      'Tentando adicionar Obstáculo: ${event.type.name}',
      name: 'DebugInsercao',
    );
    emit(
      state.copyWith(
        isLoading: true,
        isReportedSuccess: false,
        errorMessage: null,
      ),
    );

    final newObstacle = Obstacle(
      id: const Uuid().v4(),
      latitude: event.location.latitude,
      longitude: event.location.longitude,
      type: event.type,
      description: event.description,
      reportedAt: DateTime.now().toUtc(),
      upvotes: 0,
      reporterId: 'anonymous',
      severity: event.severity,
      status: ObstacleStatus.active,
    );

    // Otimista: Injeta na lista imediatamente
    final optimisticList = List<Obstacle>.from(state.obstacles)
      ..insert(0, newObstacle);
    emit(state.copyWith(obstacles: optimisticList));

    final result = await _reportObstacleUseCase(newObstacle);

    await result.fold(
      (failure) async {
        print('[DEBUG_INSERCAO] Falha capturada no BLoC: ${failure.message}');
        // Reverte se falhou
        final revertedList = state.obstacles
            .where((o) => o.id != newObstacle.id)
            .toList();
        print('[DEBUG_INSERCAO] Revertendo lista (Removendo ID ${newObstacle.id})');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            obstacles: revertedList,
          ),
        );
      },
      (_) async {
        print('[DEBUG_INSERCAO] Sucesso retornado pelo UseCase!');
        emit(state.copyWith(isLoading: false, isReportedSuccess: true));
        // Refetch silencioso
        final reloadResult = await _getObstaclesUseCase();
        reloadResult.fold(
          (failure) {
             print('[DEBUG_INSERCAO] Refetch falhou silenciosamente: ${failure.message}');
          },
          (obstacles) {
             print('[DEBUG_INSERCAO] Refetch com sucesso. ${obstacles.length} obstáculos encontrados.');
             emit(state.copyWith(obstacles: obstacles));
          },
        );
      },
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'dart:developer' as developer;

import '../../domain/entities/obstacle.dart';
import '../../domain/usecases/delete_obstacle.dart';
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

class DeleteObstacleEvent extends ObstacleEvent {
  final String obstacleId;

  DeleteObstacleEvent({required this.obstacleId});

  @override
  List<Object?> get props => [obstacleId];
}

// --- STATE ---
class ObstacleState extends Equatable {
  final List<Obstacle> obstacles;
  final bool isLoading;
  final String? errorMessage;
  final bool isReportedSuccess;
  final bool isDeleting;
  final bool isDeleteSuccess;

  const ObstacleState({
    required this.obstacles,
    this.isLoading = false,
    this.errorMessage,
    this.isReportedSuccess = false,
    this.isDeleting = false,
    this.isDeleteSuccess = false,
  });

  ObstacleState copyWith({
    List<Obstacle>? obstacles,
    bool? isLoading,
    String? errorMessage,
    bool? isReportedSuccess,
    bool? isDeleting,
    bool? isDeleteSuccess,
  }) {
    return ObstacleState(
      obstacles: obstacles ?? this.obstacles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isReportedSuccess: isReportedSuccess ?? this.isReportedSuccess,
      isDeleting: isDeleting ?? this.isDeleting,
      isDeleteSuccess: isDeleteSuccess ?? this.isDeleteSuccess,
    );
  }

  @override
  List<Object?> get props => [
    obstacles,
    isLoading,
    errorMessage,
    isReportedSuccess,
    isDeleting,
    isDeleteSuccess,
  ];
}

// --- BLOC ---
class ObstacleBloc extends Bloc<ObstacleEvent, ObstacleState> {
  final GetObstaclesUseCase _getObstaclesUseCase;
  final ReportObstacleUseCase _reportObstacleUseCase;
  final DeleteObstacleUseCase _deleteObstacleUseCase;

  ObstacleBloc({
    required GetObstaclesUseCase getObstaclesUseCase,
    required ReportObstacleUseCase reportObstacleUseCase,
    required DeleteObstacleUseCase deleteObstacleUseCase,
  }) : _getObstaclesUseCase = getObstaclesUseCase,
       _reportObstacleUseCase = reportObstacleUseCase,
       _deleteObstacleUseCase = deleteObstacleUseCase,
       super(const ObstacleState(obstacles: [])) {
    on<LoadObstaclesEvent>(_onLoadObstacles);
    on<ReportNewObstacleEvent>(_onReportNewObstacle);
    on<DeleteObstacleEvent>(_onDeleteObstacle);

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
        developer.log(
          'Falha capturada no BLoC: ${failure.message}',
          name: 'DebugInsercao',
        );
        // Reverte se falhou
        final revertedList = state.obstacles
            .where((o) => o.id != newObstacle.id)
            .toList();
        developer.log(
          'Revertendo lista (Removendo ID ${newObstacle.id})',
          name: 'DebugInsercao',
        );
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            obstacles: revertedList,
          ),
        );
      },
      (_) async {
        developer.log(
          'Sucesso retornado pelo UseCase!',
          name: 'DebugInsercao',
        );
        emit(state.copyWith(isLoading: false, isReportedSuccess: true));
        // Refetch silencioso
        final reloadResult = await _getObstaclesUseCase();
        reloadResult.fold(
          (failure) {
            developer.log(
              'Refetch falhou silenciosamente: ${failure.message}',
              name: 'DebugInsercao',
            );
          },
          (obstacles) {
            developer.log(
              'Refetch com sucesso. ${obstacles.length} obstáculos encontrados.',
              name: 'DebugInsercao',
            );
            emit(state.copyWith(obstacles: obstacles));
          },
        );
      },
    );
  }

  Future<void> _onDeleteObstacle(
    DeleteObstacleEvent event,
    Emitter<ObstacleState> emit,
  ) async {
    developer.log(
      'Iniciando exclusão do Obstáculo ID: ${event.obstacleId}',
      name: 'ObstacleBloc',
    );

    // Otimista: remove da lista local imediatamente
    final optimisticList = state.obstacles
        .where((o) => o.id != event.obstacleId)
        .toList();

    emit(
      state.copyWith(
        isDeleting: true,
        isDeleteSuccess: false,
        errorMessage: null,
        obstacles: optimisticList,
      ),
    );

    final result = await _deleteObstacleUseCase(event.obstacleId);

    await result.fold(
      (failure) async {
        developer.log(
          'Falha ao excluir obstáculo: ${failure.message}',
          name: 'ObstacleBloc',
        );
        // Reverte: recarrega a lista do servidor
        final reloadResult = await _getObstaclesUseCase();
        reloadResult.fold(
          (_) {},
          (obstacles) => emit(state.copyWith(obstacles: obstacles)),
        );
        emit(
          state.copyWith(
            isDeleting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (_) async {
        developer.log(
          'Obstáculo excluído com sucesso! ID: ${event.obstacleId}',
          name: 'ObstacleBloc',
        );
        emit(state.copyWith(isDeleting: false, isDeleteSuccess: true));
        // Refetch silencioso para garantir consistência
        final reloadResult = await _getObstaclesUseCase();
        reloadResult.fold(
          (failure) {
            developer.log(
              'Refetch após delete falhou: ${failure.message}',
              name: 'ObstacleBloc',
            );
          },
          (obstacles) {
            developer.log(
              'Refetch pós-delete: ${obstacles.length} obstáculos ativos.',
              name: 'ObstacleBloc',
            );
            emit(state.copyWith(obstacles: obstacles));
          },
        );
      },
    );
  }
}


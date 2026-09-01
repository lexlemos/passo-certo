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

class LoadObstaclesInViewportEvent extends ObstacleEvent {
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  LoadObstaclesInViewportEvent({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  @override
  List<Object?> get props => [minLat, minLng, maxLat, maxLng];
}

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
    on<LoadObstaclesInViewportEvent>(_onLoadObstaclesInViewport);
    on<ReportNewObstacleEvent>(_onReportNewObstacle);
    on<DeleteObstacleEvent>(_onDeleteObstacle);
  }

  Future<void> _onLoadObstaclesInViewport(
    LoadObstaclesInViewportEvent event,
    Emitter<ObstacleState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        isReportedSuccess: false,
        errorMessage: null,
      ),
    );

    final result = await _getObstaclesUseCase(
      minLat: event.minLat,
      minLng: event.minLng,
      maxLat: event.maxLat,
      maxLng: event.maxLng,
    );

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
      (_) {
        // O cache local já foi atualizado via write-through no repositório.
        // A UI otimista já reflete o novo obstáculo — nenhum refetch necessário.
        developer.log(
          'Sucesso retornado pelo UseCase! Cache já atualizado via write-through.',
          name: 'DebugInsercao',
        );
        emit(state.copyWith(isLoading: false, isReportedSuccess: true));
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
        // Reverte: para um delete que falhou, vamos deixar a UI local voltar ao que era.
        // Já não podemos dar fetch em tudo, pois não temos a viewport aqui.
        // Uma abordagem melhor seria recarregar se tivermos a viewport salva no estado,
        // mas para simplificar, a UI pode emitir um novo LoadObstaclesInViewportEvent.
        // Emit error only
        emit(state.copyWith(isDeleting: false, errorMessage: failure.message));
      },
      (_) {
        // O item já foi removido do cache local via write-through no repositório.
        // A UI otimista já reflete a remoção — nenhum refetch necessário.
        developer.log(
          'Obstáculo excluído com sucesso! ID: ${event.obstacleId}. '
          'Cache já atualizado via write-through.',
          name: 'ObstacleBloc',
        );
        emit(state.copyWith(isDeleting: false, isDeleteSuccess: true));
      },
    );
  }
}

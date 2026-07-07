import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

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

  ReportNewObstacleEvent({
    required this.type,
    required this.location,
    required this.description,
  });

  @override
  List<Object?> get props => [type, location, description];
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
  List<Object?> get props => [obstacles, isLoading, errorMessage, isReportedSuccess];
}

// --- BLOC ---
class ObstacleBloc extends Bloc<ObstacleEvent, ObstacleState> {
  final GetObstaclesUseCase _getObstaclesUseCase;
  final ReportObstacleUseCase _reportObstacleUseCase;

  ObstacleBloc({
    required GetObstaclesUseCase getObstaclesUseCase,
    required ReportObstacleUseCase reportObstacleUseCase,
  })  : _getObstaclesUseCase = getObstaclesUseCase,
        _reportObstacleUseCase = reportObstacleUseCase,
        super(const ObstacleState(obstacles: [])) {
    on<LoadObstaclesEvent>(_onLoadObstacles);
    on<ReportNewObstacleEvent>(_onReportNewObstacle);

    // Carrega a lista inicial de obstáculos
    add(LoadObstaclesEvent());
  }

  Future<void> _onLoadObstacles(LoadObstaclesEvent event, Emitter<ObstacleState> emit) async {
    emit(state.copyWith(isLoading: true, isReportedSuccess: false, errorMessage: null));

    final result = await _getObstaclesUseCase();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (obstacles) => emit(state.copyWith(isLoading: false, obstacles: obstacles)),
    );
  }

  Future<void> _onReportNewObstacle(ReportNewObstacleEvent event, Emitter<ObstacleState> emit) async {
    emit(state.copyWith(isLoading: true, isReportedSuccess: false, errorMessage: null));

    final newObstacle = Obstacle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: event.location.latitude,
      longitude: event.location.longitude,
      type: event.type,
      description: event.description,
      reportedAt: DateTime.now(),
      upvotes: 0,
    );

    final result = await _reportObstacleUseCase(newObstacle);

    await result.fold(
      (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) async {
        // Recarrega todos os obstáculos após salvar
        final reloadResult = await _getObstaclesUseCase();
        reloadResult.fold(
          (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
          (obstacles) => emit(state.copyWith(
            isLoading: false,
            obstacles: obstacles,
            isReportedSuccess: true,
          )),
        );
      },
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'dart:developer' as developer;

import '../../domain/entities/place.dart';
import '../../domain/usecases/add_place.dart';
import '../../domain/usecases/delete_place.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AddPlaceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitPlaceEvent extends AddPlaceEvent {
  final String name;
  final String searchTerms;
  final String category;
  final LatLng location;

  SubmitPlaceEvent({
    required this.name,
    required this.searchTerms,
    required this.category,
    required this.location,
  });

  @override
  List<Object?> get props => [name, searchTerms, category, location];
}

class DeletePlaceEvent extends AddPlaceEvent {
  final String placeId;

  DeletePlaceEvent({required this.placeId});

  @override
  List<Object?> get props => [placeId];
}

// ─── State ───────────────────────────────────────────────────────────────────

class AddPlaceState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final List<Place> newlyAddedPlaces;
  final bool isDeleting;
  final bool isDeleteSuccess;

  const AddPlaceState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.newlyAddedPlaces = const [],
    this.isDeleting = false,
    this.isDeleteSuccess = false,
  });

  AddPlaceState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    List<Place>? newlyAddedPlaces,
    bool? isDeleting,
    bool? isDeleteSuccess,
  }) {
    return AddPlaceState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      newlyAddedPlaces: newlyAddedPlaces ?? this.newlyAddedPlaces,
      isDeleting: isDeleting ?? this.isDeleting,
      isDeleteSuccess: isDeleteSuccess ?? this.isDeleteSuccess,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSuccess,
    errorMessage,
    newlyAddedPlaces,
    isDeleting,
    isDeleteSuccess,
  ];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class AddPlaceBloc extends Bloc<AddPlaceEvent, AddPlaceState> {
  final AddPlaceUseCase _addPlaceUseCase;
  final DeletePlaceUseCase _deletePlaceUseCase;

  AddPlaceBloc({
    required AddPlaceUseCase addPlaceUseCase,
    required DeletePlaceUseCase deletePlaceUseCase,
  }) : _addPlaceUseCase = addPlaceUseCase,
       _deletePlaceUseCase = deletePlaceUseCase,
       super(const AddPlaceState()) {
    on<SubmitPlaceEvent>(_onSubmitPlace);
    on<DeletePlaceEvent>(_onDeletePlace);
  }

  Future<void> _onSubmitPlace(
    SubmitPlaceEvent event,
    Emitter<AddPlaceState> emit,
  ) async {
    developer.log(
      'Tentando adicionar Local: ${event.name}',
      name: 'DebugInsercao',
    );
    emit(state.copyWith(isLoading: true, isSuccess: false));

    final place = Place(
      name: event.name,
      latitude: event.location.latitude,
      longitude: event.location.longitude,
      searchTerms: event.searchTerms
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      category: event.category,
      floor: 0,
      isAccessible: true,
    );

    // Otimista
    final newList = List<Place>.from(state.newlyAddedPlaces)..add(place);
    emit(state.copyWith(newlyAddedPlaces: newList));

    final result = await _addPlaceUseCase(place);

    result.fold((failure) {
      developer.log(
        'Falha capturada no BLoC (Place): ${failure.message}',
        name: 'DebugInsercao',
      );
      // Reverte
      final reverted = state.newlyAddedPlaces
          .where((p) => p.name != place.name && p.latitude != place.latitude)
          .toList();
      developer.log('Revertendo lista de locais', name: 'DebugInsercao');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          newlyAddedPlaces: reverted,
        ),
      );
    }, (addedPlace) {
      developer.log(
        'Sucesso retornado pelo UseCase (Place)!',
        name: 'DebugInsercao',
      );
      emit(state.copyWith(isLoading: false, isSuccess: true));
    });
  }

  Future<void> _onDeletePlace(
    DeletePlaceEvent event,
    Emitter<AddPlaceState> emit,
  ) async {
    developer.log(
      'Iniciando exclusão do Local ID: ${event.placeId}',
      name: 'AddPlaceBloc',
    );

    // Otimista: remove da lista local imediatamente
    final optimisticList = state.newlyAddedPlaces
        .where((p) => p.id != event.placeId)
        .toList();

    emit(
      state.copyWith(
        isDeleting: true,
        isDeleteSuccess: false,
        errorMessage: null,
        newlyAddedPlaces: optimisticList,
      ),
    );

    final result = await _deletePlaceUseCase(event.placeId);

    result.fold(
      (failure) {
        developer.log(
          'Falha ao excluir local: ${failure.message}',
          name: 'AddPlaceBloc',
        );
        emit(
          state.copyWith(isDeleting: false, errorMessage: failure.message),
        );
      },
      (_) {
        developer.log(
          'Local excluído com sucesso! ID: ${event.placeId}',
          name: 'AddPlaceBloc',
        );
        emit(state.copyWith(isDeleting: false, isDeleteSuccess: true));
      },
    );
  }
}

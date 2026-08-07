import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'dart:developer' as developer;

import '../../domain/entities/place.dart';
import '../../domain/usecases/add_place.dart';

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

class AddPlaceState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final List<Place> newlyAddedPlaces;

  const AddPlaceState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.newlyAddedPlaces = const [],
  });

  AddPlaceState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    List<Place>? newlyAddedPlaces,
  }) {
    return AddPlaceState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      newlyAddedPlaces: newlyAddedPlaces ?? this.newlyAddedPlaces,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSuccess,
    errorMessage,
    newlyAddedPlaces,
  ];
}

class AddPlaceBloc extends Bloc<AddPlaceEvent, AddPlaceState> {
  final AddPlaceUseCase _addPlaceUseCase;

  AddPlaceBloc({required AddPlaceUseCase addPlaceUseCase})
    : _addPlaceUseCase = addPlaceUseCase,
      super(const AddPlaceState()) {
    on<SubmitPlaceEvent>(_onSubmitPlace);
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
      developer.log(
        'Revertendo lista de locais',
        name: 'DebugInsercao',
      );
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
}


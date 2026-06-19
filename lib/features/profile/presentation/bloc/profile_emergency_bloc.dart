import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/emergency_contact.dart';
import '../../domain/usecases/validate_emergency_contact.dart';

// --- EVENTS ---
abstract class ProfileEmergencyEvent {}

class LoadEmergencyContactEvent extends ProfileEmergencyEvent {}

class SaveEmergencyContactEvent extends ProfileEmergencyEvent {
  final String contactInput;
  SaveEmergencyContactEvent({required this.contactInput});
}

// --- STATE ---
class ProfileEmergencyState {
  final String contactText;
  final bool isSaved;
  final String? errorMessage;
  final bool isLoading;

  ProfileEmergencyState({
    required this.contactText,
    this.isSaved = false,
    this.errorMessage,
    this.isLoading = false,
  });

  ProfileEmergencyState copyWith({
    String? contactText,
    bool? isSaved,
    String? errorMessage,
    bool? isLoading,
  }) {
    return ProfileEmergencyState(
      contactText: contactText ?? this.contactText,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLOC ---
class ProfileEmergencyBloc extends Bloc<ProfileEmergencyEvent, ProfileEmergencyState> {
  final ValidateEmergencyContactUseCase _validateEmergencyContactUseCase;

  ProfileEmergencyBloc({
    ValidateEmergencyContactUseCase? validateEmergencyContactUseCase,
  })  : _validateEmergencyContactUseCase =
            validateEmergencyContactUseCase ?? ValidateEmergencyContactUseCase(),
        super(ProfileEmergencyState(contactText: '')) {
    on<LoadEmergencyContactEvent>(_onLoadEmergencyContact);
    on<SaveEmergencyContactEvent>(_onSaveEmergencyContact);
  }

  void _onLoadEmergencyContact(
    LoadEmergencyContactEvent event,
    Emitter<ProfileEmergencyState> emit,
  ) {
    // Carrega um contato inicial para demonstração
    emit(state.copyWith(
      contactText: 'Maria Souza (79) 99999-9999',
      isSaved: false,
    ));
  }

  Future<void> _onSaveEmergencyContact(
    SaveEmergencyContactEvent event,
    Emitter<ProfileEmergencyState> emit,
  ) async {
    final inputText = event.contactInput.trim();
    final contact = EmergencyContact.fromSingleString(inputText);
    final validationError = _validateEmergencyContactUseCase(contact);

    if (validationError != null) {
      emit(state.copyWith(
        isSaved: false,
        errorMessage: validationError,
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      isSaved: false,
      errorMessage: null,
    ));

    // Simula salvamento
    await Future.delayed(const Duration(milliseconds: 800));

    emit(state.copyWith(
      isLoading: false,
      isSaved: true,
      contactText: inputText,
      errorMessage: null,
    ));
  }
}

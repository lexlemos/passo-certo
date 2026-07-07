import 'package:hydrated_bloc/hydrated_bloc.dart';

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
  final EmergencyContact? contact;
  final bool isSaved;
  final String? errorMessage;
  final bool isLoading;

  ProfileEmergencyState({
    required this.contactText,
    this.contact,
    this.isSaved = false,
    this.errorMessage,
    this.isLoading = false,
  });

  ProfileEmergencyState copyWith({
    String? contactText,
    EmergencyContact? contact,
    bool? isSaved,
    String? errorMessage,
    bool? isLoading,
  }) {
    return ProfileEmergencyState(
      contactText: contactText ?? this.contactText,
      contact: contact ?? this.contact,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLOC ---
class ProfileEmergencyBloc extends HydratedBloc<ProfileEmergencyEvent, ProfileEmergencyState> {
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
    if (state.contactText.isNotEmpty) return;
    final contact = EmergencyContact.fromSingleString('Maria Souza (79) 99999-9999');
    emit(state.copyWith(
      contactText: 'Maria Souza (79) 99999-9999',
      contact: contact,
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
      contact: contact,
      errorMessage: null,
    ));
  }

  @override
  ProfileEmergencyState? fromJson(Map<String, dynamic> json) {
    try {
      final contactText = json['contactText'] as String? ?? '';
      EmergencyContact? contact;
      if (json['contact'] != null) {
        final contactMap = json['contact'] as Map<String, dynamic>;
        contact = EmergencyContact(
          name: contactMap['name'] as String? ?? '',
          phoneNumber: contactMap['phoneNumber'] as String? ?? '',
        );
      }
      return ProfileEmergencyState(
        contactText: contactText,
        contact: contact,
        isSaved: json['isSaved'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
        isLoading: json['isLoading'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ProfileEmergencyState state) {
    return {
      'contactText': state.contactText,
      'isSaved': state.isSaved,
      'errorMessage': state.errorMessage,
      'isLoading': state.isLoading,
      'contact': state.contact != null
          ? {
              'name': state.contact!.name,
              'phoneNumber': state.contact!.phoneNumber,
            }
          : null,
    };
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/emergency_contact.dart';
import '../../domain/usecases/validate_emergency_contact.dart';

// --- EVENTS ---
abstract class ProfileEvent {}

class UpdateEmergencyContactNameEvent extends ProfileEvent {
  final String name;
  UpdateEmergencyContactNameEvent(this.name);
}

class UpdateEmergencyContactPhoneEvent extends ProfileEvent {
  final String phone;
  UpdateEmergencyContactPhoneEvent(this.phone);
}

class SaveProfileEvent extends ProfileEvent {}

class UpdateGpsAccuracyEvent extends ProfileEvent {
  final double accuracy;
  UpdateGpsAccuracyEvent(this.accuracy);
}

// --- STATE ---
class ProfileState {
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool isNameValid;
  final bool isPhoneValid;
  final double gpsAccuracy;
  final String gpsStatus;
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  ProfileState({
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.isNameValid,
    required this.isPhoneValid,
    required this.gpsAccuracy,
    required this.gpsStatus,
    required this.isSaving,
    this.errorMessage,
    required this.isSuccess,
  });

  ProfileState copyWith({
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isNameValid,
    bool? isPhoneValid,
    double? gpsAccuracy,
    String? gpsStatus,
    bool? isSaving,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ProfileState(
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      isNameValid: isNameValid ?? this.isNameValid,
      isPhoneValid: isPhoneValid ?? this.isPhoneValid,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// --- BLOC ---
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ValidateEmergencyContactUseCase _validateEmergencyContactUseCase;

  ProfileBloc({
    ValidateEmergencyContactUseCase? validateEmergencyContactUseCase,
  })  : _validateEmergencyContactUseCase =
            validateEmergencyContactUseCase ?? ValidateEmergencyContactUseCase(),
        super(ProfileState(
          emergencyContactName: '',
          emergencyContactPhone: '',
          isNameValid: true,
          isPhoneValid: true,
          gpsAccuracy: 12.0,
          gpsStatus: 'Bom (Menos de 15m)',
          isSaving: false,
          isSuccess: false,
        )) {
    on<UpdateEmergencyContactNameEvent>(_onUpdateName);
    on<UpdateEmergencyContactPhoneEvent>(_onUpdatePhone);
    on<UpdateGpsAccuracyEvent>(_onUpdateGpsAccuracy);
    on<SaveProfileEvent>(_onSaveProfile);
  }

  void _onUpdateName(UpdateEmergencyContactNameEvent event, Emitter<ProfileState> emit) {
    final contact = EmergencyContact(
      name: event.name,
      phoneNumber: state.emergencyContactPhone,
    );
    final error = _validateEmergencyContactUseCase(contact);
    // Validação de nome específico:
    final isNameValid = event.name.trim().isNotEmpty;

    emit(state.copyWith(
      emergencyContactName: event.name,
      isNameValid: isNameValid,
      errorMessage: isNameValid ? error : 'O nome do contato é obrigatório.',
      isSuccess: false,
    ));
  }

  void _onUpdatePhone(UpdateEmergencyContactPhoneEvent event, Emitter<ProfileState> emit) {
    final contact = EmergencyContact(
      name: state.emergencyContactName,
      phoneNumber: event.phone,
    );
    final error = _validateEmergencyContactUseCase(contact);
    // Se o erro for relacionado ao telefone:
    final isPhoneValid = error == null || !error.contains('Telefone');

    emit(state.copyWith(
      emergencyContactPhone: event.phone,
      isPhoneValid: isPhoneValid,
      errorMessage: error,
      isSuccess: false,
    ));
  }

  void _onUpdateGpsAccuracy(UpdateGpsAccuracyEvent event, Emitter<ProfileState> emit) {
    String status;
    if (event.accuracy < 5) {
      status = 'Excelente (Menos de 5m)';
    } else if (event.accuracy < 15) {
      status = 'Bom (Menos de 15m)';
    } else {
      status = 'Fraco (Requer atenção)';
    }

    emit(state.copyWith(
      gpsAccuracy: event.accuracy,
      gpsStatus: status,
    ));
  }

  Future<void> _onSaveProfile(SaveProfileEvent event, Emitter<ProfileState> emit) async {
    final contact = EmergencyContact(
      name: state.emergencyContactName,
      phoneNumber: state.emergencyContactPhone,
    );
    final validationError = _validateEmergencyContactUseCase(contact);

    if (validationError != null) {
      emit(state.copyWith(
        isNameValid: state.emergencyContactName.trim().isNotEmpty,
        isPhoneValid: state.emergencyContactPhone.trim().isNotEmpty &&
            !validationError.contains('Telefone'),
        errorMessage: validationError,
      ));
      return;
    }

    emit(state.copyWith(isSaving: true, errorMessage: null));

    // Simula salvamento
    await Future.delayed(const Duration(milliseconds: 800));

    emit(state.copyWith(
      isSaving: false,
      isSuccess: true,
    ));
  }
}

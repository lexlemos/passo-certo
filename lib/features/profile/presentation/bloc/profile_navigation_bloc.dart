import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

// --- EVENTS ---
abstract class ProfileNavigationEvent {}

class LoadNavigationSettingsEvent extends ProfileNavigationEvent {}

class ToggleVoiceNavigationEvent extends ProfileNavigationEvent {
  final bool value;
  ToggleVoiceNavigationEvent({required this.value});
}

class ToggleHighContrastEvent extends ProfileNavigationEvent {
  final bool value;
  ToggleHighContrastEvent({required this.value});
}

class ChangeTextSizeEvent extends ProfileNavigationEvent {
  final String value;
  ChangeTextSizeEvent({required this.value});
}

class ToggleAvoidStairsEvent extends ProfileNavigationEvent {
  final bool value;
  ToggleAvoidStairsEvent({required this.value});
}

class ToggleExtraCrossingTimeEvent extends ProfileNavigationEvent {
  final bool value;
  ToggleExtraCrossingTimeEvent({required this.value});
}

class ToggleSoundTrafficSignalsEvent extends ProfileNavigationEvent {
  final bool value;
  ToggleSoundTrafficSignalsEvent({required this.value});
}

// --- STATE ---
class ProfileNavigationState extends Equatable {
  final bool voiceNavigation;
  final bool highContrast;
  final String textSize;
  final bool avoidStairs;
  final bool extraCrossingTime;
  final bool soundTrafficSignals;
  final bool hasError;

  const ProfileNavigationState({
    this.voiceNavigation = false,
    this.highContrast = false,
    this.textSize = 'Padrão',
    this.avoidStairs = false,
    this.extraCrossingTime = false,
    this.soundTrafficSignals = false,
    this.hasError = false,
  });

  ProfileNavigationState copyWith({
    bool? voiceNavigation,
    bool? highContrast,
    String? textSize,
    bool? avoidStairs,
    bool? extraCrossingTime,
    bool? soundTrafficSignals,
    bool? hasError,
  }) {
    return ProfileNavigationState(
      voiceNavigation: voiceNavigation ?? this.voiceNavigation,
      highContrast: highContrast ?? this.highContrast,
      textSize: textSize ?? this.textSize,
      avoidStairs: avoidStairs ?? this.avoidStairs,
      extraCrossingTime: extraCrossingTime ?? this.extraCrossingTime,
      soundTrafficSignals: soundTrafficSignals ?? this.soundTrafficSignals,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  List<Object?> get props => [
    voiceNavigation,
    highContrast,
    textSize,
    avoidStairs,
    extraCrossingTime,
    soundTrafficSignals,
    hasError,
  ];
}

// --- BLOC ---
class ProfileNavigationBloc
    extends HydratedBloc<ProfileNavigationEvent, ProfileNavigationState> {
  ProfileNavigationBloc() : super(const ProfileNavigationState()) {
    on<LoadNavigationSettingsEvent>(_onLoadNavigationSettings);
    on<ToggleVoiceNavigationEvent>(_onToggleVoiceNavigation);
    on<ToggleHighContrastEvent>(_onToggleHighContrast);
    on<ChangeTextSizeEvent>(_onChangeTextSize);
    on<ToggleAvoidStairsEvent>(_onToggleAvoidStairs);
    on<ToggleExtraCrossingTimeEvent>(_onToggleExtraCrossingTime);
    on<ToggleSoundTrafficSignalsEvent>(_onToggleSoundTrafficSignals);
  }

  void _onLoadNavigationSettings(
    LoadNavigationSettingsEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state);
  }

  void _onToggleVoiceNavigation(
    ToggleVoiceNavigationEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state.copyWith(voiceNavigation: event.value, hasError: false));
  }

  void _onToggleHighContrast(
    ToggleHighContrastEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state.copyWith(highContrast: event.value, hasError: false));
  }

  void _onChangeTextSize(
    ChangeTextSizeEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state.copyWith(textSize: event.value, hasError: false));
  }

  void _onToggleAvoidStairs(
    ToggleAvoidStairsEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state.copyWith(avoidStairs: event.value, hasError: false));
  }

  void _onToggleExtraCrossingTime(
    ToggleExtraCrossingTimeEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state.copyWith(extraCrossingTime: event.value, hasError: false));
  }

  void _onToggleSoundTrafficSignals(
    ToggleSoundTrafficSignalsEvent event,
    Emitter<ProfileNavigationState> emit,
  ) {
    emit(state.copyWith(soundTrafficSignals: event.value, hasError: false));
  }

  @override
  ProfileNavigationState? fromJson(Map<String, dynamic> json) {
    try {
      return ProfileNavigationState(
        voiceNavigation: json['voiceNavigation'] as bool? ?? false,
        highContrast: json['highContrast'] as bool? ?? false,
        textSize: json['textSize'] as String? ?? 'Padrão',
        avoidStairs: json['avoidStairs'] as bool? ?? false,
        extraCrossingTime: json['extraCrossingTime'] as bool? ?? false,
        soundTrafficSignals: json['soundTrafficSignals'] as bool? ?? false,
        hasError: json['hasError'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ProfileNavigationState state) {
    return {
      'voiceNavigation': state.voiceNavigation,
      'highContrast': state.highContrast,
      'textSize': state.textSize,
      'avoidStairs': state.avoidStairs,
      'extraCrossingTime': state.extraCrossingTime,
      'soundTrafficSignals': state.soundTrafficSignals,
      'hasError': state.hasError,
    };
  }
}
